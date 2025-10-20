import 'dart:async';
import 'package:dio/dio.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/bloc/event_transformers.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/cache/hive_cache_manager.dart';
import '../../../../domain/entities/transaction.dart' as tx;
import '../../../../domain/repositories/transaction_repository.dart';
// sync notifications are handled by DI and dispatched into the bloc via events

// Events
abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();
  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionsEvent {
  final int page;
  final Map<String, dynamic>? filters;
  const LoadTransactions({this.page = 1, this.filters});
  @override
  List<Object?> get props => [page, filters];
}

class AddTransaction extends TransactionsEvent {
  final tx.Transaction transaction;
  const AddTransaction(this.transaction);
  @override
  List<Object> get props => [transaction];
}

class UpdateTransaction extends TransactionsEvent {
  final String id;
  final tx.Transaction transaction;
  const UpdateTransaction({required this.id, required this.transaction});
  @override
  List<Object> get props => [id, transaction];
}

class DeleteTransaction extends TransactionsEvent {
  final String id;
  const DeleteTransaction(this.id);
  @override
  List<Object> get props => [id];
}

class RefreshTransactions extends TransactionsEvent {
  const RefreshTransactions();
}

class SearchTransactions extends TransactionsEvent {
  final String query;
  const SearchTransactions(this.query);
  @override
  List<Object> get props => [query];
}

class FilterTransactions extends TransactionsEvent {
  final Map<String, dynamic> filters;
  const FilterTransactions(this.filters);
  @override
  List<Object> get props => [filters];
}

/// Internal event used by DI to apply id mappings produced by background sync.
class ApplyIdMap extends TransactionsEvent {
  final Map<String, String> idMap;
  const ApplyIdMap(this.idMap);
  @override
  List<Object> get props => [idMap];
}

// States
abstract class TransactionsState extends Equatable {
  const TransactionsState();
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionsState {
  const TransactionInitial();
}

class TransactionLoading extends TransactionsState {
  const TransactionLoading();
}

class TransactionLoaded extends TransactionsState {
  final List<tx.Transaction> transactions;
  final bool hasMore;
  final int currentPage;
  final Map<String, dynamic>? currentFilters;
  final String? searchQuery;

  const TransactionLoaded({
    required this.transactions,
    required this.hasMore,
    required this.currentPage,
    this.currentFilters,
    this.searchQuery,
  });

  @override
  List<Object?> get props =>
      [transactions, hasMore, currentPage, currentFilters, searchQuery];

  TransactionLoaded copyWith({
    List<tx.Transaction>? transactions,
    bool? hasMore,
    int? currentPage,
    Map<String, dynamic>? currentFilters,
    String? searchQuery,
  }) {
    return TransactionLoaded(
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      currentFilters: currentFilters ?? this.currentFilters,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TransactionOperationInProgress extends TransactionsState {
  final String operation;
  const TransactionOperationInProgress(this.operation);
  @override
  List<Object> get props => [operation];
}

class TransactionOperationSuccess extends TransactionsState {
  final String message;
  final List<tx.Transaction> transactions;
  final bool hasMore;

  const TransactionOperationSuccess({
    required this.message,
    required this.transactions,
    required this.hasMore,
  });

  @override
  List<Object> get props => [message, transactions, hasMore];
}

class TransactionError extends TransactionsState {
  final String error;
  final List<tx.Transaction>? transactions;
  final bool? hasMore;

  const TransactionError({
    required this.error,
    this.transactions,
    this.hasMore,
  });

  @override
  List<Object?> get props => [error, transactions, hasMore];
}

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  List<tx.Transaction> _allUnfilteredTransactions = [];
  List<tx.Transaction> get allUnfilteredTransactions => _allUnfilteredTransactions;
  final HiveCacheManager cacheManager;
  final TransactionRepository transactionRepository;
  List<tx.Transaction> _allTransactions = [];
  Map<String, dynamic>? _currentFilters;
  String? _currentSearchQuery;
  int _currentPage = 1;
  static const int _pageSize = 20;
  // Simple cancellation token to ignore outdated async responses
  int _latestRequestId = 0;
  // Dio CancelToken to cancel in-flight HTTP requests for transactions
  CancelToken? _currentCancelToken;

  TransactionsBloc({
    required this.cacheManager,
    required this.transactionRepository,
  }) : super(const TransactionInitial()) {
    // Sync listener should be attached by the DI container via
    // `attachSyncListener` to avoid DI ordering issues.
    // Load transactions with sequential processing
    on<LoadTransactions>(
      _onLoadTransactions,
      transformer: EventTransformers.sequential(),
    );

    // Add transaction with drop new strategy to prevent duplicate submissions
    on<AddTransaction>(
      _onAddTransaction,
      transformer: EventTransformers.droppable(),
    );

    // Update transaction with drop new strategy
    on<UpdateTransaction>(
      _onUpdateTransaction,
      transformer: EventTransformers.droppable(),
    );

    // Delete transaction with drop new strategy
    on<DeleteTransaction>(
      _onDeleteTransaction,
      transformer: EventTransformers.droppable(),
    );

    // Refresh with restartable strategy
    on<RefreshTransactions>(
      _onRefreshTransactions,
      transformer: EventTransformers.restartable(),
    );

    // Search with debounce to prevent excessive API calls
    on<SearchTransactions>(
      _onSearchTransactions,
      transformer:
          EventTransformers.debounce(const Duration(milliseconds: 300)),
    );

    // Filter with throttle to prevent excessive filtering
    on<FilterTransactions>(
      _onFilterTransactions,
      transformer:
          EventTransformers.throttle(const Duration(milliseconds: 150)),
    );

    // Internal event for applying id mappings (tempId -> serverId)
    on<ApplyIdMap>(_onApplyIdMap);

    add(const LoadTransactions());
  }

  Future<void> _onLoadTransactions(
      LoadTransactions event, Emitter<TransactionsState> emit) async {
    final requestId = ++_latestRequestId;
    try {
      if (event.page == 1) emit(const TransactionLoading());
      _currentPage = event.page;
      _currentFilters = event.filters;

      final query = TransactionQuery(
        page: event.page,
        limit: _pageSize,
        categories: event.filters?['categories'] as List<String>?,
        type: _parseTransactionType(event.filters?['type']),
        searchQuery: _currentSearchQuery,
        amountRange: event.filters?['amountRange'],
      );

      // Cancel any previous in-flight HTTP request for transactions
      _currentCancelToken?.cancel('cancelled by new request');
      _currentCancelToken = CancelToken();

      final result = await transactionRepository.getTransactions(
        query,
        cancelToken: _currentCancelToken,
      );
      // If a newer request was started while this one was in-flight, ignore this result
      if (requestId != _latestRequestId) return;

      result.fold(
        (failure) {
          Logger.e('Error loading transactions from repository', error: failure.message);
          emit(TransactionError(error: failure.message));
        },
        (paginatedResponse) {
          final transactions = paginatedResponse.data;
          final hasMore = paginatedResponse.meta.hasMore;

          if (event.page == 1) {
            _allTransactions = List<tx.Transaction>.from(transactions);
            // Set unfiltered transactions only if no filters or search query
            if ((event.filters == null || event.filters!.isEmpty) && (_currentSearchQuery == null || _currentSearchQuery!.isEmpty)) {
              _allUnfilteredTransactions = List<tx.Transaction>.from(transactions);
            }
          } else {
            // Prevent duplicates by checking IDs before adding
            final newIds = transactions.map((t) => t.id).toSet();
            _allTransactions.removeWhere((t) => newIds.contains(t.id));
            _allTransactions.addAll(transactions);
          }

          emit(TransactionLoaded(
            transactions: _allTransactions,
            hasMore: hasMore,
            currentPage: event.page,
            currentFilters: event.filters,
            searchQuery: _currentSearchQuery,
          ));
        },
      );
    } catch (error) {
      // Ignore errors from stale requests
      if (requestId != _latestRequestId) return;
      Logger.e('Error loading transactions', error: error);
      emit(TransactionError(error: 'Failed to load transactions: $error'));
    }
  }

  Future<void> _onAddTransaction(
      AddTransaction event, Emitter<TransactionsState> emit) async {
    try {
  // Immediately show the transaction in UI (optimistic)
  // Remove any existing entries with same id to avoid duplicates
  _allTransactions.removeWhere((t) => t.id == event.transaction.id);
  _allUnfilteredTransactions.removeWhere((t) => t.id == event.transaction.id);
  _allTransactions.insert(0, event.transaction);
  _allUnfilteredTransactions.insert(0, event.transaction);

  // Ensure no duplicate ids after optimistic insert
  _allTransactions = _uniqueById(_allTransactions);
  _allUnfilteredTransactions = _uniqueById(_allUnfilteredTransactions);

      emit(TransactionLoaded(
        transactions: _allTransactions,
        hasMore: false,
        currentPage: _currentPage,
        currentFilters: _currentFilters,
        searchQuery: _currentSearchQuery,
      ));

      // Since persistence is centralized in the repository (the form calls
      // repository.createTransaction before dispatching this event), this
      // handler only needs to update in-memory lists and emit success.
      _allTransactions = _uniqueById(_allTransactions);
      _allUnfilteredTransactions = _uniqueById(_allUnfilteredTransactions);

      emit(const TransactionOperationSuccess(
        message: 'Transaction added (optimistic)',
        transactions: [],
        hasMore: false,
      ));

    } catch (error) {
      Logger.e('Error adding transaction', error: error);
      emit(TransactionError(error: 'Failed to add transaction: $error'));
    }
  }

  // ID replacement now handled centrally via ApplyIdMap and LocalDataSource.replaceTempIds

  List<tx.Transaction> _uniqueById(List<tx.Transaction> list) {
    final seen = <String>{};
    final out = <tx.Transaction>[];
    for (final t in list) {
      if (!seen.contains(t.id)) {
        seen.add(t.id);
        out.add(t);
      }
    }
    return out;
  }

  Future<void> _onUpdateTransaction(
      UpdateTransaction event, Emitter<TransactionsState> emit) async {
    try {
      emit(const TransactionOperationInProgress('Updating transaction'));

      final result =
          await transactionRepository.updateTransaction(event.transaction);
      result.fold(
        (failure) {
          Logger.e('Error updating transaction', error: failure.message);
          emit(TransactionError(
              error: 'Failed to update transaction: ${failure.message}'));
        },
        (updatedTransaction) {
          // Optimistically update in-memory lists
          _allTransactions.removeWhere((t) => t.id == updatedTransaction.id);
          _allTransactions.insert(0, updatedTransaction);
          _allUnfilteredTransactions.removeWhere((t) => t.id == updatedTransaction.id);
          _allUnfilteredTransactions.insert(0, updatedTransaction);

          emit(TransactionOperationSuccess(
            message: 'Transaction updated successfully',
            transactions: [updatedTransaction],
            hasMore: false,
          ));

          emit(TransactionLoaded(
            transactions: _allTransactions,
            hasMore: false,
            currentPage: _currentPage,
            currentFilters: _currentFilters,
            searchQuery: _currentSearchQuery,
          ));
        },
      );
    } catch (error) {
      Logger.e('Error updating transaction', error: error);
      emit(TransactionError(error: 'Failed to update transaction: $error'));
    }
  }

  Future<void> _onDeleteTransaction(
      DeleteTransaction event, Emitter<TransactionsState> emit) async {
    try {
      emit(const TransactionOperationInProgress('Deleting transaction'));

      final result = await transactionRepository.deleteTransaction(event.id);
      result.fold(
        (failure) {
          Logger.e('Error deleting transaction', error: failure.message);
          emit(TransactionError(
              error: 'Failed to delete transaction: ${failure.message}'));
        },
        (_) {
          // Optimistically remove from in-memory lists
          _allTransactions.removeWhere((t) => t.id == event.id);
          _allUnfilteredTransactions.removeWhere((t) => t.id == event.id);

          emit(const TransactionOperationSuccess(
            message: 'Transaction deleted successfully',
            transactions: [],
            hasMore: false,
          ));

          emit(TransactionLoaded(
            transactions: _allTransactions,
            hasMore: false,
            currentPage: _currentPage,
            currentFilters: _currentFilters,
            searchQuery: _currentSearchQuery,
          ));
        },
      );
    } catch (error) {
      Logger.e('Error deleting transaction', error: error);
      emit(TransactionError(error: 'Failed to delete transaction: $error'));
    }
  }

  Future<void> _onRefreshTransactions(
      RefreshTransactions event, Emitter<TransactionsState> emit) async {
    try {
      // Clear repository cache and reload
      await transactionRepository.clearCache();
      _currentPage = 1;
      add(LoadTransactions(page: 1, filters: _currentFilters));
    } catch (error) {
      Logger.e('Error refreshing transactions', error: error);
      emit(TransactionError(error: 'Failed to refresh transactions: $error'));
    }
  }

  Future<void> _onSearchTransactions(
      SearchTransactions event, Emitter<TransactionsState> emit) async {
    final requestId = ++_latestRequestId;
    try {
      emit(const TransactionLoading());
      _currentSearchQuery = event.query.isEmpty ? null : event.query;
      _currentPage = 1;

      final query = TransactionQuery(
        page: 1,
        limit: _pageSize,
        searchQuery: _currentSearchQuery,
        type: _parseTransactionType(_currentFilters?['type']),
        categories: _currentFilters?['categories'] as List<String>?,
        startDate: _currentFilters?['startDate'],
        endDate: _currentFilters?['endDate'],
        amountRange: _currentFilters?['amountRange'],
      );

      // Cancel previous HTTP request and create a new CancelToken for this search
      _currentCancelToken?.cancel('cancelled by new search request');
      _currentCancelToken = CancelToken();

      final result = await transactionRepository.getTransactions(
        query,
        cancelToken: _currentCancelToken,
      );

      // If another request was started after this one, ignore this result
      if (requestId != _latestRequestId) return;

      result.fold(
        (failure) {
          Logger.e('Error searching transactions', error: failure.message);
          emit(TransactionError(
              error: 'Failed to search transactions: ${failure.message}'));
        },
        (paginatedResponse) {
          _allTransactions = paginatedResponse.data;

          emit(TransactionLoaded(
            transactions: paginatedResponse.data,
            hasMore: paginatedResponse.meta.hasMore,
            currentPage: 1,
            currentFilters: _currentFilters,
            searchQuery: _currentSearchQuery,
          ));
        },
      );
      } catch (error) {
      // Ignore errors from stale requests
      if (requestId != _latestRequestId) return;
      Logger.e('Error searching transactions', error: error);
      emit(TransactionError(error: 'Failed to search transactions: $error'));
    }
  }

  Future<void> _onFilterTransactions(
      FilterTransactions event, Emitter<TransactionsState> emit) async {
    final requestId = ++_latestRequestId;
    try {
      emit(const TransactionLoading());
      _currentFilters = event.filters;
      _currentPage = 1;

      dynamic categoryFilter;
      if (_currentFilters?['categories'] != null && (_currentFilters?['categories'] as List).isNotEmpty) {
        categoryFilter = List<String>.from(_currentFilters?['categories']);
      } else if (_currentFilters?['categories'] != null) {
        categoryFilter = _currentFilters?['categories'];
      }
      final query = TransactionQuery(
        page: 1,
        limit: _pageSize,
        searchQuery: _currentSearchQuery,
        type: _parseTransactionType(_currentFilters?['type']),
        categories: categoryFilter as List<String>?,
        startDate: _currentFilters?['startDate'] != null ? DateTime.parse(_currentFilters?['startDate']) : null,
        endDate: _currentFilters?['endDate'] != null ? DateTime.parse(_currentFilters?['endDate']) : null,
        amountRange: _currentFilters?['amountRange'],
      );

      // Cancel previous HTTP request and allocate a new CancelToken for this filter
      _currentCancelToken?.cancel('cancelled by new filter request');
      _currentCancelToken = CancelToken();

      final result = await transactionRepository.getTransactions(
        query,
        cancelToken: _currentCancelToken,
      );

      // Ignore result if a newer request has been started
      if (requestId != _latestRequestId) return;

      result.fold(
        (failure) {
          Logger.e('Error filtering transactions', error: failure.message);
          emit(TransactionError(
              error: 'Failed to filter transactions: ${failure.message}'));
        },
        (paginatedResponse) {
          _allTransactions = paginatedResponse.data;

          emit(TransactionLoaded(
            transactions: paginatedResponse.data,
            hasMore: paginatedResponse.meta.hasMore,
            currentPage: 1,
            currentFilters: _currentFilters,
            searchQuery: _currentSearchQuery,
          ));
        },
      );
    } catch (error) {
      // Ignore errors from stale requests
      if (requestId != _latestRequestId) return;
      Logger.e('Error filtering transactions', error: error);
      emit(TransactionError(error: 'Failed to filter transactions: $error'));
    }
  }

  tx.TransactionType? _parseTransactionType(String? type) {
    if (type == null) return null;
    switch (type.toLowerCase()) {
      case 'income':
        return tx.TransactionType.income;
      case 'expense':
        return tx.TransactionType.expense;
      case 'all':
        return tx.TransactionType.all;
      default:
        return null;
    }
  }

  Future<void> _onApplyIdMap(ApplyIdMap event, Emitter<TransactionsState> emit) async {
    try {
      final idMap = event.idMap;
      if (idMap.isEmpty) return;

      // Replace IDs in the in-memory lists
      idMap.forEach((tempId, serverId) {
        for (var i = 0; i < _allTransactions.length; i++) {
          if (_allTransactions[i].id == tempId) {
            _allTransactions[i] = _allTransactions[i].copyWith(id: serverId);
          }
        }
        for (var i = 0; i < _allUnfilteredTransactions.length; i++) {
          if (_allUnfilteredTransactions[i].id == tempId) {
            _allUnfilteredTransactions[i] = _allUnfilteredTransactions[i].copyWith(id: serverId);
          }
        }
      });

      // Emit a new loaded state reflecting replacements so UI updates regardless
      emit(TransactionLoaded(
        transactions: List<tx.Transaction>.from(_allTransactions),
        hasMore: false,
        currentPage: _currentPage,
        currentFilters: _currentFilters,
        searchQuery: _currentSearchQuery,
      ));
    } catch (error) {
      Logger.e('Error applying id map', error: error);
    }
  }
}

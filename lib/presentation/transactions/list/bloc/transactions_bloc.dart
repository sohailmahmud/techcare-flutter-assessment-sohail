import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/bloc/event_transformers.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/cache/hive_cache_manager.dart';
import '../../../../domain/entities/transaction.dart' as tx;
import '../../../../domain/repositories/transaction_repository.dart';

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
  List<Object?> get props => [transactions, hasMore, currentPage, currentFilters, searchQuery];

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
  final HiveCacheManager cacheManager;
  final TransactionRepository transactionRepository;
  List<tx.Transaction> _allTransactions = [];
  Map<String, dynamic>? _currentFilters;
  String? _currentSearchQuery;
  int _currentPage = 1;
  static const int _pageSize = 20;

  TransactionsBloc({
    required this.cacheManager,
    required this.transactionRepository,
  }) : super(const TransactionInitial()) {
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
      transformer: EventTransformers.debounce(const Duration(milliseconds: 300)),
    );
    
    // Filter with throttle to prevent excessive filtering
    on<FilterTransactions>(
      _onFilterTransactions,
      transformer: EventTransformers.throttle(const Duration(milliseconds: 150)),
    );

    add(const LoadTransactions());
  }

  Future<void> _onLoadTransactions(LoadTransactions event, Emitter<TransactionsState> emit) async {
    try {
      if (event.page == 1) emit(const TransactionLoading());
      _currentPage = event.page;
      _currentFilters = event.filters;
      
      final query = TransactionQuery(
        page: event.page,
        limit: _pageSize,
        category: event.filters?['category'],
        type: _parseTransactionType(event.filters?['type']),
        searchQuery: _currentSearchQuery,
      );
      
      final result = await transactionRepository.getTransactions(query);
      result.fold(
        (failure) {
          Logger.e('Error loading transactions from repository', error: failure.message);
          emit(TransactionError(error: failure.message));
        },
        (paginatedResponse) {
          final transactions = paginatedResponse.data;
          final hasMore = paginatedResponse.meta.hasMore;
          
          if (event.page == 1) {
            _allTransactions = transactions;
          } else {
            _allTransactions.addAll(transactions);
            // For infinite scroll, combine with existing transactions
            if (state is TransactionLoaded) {
              final existingTransactions = (state as TransactionLoaded).transactions;
              emit(TransactionLoaded(
                transactions: [...existingTransactions, ...transactions],
                hasMore: hasMore,
                currentPage: event.page,
                currentFilters: event.filters,
                searchQuery: _currentSearchQuery,
              ));
              return;
            }
          }

          emit(TransactionLoaded(
            transactions: transactions,
            hasMore: hasMore,
            currentPage: event.page,
            currentFilters: event.filters,
            searchQuery: _currentSearchQuery,
          ));
        },
      );
    } catch (error) {
      Logger.e('Error loading transactions', error: error);
      emit(TransactionError(error: 'Failed to load transactions: $error'));
    }
  }

  Future<void> _onAddTransaction(AddTransaction event, Emitter<TransactionsState> emit) async {
    try {
      emit(const TransactionOperationInProgress('Adding transaction'));
      
      final result = await transactionRepository.createTransaction(event.transaction);
      result.fold(
        (failure) {
          Logger.e('Error adding transaction', error: failure.message);
          emit(TransactionError(error: 'Failed to add transaction: ${failure.message}'));
        },
        (createdTransaction) {
          // Update local list optimistically
          _allTransactions = [createdTransaction, ..._allTransactions];
          
          emit(TransactionOperationSuccess(
            message: 'Transaction added successfully',
            transactions: [createdTransaction],
            hasMore: _allTransactions.length > _pageSize,
          ));
          
          // Auto-transition back to loaded state
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (!isClosed) {
              add(const LoadTransactions(page: 1));
            }
          });
        },
      );
    } catch (error) {
      Logger.e('Error adding transaction', error: error);
      emit(TransactionError(error: 'Failed to add transaction: $error'));
    }
  }

  Future<void> _onUpdateTransaction(UpdateTransaction event, Emitter<TransactionsState> emit) async {
    try {
      emit(const TransactionOperationInProgress('Updating transaction'));
      
      final result = await transactionRepository.updateTransaction(event.transaction);
      result.fold(
        (failure) {
          Logger.e('Error updating transaction', error: failure.message);
          emit(TransactionError(error: 'Failed to update transaction: ${failure.message}'));
        },
        (updatedTransaction) {
          // Update local list optimistically
          final index = _allTransactions.indexWhere((t) => t.id == event.id);
          if (index != -1) {
            _allTransactions[index] = updatedTransaction;
          }
          
          emit(TransactionOperationSuccess(
            message: 'Transaction updated successfully',
            transactions: [updatedTransaction],
            hasMore: _allTransactions.length > _currentPage * _pageSize,
          ));

          // Auto-transition back to loaded state
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (!isClosed) {
              add(LoadTransactions(page: _currentPage, filters: _currentFilters));
            }
          });
        },
      );
    } catch (error) {
      Logger.e('Error updating transaction', error: error);
      emit(TransactionError(error: 'Failed to update transaction: $error'));
    }
  }

  Future<void> _onDeleteTransaction(DeleteTransaction event, Emitter<TransactionsState> emit) async {
    try {
      emit(const TransactionOperationInProgress('Deleting transaction'));
      
      final result = await transactionRepository.deleteTransaction(event.id);
      result.fold(
        (failure) {
          Logger.e('Error deleting transaction', error: failure.message);
          emit(TransactionError(error: 'Failed to delete transaction: ${failure.message}'));
        },
        (_) {
          // Remove from local list optimistically
          _allTransactions.removeWhere((t) => t.id == event.id);
          
          emit(const TransactionOperationSuccess(
            message: 'Transaction deleted successfully',
            transactions: [],
            hasMore: false,
          ));

          // Auto-transition back to loaded state
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (!isClosed) {
              add(LoadTransactions(page: _currentPage, filters: _currentFilters));
            }
          });
        },
      );
    } catch (error) {
      Logger.e('Error deleting transaction', error: error);
      emit(TransactionError(error: 'Failed to delete transaction: $error'));
    }
  }

  Future<void> _onRefreshTransactions(RefreshTransactions event, Emitter<TransactionsState> emit) async {
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

  Future<void> _onSearchTransactions(SearchTransactions event, Emitter<TransactionsState> emit) async {
    try {
      emit(const TransactionLoading());
      _currentSearchQuery = event.query.isEmpty ? null : event.query;
      _currentPage = 1;

      final query = TransactionQuery(
        page: 1,
        limit: _pageSize,
        searchQuery: _currentSearchQuery,
        type: _parseTransactionType(_currentFilters?['type']),
        category: _currentFilters?['categoryId'],
        startDate: _currentFilters?['startDate'],
        endDate: _currentFilters?['endDate'],
      );
      
      final result = await transactionRepository.getTransactions(query);
      
      result.fold(
        (failure) {
          Logger.e('Error searching transactions', error: failure.message);
          emit(TransactionError(error: 'Failed to search transactions: ${failure.message}'));
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
      Logger.e('Error searching transactions', error: error);
      emit(TransactionError(error: 'Failed to search transactions: $error'));
    }
  }

  Future<void> _onFilterTransactions(FilterTransactions event, Emitter<TransactionsState> emit) async {
    try {
      emit(const TransactionLoading());
      _currentFilters = event.filters;
      _currentPage = 1;

      final query = TransactionQuery(
        page: 1,
        limit: _pageSize,
        searchQuery: _currentSearchQuery,
        type: _parseTransactionType(_currentFilters?['type']),
        category: _currentFilters?['categoryId'],
        startDate: _currentFilters?['startDate'],
        endDate: _currentFilters?['endDate'],
      );
      
      final result = await transactionRepository.getTransactions(query);
      
      result.fold(
        (failure) {
          Logger.e('Error filtering transactions', error: failure.message);
          emit(TransactionError(error: 'Failed to filter transactions: ${failure.message}'));
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
}
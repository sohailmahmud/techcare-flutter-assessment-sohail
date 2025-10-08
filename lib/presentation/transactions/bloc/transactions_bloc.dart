import 'dart:async';
import 'dart:developer' as dev;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/cache/hive_cache_manager.dart';
import '../../../domain/entities/transaction.dart' as tx;
import '../../../domain/entities/transaction_filter.dart';

// Events
abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionsEvent {
  final bool refresh;
  
  const LoadTransactions({this.refresh = false});

  @override
  List<Object> get props => [refresh];
}

class LoadMoreTransactions extends TransactionsEvent {
  const LoadMoreTransactions();
}

class SearchTransactions extends TransactionsEvent {
  final String query;
  
  const SearchTransactions(this.query);

  @override
  List<Object> get props => [query];
}

class ApplyFilters extends TransactionsEvent {
  final TransactionFilter filter;
  
  const ApplyFilters(this.filter);

  @override
  List<Object> get props => [filter];
}

class ClearFilters extends TransactionsEvent {
  const ClearFilters();
}

class DeleteTransaction extends TransactionsEvent {
  final String transactionId;
  
  const DeleteTransaction(this.transactionId);

  @override
  List<Object> get props => [transactionId];
}

class UpdateTransaction extends TransactionsEvent {
  final tx.Transaction transaction;
  
  const UpdateTransaction(this.transaction);

  @override
  List<Object> get props => [transaction];
}

// Cache Events
class InvalidateCache extends TransactionsEvent {
  final TransactionFilter? filter;
  final List<String>? transactionIds;
  final bool invalidateAll;

  const InvalidateCache({
    this.filter,
    this.transactionIds,
    this.invalidateAll = false,
  });

  @override
  List<Object?> get props => [filter, transactionIds, invalidateAll];
}

class RefreshCache extends TransactionsEvent {
  final TransactionFilter? filter;

  const RefreshCache({this.filter});

  @override
  List<Object?> get props => [filter];
}

class GetCacheStats extends TransactionsEvent {
  const GetCacheStats();
}

class ClearAllCache extends TransactionsEvent {
  const ClearAllCache();
}

// States
abstract class TransactionsState extends Equatable {
  const TransactionsState();

  @override
  List<Object?> get props => [];
}

class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
}

class TransactionsLoading extends TransactionsState {
  const TransactionsLoading();
}

class TransactionsLoaded extends TransactionsState {
  final List<tx.Transaction> transactions;
  final TransactionFilter currentFilter;
  final PaginationInfo paginationInfo;
  final bool isSearching;
  final String? errorMessage;

  const TransactionsLoaded({
    required this.transactions,
    required this.currentFilter,
    required this.paginationInfo,
    this.isSearching = false,
    this.errorMessage,
  });

  TransactionsLoaded copyWith({
    List<tx.Transaction>? transactions,
    TransactionFilter? currentFilter,
    PaginationInfo? paginationInfo,
    bool? isSearching,
    String? errorMessage,
  }) {
    return TransactionsLoaded(
      transactions: transactions ?? this.transactions,
      currentFilter: currentFilter ?? this.currentFilter,
      paginationInfo: paginationInfo ?? this.paginationInfo,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        transactions,
        currentFilter,
        paginationInfo,
        isSearching,
        errorMessage,
      ];
}

class TransactionsError extends TransactionsState {
  final String message;
  final List<tx.Transaction> cachedTransactions;
  final TransactionFilter currentFilter;

  const TransactionsError({
    required this.message,
    this.cachedTransactions = const [],
    this.currentFilter = const TransactionFilter(),
  });

  @override
  List<Object> get props => [message, cachedTransactions, currentFilter];
}

// Cache States
class CacheStatsState extends TransactionsState {
  final CacheStatistics stats;

  const CacheStatsState(this.stats);

  @override
  List<Object> get props => [stats];
}

class CacheInvalidatedState extends TransactionsState {
  final String message;

  const CacheInvalidatedState(this.message);

  @override
  List<Object> get props => [message];
}

class TransactionsLoadedFromCache extends TransactionsLoaded {
  final bool isStale;
  final DateTime cacheTime;

  const TransactionsLoadedFromCache({
    required super.transactions,
    required super.currentFilter,
    required super.paginationInfo,
    super.isSearching,
    super.errorMessage,
    this.isStale = false,
    required this.cacheTime,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        isStale,
        cacheTime,
      ];
}

// BLoC Implementation
class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  Timer? _searchDebouncer;
  final List<tx.Transaction> _allTransactions = [];
  final Duration _searchDebounceDelay = const Duration(milliseconds: 300);
  final HiveCacheManager _cacheManager;

  TransactionsBloc({HiveCacheManager? cacheManager}) 
    : _cacheManager = cacheManager ?? HiveCacheManager(),
      super(const TransactionsInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<LoadMoreTransactions>(_onLoadMoreTransactions);
    on<SearchTransactions>(_onSearchTransactions);
    on<ApplyFilters>(_onApplyFilters);
    on<ClearFilters>(_onClearFilters);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<InvalidateCache>(_onInvalidateCache);
    on<RefreshCache>(_onRefreshCache);
    on<GetCacheStats>(_onGetCacheStats);
    on<ClearAllCache>(_onClearAllCache);
    
    // Initialize cache
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    try {
      await _cacheManager.initialize();
      dev.log('Cache initialized successfully');
    } catch (e) {
      dev.log('Failed to initialize cache: $e');
    }
  }

  @override
  Future<void> close() {
    _searchDebouncer?.cancel();
    _cacheManager.dispose();
    return super.close();
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    try {
      if (event.refresh || state is TransactionsInitial) {
        emit(const TransactionsLoading());
        _allTransactions.clear();
      }

      // Mock data generation for demonstration
      final mockTransactions = _generateMockTransactions();
      _allTransactions.addAll(mockTransactions);

      const filter = TransactionFilter();
      final filteredTransactions = _applyFiltersToTransactions(_allTransactions, filter);
      
      final paginationInfo = PaginationInfo(
        currentPage: 0,
        totalItems: filteredTransactions.length,
        hasNextPage: filteredTransactions.length > 20,
      );

      final paginatedTransactions = _paginateTransactions(filteredTransactions, paginationInfo);

      emit(TransactionsLoaded(
        transactions: paginatedTransactions,
        currentFilter: filter,
        paginationInfo: paginationInfo,
      ));
    } catch (e) {
      emit(TransactionsError(
        message: 'Failed to load transactions: ${e.toString()}',
        cachedTransactions: _allTransactions,
      ));
    }
  }

  Future<void> _onLoadMoreTransactions(
    LoadMoreTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TransactionsLoaded || 
        currentState.paginationInfo.isLoading ||
        !currentState.paginationInfo.hasNextPage) {
      return;
    }

    try {
      final updatedPagination = currentState.paginationInfo.copyWith(isLoading: true);
      emit(currentState.copyWith(paginationInfo: updatedPagination));

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      final filteredTransactions = _applyFiltersToTransactions(_allTransactions, currentState.currentFilter);
      final nextPage = currentState.paginationInfo.currentPage + 1;
      final startIndex = nextPage * currentState.paginationInfo.itemsPerPage;
      final endIndex = (startIndex + currentState.paginationInfo.itemsPerPage)
          .clamp(0, filteredTransactions.length);

      final newTransactions = filteredTransactions.sublist(startIndex, endIndex);
      final allLoadedTransactions = [...currentState.transactions, ...newTransactions];

      final finalPagination = currentState.paginationInfo.copyWith(
        currentPage: nextPage,
        hasNextPage: endIndex < filteredTransactions.length,
        isLoading: false,
      );

      emit(currentState.copyWith(
        transactions: allLoadedTransactions,
        paginationInfo: finalPagination,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        paginationInfo: currentState.paginationInfo.copyWith(isLoading: false),
        errorMessage: 'Failed to load more transactions: ${e.toString()}',
      ));
    }
  }

  void _onSearchTransactions(
    SearchTransactions event,
    Emitter<TransactionsState> emit,
  ) {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(_searchDebounceDelay, () {
      final currentState = state;
      if (currentState is TransactionsLoaded) {
        final updatedFilter = currentState.currentFilter.copyWith(
          searchQuery: event.query,
        );
        add(ApplyFilters(updatedFilter));
      }
    });

    // Show immediate searching state
    if (state is TransactionsLoaded) {
      emit((state as TransactionsLoaded).copyWith(isSearching: true));
    }
  }

  Future<void> _onApplyFilters(
    ApplyFilters event,
    Emitter<TransactionsState> emit,
  ) async {
    try {
      emit(const TransactionsLoading());

      final filteredTransactions = _applyFiltersToTransactions(_allTransactions, event.filter);
      
      const initialPagination = PaginationInfo(
        currentPage: 0,
        totalItems: 0, // Will be updated below
        hasNextPage: false,
      );

      final updatedPagination = initialPagination.copyWith(
        totalItems: filteredTransactions.length,
        hasNextPage: filteredTransactions.length > initialPagination.itemsPerPage,
      );

      final paginatedTransactions = _paginateTransactions(filteredTransactions, updatedPagination);

      emit(TransactionsLoaded(
        transactions: paginatedTransactions,
        currentFilter: event.filter,
        paginationInfo: updatedPagination,
        isSearching: false,
      ));
    } catch (e) {
      emit(TransactionsError(
        message: 'Failed to apply filters: ${e.toString()}',
        cachedTransactions: _allTransactions,
        currentFilter: event.filter,
      ));
    }
  }

  void _onClearFilters(
    ClearFilters event,
    Emitter<TransactionsState> emit,
  ) {
    const clearedFilter = TransactionFilter();
    add(ApplyFilters(clearedFilter));
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TransactionsLoaded) return;

    try {
      // Remove from cache
      _allTransactions.removeWhere((t) => t.id == event.transactionId);
      
      // Remove from current display
      final updatedTransactions = currentState.transactions
          .where((t) => t.id != event.transactionId)
          .toList();

      final updatedPagination = currentState.paginationInfo.copyWith(
        totalItems: currentState.paginationInfo.totalItems - 1,
      );

      emit(currentState.copyWith(
        transactions: updatedTransactions,
        paginationInfo: updatedPagination,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        errorMessage: 'Failed to delete transaction: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TransactionsLoaded) return;

    try {
      // Update in cache
      final index = _allTransactions.indexWhere((t) => t.id == event.transaction.id);
      if (index != -1) {
        _allTransactions[index] = event.transaction;
      }

      // Update in current display
      final updatedTransactions = currentState.transactions.map((t) {
        return t.id == event.transaction.id ? event.transaction : t;
      }).toList();

      emit(currentState.copyWith(transactions: updatedTransactions));
    } catch (e) {
      emit(currentState.copyWith(
        errorMessage: 'Failed to update transaction: ${e.toString()}',
      ));
    }
  }

  List<tx.Transaction> _applyFiltersToTransactions(
    List<tx.Transaction> transactions,
    TransactionFilter filter,
  ) {
    var filtered = transactions.where((transaction) {
      // Search query filter
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        final titleMatch = transaction.title.toLowerCase().contains(query);
        final descriptionMatch = transaction.notes?.toLowerCase().contains(query) ?? false;
        final categoryMatch = transaction.categoryName.toLowerCase().contains(query);
        
        if (!titleMatch && !descriptionMatch && !categoryMatch) {
          return false;
        }
      }

      // Date range filter
      if (filter.dateRange != null) {
        if (!filter.dateRange!.contains(transaction.date)) {
          return false;
        }
      }

      // Category filter
      if (filter.selectedCategories.isNotEmpty) {
        if (!filter.selectedCategories.contains(transaction.categoryName)) {
          return false;
        }
      }

      // Amount range filter
      if (filter.amountRange != null) {
        if (!filter.amountRange!.contains(transaction.amount)) {
          return false;
        }
      }

      // Transaction type filter
      if (filter.transactionType != TransactionType.all) {
        if (filter.transactionType == TransactionType.income && transaction.type != tx.TransactionType.income) {
          return false;
        }
        if (filter.transactionType == TransactionType.expense && transaction.type != tx.TransactionType.expense) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));
    
    return filtered;
  }

  List<tx.Transaction> _paginateTransactions(
    List<tx.Transaction> transactions,
    PaginationInfo paginationInfo,
  ) {
    final startIndex = 0;
    final endIndex = ((paginationInfo.currentPage + 1) * paginationInfo.itemsPerPage)
        .clamp(0, transactions.length);
    
    return transactions.sublist(startIndex, endIndex);
  }

  List<tx.Transaction> _generateMockTransactions() {
    final categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Salary', 'Freelance'];
    final transactions = <tx.Transaction>[];
    final now = DateTime.now();

    for (int i = 0; i < 100; i++) {
      final isIncome = i % 5 == 0; // 20% income, 80% expense
      final amount = isIncome 
          ? (50000 + (i * 1000)).toDouble() // Income amounts
          : -(500 + (i * 50)).toDouble(); // Expense amounts
      
      transactions.add(tx.Transaction(
        id: 'trans_$i',
        title: isIncome ? 'Income Transaction $i' : 'Expense Transaction $i',
        amount: amount,
        categoryId: 'cat_${i % categories.length}',
        categoryName: categories[i % categories.length],
        date: now.subtract(Duration(days: i)),
        type: isIncome ? tx.TransactionType.income : tx.TransactionType.expense,
        notes: 'Description for transaction $i',
        createdAt: now.subtract(Duration(days: i)),
      ));
    }

    return transactions;
  }

  // Cache Event Handlers
  Future<void> _onInvalidateCache(
    InvalidateCache event,
    Emitter<TransactionsState> emit,
  ) async {
    try {
      await _cacheManager.invalidateCache(
        filter: event.filter,
        transactionIds: event.transactionIds,
        invalidateAll: event.invalidateAll,
        type: CacheInvalidationType.soft,
      );
      
      emit(const CacheInvalidatedState('Cache invalidated successfully'));
      
      // Reload data if needed
      if (event.invalidateAll || event.filter == null) {
        add(const LoadTransactions(refresh: true));
      }
    } catch (e) {
      emit(TransactionsError(message: 'Failed to invalidate cache: $e'));
    }
  }

  Future<void> _onRefreshCache(
    RefreshCache event,
    Emitter<TransactionsState> emit,
  ) async {
    try {
      // Clear existing cache and reload from network
      await _cacheManager.invalidateCache(
        filter: event.filter,
        type: CacheInvalidationType.hard,
      );
      
      // Reload transactions
      add(LoadTransactions(refresh: true));
    } catch (e) {
      emit(TransactionsError(message: 'Failed to refresh cache: $e'));
    }
  }

  Future<void> _onGetCacheStats(
    GetCacheStats event,
    Emitter<TransactionsState> emit,
  ) async {
    try {
      final stats = await _cacheManager.getCacheStats();
      emit(CacheStatsState(stats));
    } catch (e) {
      emit(TransactionsError(message: 'Failed to get cache stats: $e'));
    }
  }

  Future<void> _onClearAllCache(
    ClearAllCache event,
    Emitter<TransactionsState> emit,
  ) async {
    try {
      await _cacheManager.clearAll();
      emit(const CacheInvalidatedState('All cache cleared'));
      add(const LoadTransactions(refresh: true));
    } catch (e) {
      emit(TransactionsError(message: 'Failed to clear cache: $e'));
    }
  }
}
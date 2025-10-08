import 'package:equatable/equatable.dart';
import '../../../data/cache/hive_cache_manager.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/transaction_filter.dart';

// Cache-specific states
abstract class CacheState extends Equatable {
  const CacheState();

  @override
  List<Object?> get props => [];
}

/// State indicating cache is being loaded
class CacheLoading extends CacheState {
  final String operation;

  const CacheLoading(this.operation);

  @override
  List<Object?> get props => [operation];
}

/// State when cache statistics are loaded
class CacheStatsLoaded extends CacheState {
  final CacheStatistics stats;

  const CacheStatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

/// State when cache is invalidated
class CacheInvalidated extends CacheState {
  final String message;
  final CacheInvalidationType type;

  const CacheInvalidated({
    required this.message,
    required this.type,
  });

  @override
  List<Object?> get props => [message, type];
}

/// State when cache refresh is completed
class CacheRefreshed extends CacheState {
  final List<Transaction> transactions;
  final TransactionFilter? filter;
  final DateTime refreshedAt;

  const CacheRefreshed({
    required this.transactions,
    this.filter,
    required this.refreshedAt,
  });

  @override
  List<Object?> get props => [transactions, filter, refreshedAt];
}

/// State when cache cleanup is completed
class CacheCleanupCompleted extends CacheState {
  final int itemsRemoved;
  final DateTime cleanupTime;

  const CacheCleanupCompleted({
    required this.itemsRemoved,
    required this.cleanupTime,
  });

  @override
  List<Object?> get props => [itemsRemoved, cleanupTime];
}

/// State when cache preloading is completed
class CachePreloaded extends CacheState {
  final TransactionFilter filter;
  final int itemsLoaded;

  const CachePreloaded({
    required this.filter,
    required this.itemsLoaded,
  });

  @override
  List<Object?> get props => [filter, itemsLoaded];
}

/// State when cache operation fails
class CacheError extends CacheState {
  final String message;
  final String operation;

  const CacheError({
    required this.message,
    required this.operation,
  });

  @override
  List<Object?> get props => [message, operation];
}

/// Enhanced transactions loaded state with cache information
class TransactionsLoadedWithCache extends CacheState {
  final List<Transaction> transactions;
  final bool isFromCache;
  final DateTime? cacheTime;
  final TransactionFilter? appliedFilter;
  final bool hasMoreData;
  final int currentPage;
  final bool isStale;

  const TransactionsLoadedWithCache({
    required this.transactions,
    required this.isFromCache,
    this.cacheTime,
    this.appliedFilter,
    required this.hasMoreData,
    required this.currentPage,
    this.isStale = false,
  });

  TransactionsLoadedWithCache copyWith({
    List<Transaction>? transactions,
    bool? isFromCache,
    DateTime? cacheTime,
    TransactionFilter? appliedFilter,
    bool? hasMoreData,
    int? currentPage,
    bool? isStale,
  }) {
    return TransactionsLoadedWithCache(
      transactions: transactions ?? this.transactions,
      isFromCache: isFromCache ?? this.isFromCache,
      cacheTime: cacheTime ?? this.cacheTime,
      appliedFilter: appliedFilter ?? this.appliedFilter,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      currentPage: currentPage ?? this.currentPage,
      isStale: isStale ?? this.isStale,
    );
  }

  @override
  List<Object?> get props => [
        transactions,
        isFromCache,
        cacheTime,
        appliedFilter,
        hasMoreData,
        currentPage,
        isStale,
      ];
}
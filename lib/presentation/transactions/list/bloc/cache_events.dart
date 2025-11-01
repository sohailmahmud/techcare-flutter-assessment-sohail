import 'package:equatable/equatable.dart';

import '../../../../data/cache/hive_cache_manager.dart';
import '../../../../domain/entities/transaction_filter.dart';

// Cache-specific events for TransactionsBloc
abstract class CacheEvent extends Equatable {
  const CacheEvent();

  @override
  List<Object?> get props => [];
}

/// Event to invalidate cache with different strategies
class InvalidateCacheEvent extends CacheEvent {
  final TransactionFilter? filter;
  final List<String>? transactionIds;
  final bool invalidateAll;
  final CacheInvalidationType type;

  const InvalidateCacheEvent({
    this.filter,
    this.transactionIds,
    this.invalidateAll = false,
    this.type = CacheInvalidationType.soft,
  });

  @override
  List<Object?> get props => [filter, transactionIds, invalidateAll, type];
}

/// Event to refresh cache from network
class RefreshCacheEvent extends CacheEvent {
  final TransactionFilter? filter;
  final bool forceRefresh;

  const RefreshCacheEvent({this.filter, this.forceRefresh = false});

  @override
  List<Object?> get props => [filter, forceRefresh];
}

/// Event to clear all cache
class ClearAllCacheEvent extends CacheEvent {
  final bool reloadAfterClear;

  const ClearAllCacheEvent({this.reloadAfterClear = true});

  @override
  List<Object?> get props => [reloadAfterClear];
}

/// Event to get cache statistics
class GetCacheStatsEvent extends CacheEvent {
  const GetCacheStatsEvent();
}

/// Event to perform cache cleanup
class CleanupCacheEvent extends CacheEvent {
  final bool force;

  const CleanupCacheEvent({this.force = false});

  @override
  List<Object?> get props => [force];
}

/// Event to preload cache for specific filters
class PreloadCacheEvent extends CacheEvent {
  final TransactionFilter filter;
  final Duration? ttl;

  const PreloadCacheEvent({required this.filter, this.ttl});

  @override
  List<Object?> get props => [filter, ttl];
}

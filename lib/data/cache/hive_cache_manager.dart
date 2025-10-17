import 'dart:async';
import 'dart:developer' as dev;
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../domain/entities/transaction.dart' hide TransactionType;
import '../../domain/entities/transaction_filter.dart' as filter
    show TransactionFilter;
import '../../domain/entities/transaction_filter.dart';
import '../models/cached_transaction.dart';
import '../models/cache_metadata.dart';

/// Comprehensive cache manager using Hive with proper invalidation strategies
class HiveCacheManager {
  static const String _transactionsBoxName = 'transactions_cache';
  static const String _metadataBoxName = 'cache_metadata';
  static const String _configBoxName = 'cache_config';

  // Cache configuration
  static const Duration _defaultTTL = Duration(hours: 24);
  // static const Duration _maxCacheAge = Duration(days: 7); // Reserved for future TTL features
  static const int _maxCacheSize = 5000; // Maximum cached transactions
  static const Duration _cleanupInterval = Duration(hours: 6);

  late Box<CachedTransaction> _transactionsBox;
  late Box<CacheMetadata> _metadataBox;
  late Box<dynamic> _configBox;

  Timer? _cleanupTimer;
  bool _isInitialized = false;

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive Flutter
      await Hive.initFlutter();

      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CachedTransactionAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(CacheMetadataAdapter());
      }

      // Open boxes
      _transactionsBox =
          await Hive.openBox<CachedTransaction>(_transactionsBoxName);
      _metadataBox = await Hive.openBox<CacheMetadata>(_metadataBoxName);
      _configBox = await Hive.openBox(_configBoxName);

      // Start periodic cleanup
      _startPeriodicCleanup();

      _isInitialized = true;
      dev.log('HiveCacheManager initialized successfully');
    } catch (e) {
      dev.log('Failed to initialize HiveCacheManager: $e');
      rethrow;
    }
  }

  /// Cache transactions with smart invalidation
  Future<void> cacheTransactions(
    List<Transaction> transactions, {
    filter.TransactionFilter? filter,
    Duration? ttl,
    bool forceClear = false,
  }) async {
    await _ensureInitialized();

    try {
      final cacheKey = _generateCacheKey(filter);
      final cacheTTL = ttl ?? _defaultTTL;

      dev.log(
          'Caching ${transactions.length} transactions with key: $cacheKey');

      // Clear existing cache if forced or filter changed
      if (forceClear || await _hasFilterChanged(filter)) {
        await _clearFilteredCache(filter);
      }

      // Cache transactions
      final cachedTransactions = <String, CachedTransaction>{};
      for (final transaction in transactions) {
        final cached =
            CachedTransaction.fromTransaction(transaction, ttl: cacheTTL);
        cachedTransactions[transaction.id] = cached;
      }

      await _transactionsBox.putAll(cachedTransactions);

      // Update metadata
      await _updateCacheMetadata(cacheKey, transactions.length, filter);

      // Enforce cache size limits
      await _enforceCacheLimits();

      dev.log('Successfully cached ${transactions.length} transactions');
    } catch (e) {
      dev.log('Failed to cache transactions: $e');
      rethrow;
    }
  }

  /// Get cached transactions with smart filtering
  Future<List<Object>> getCachedTransactions({
    filter.TransactionFilter? filter,
    int? page,
    int? limit,
    bool includeExpired = false,
  }) async {
    await _ensureInitialized();

    try {
      _incrementCacheHit();

      var cached = _transactionsBox.values.where((transaction) {
        // Skip deleted items
        if (transaction.isDeleted) return false;

        // Skip expired items unless requested
        if (!includeExpired && transaction.isExpired) return false;

        // Apply filters
        return _matchesFilter(transaction, filter);
      }).toList();

      // Sort by date (newest first)
      cached.sort((a, b) => b.date.compareTo(a.date));

      // Apply pagination
      if (page != null && limit != null) {
        final start = page * limit;
        cached = cached.skip(start).take(limit).toList();
      }

      final result = cached.map((c) => c.toTransaction()).toList();
      dev.log('Retrieved ${result.length} cached transactions');

      return result;
    } catch (e) {
      _incrementCacheMiss();
      dev.log('Failed to get cached transactions: $e');
      return [];
    }
  }

  /// Check if valid cache exists for filter
  Future<bool> hasValidCache({
    filter.TransactionFilter? filter,
    Duration? maxAge,
  }) async {
    await _ensureInitialized();

    try {
      final cacheKey = _generateCacheKey(filter);
      final metadata = _metadataBox.get(cacheKey);

      if (metadata == null) return false;

      final age = maxAge ?? _defaultTTL;
      final isValid = !metadata.isStale(age) && metadata.totalItems > 0;

      dev.log('Cache validity for $cacheKey: $isValid');
      return isValid;
    } catch (e) {
      dev.log('Failed to check cache validity: $e');
      return false;
    }
  }

  /// Invalidate cache based on different strategies
  Future<void> invalidateCache({
    filter.TransactionFilter? filter,
    List<String>? transactionIds,
    bool invalidateAll = false,
    CacheInvalidationType type = CacheInvalidationType.soft,
  }) async {
    await _ensureInitialized();

    try {
      if (invalidateAll) {
        await _invalidateAllCache(type);
        dev.log('Invalidated all cache (${type.name})');
      } else if (transactionIds != null) {
        await _invalidateTransactions(transactionIds, type);
        dev.log(
            'Invalidated ${transactionIds.length} transactions (${type.name})');
      } else if (filter != null) {
        await _invalidateFilteredCache(filter, type);
        dev.log('Invalidated filtered cache (${type.name})');
      }
    } catch (e) {
      dev.log('Failed to invalidate cache: $e');
      rethrow;
    }
  }

  /// Update single transaction in cache
  Future<void> updateTransaction(Transaction transaction) async {
    await _ensureInitialized();

    try {
      final existingCached = _transactionsBox.get(transaction.id);
      if (existingCached != null) {
        // Update existing
        final updated = CachedTransaction.fromTransaction(transaction);
        updated.cachedAt = existingCached.cachedAt; // Keep original cache time
        updated.lastModified = DateTime.now();
        await _transactionsBox.put(transaction.id, updated);
      } else {
        // Add new
        final cached = CachedTransaction.fromTransaction(transaction);
        await _transactionsBox.put(transaction.id, cached);
      }

      // Update metadata
      await _updateAllMetadata();
      dev.log('Updated transaction in cache: ${transaction.id}');
    } catch (e) {
      dev.log('Failed to update transaction: $e');
      rethrow;
    }
  }

  /// Delete transaction from cache
  Future<void> deleteTransaction(String transactionId) async {
    await _ensureInitialized();

    try {
      final cached = _transactionsBox.get(transactionId);
      if (cached != null) {
        cached.markDeleted();
        dev.log('Marked transaction as deleted: $transactionId');
      }

      await _updateAllMetadata();
    } catch (e) {
      dev.log('Failed to delete transaction: $e');
      rethrow;
    }
  }

  /// Get cache statistics
  Future<CacheStatistics> getCacheStats() async {
    await _ensureInitialized();

    try {
      final allTransactions = _transactionsBox.values.toList();
      final activeTransactions =
          allTransactions.where((t) => !t.isDeleted).toList();
      final expiredTransactions =
          activeTransactions.where((t) => t.isExpired).toList();
      final staleTransactions =
          activeTransactions.where((t) => t.isStale).toList();

      final hitCount = _configBox.get('cache_hits', defaultValue: 0);
      final missCount = _configBox.get('cache_misses', defaultValue: 0);
      final totalRequests = hitCount + missCount;
      final hitRate = totalRequests > 0 ? hitCount / totalRequests : 0.0;

      return CacheStatistics(
        totalItems: allTransactions.length,
        activeItems: activeTransactions.length,
        expiredItems: expiredTransactions.length,
        staleItems: staleTransactions.length,
        cacheSize: _transactionsBox.length,
        lastCleanup:
            _configBox.get('last_cleanup', defaultValue: DateTime.now()),
        hitRate: hitRate,
        hitCount: hitCount,
        missCount: missCount,
      );
    } catch (e) {
      dev.log('Failed to get cache stats: $e');
      rethrow;
    }
  }

  /// Perform cache cleanup
  Future<void> cleanup({bool force = false}) async {
    await _ensureInitialized();

    try {
      dev.log('Starting cache cleanup...');

      // Remove expired and deleted transactions
      final expiredKeys = <String>[];
      for (final entry in _transactionsBox.toMap().entries) {
        if (entry.value.isExpired || entry.value.isDeleted) {
          expiredKeys.add(entry.key);
        }
      }

      await _transactionsBox.deleteAll(expiredKeys);
      dev.log('Removed ${expiredKeys.length} expired/deleted transactions');

      // Enforce size limits
      await _enforceCacheLimits();

      await _configBox.put('last_cleanup', DateTime.now());
      await _updateAllMetadata();

      dev.log('Cache cleanup completed');
    } catch (e) {
      dev.log('Failed to cleanup cache: $e');
      rethrow;
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    await _ensureInitialized();

    try {
      await _transactionsBox.clear();
      await _metadataBox.clear();
      await _configBox.clear();
      dev.log('Cleared all cache');
    } catch (e) {
      dev.log('Failed to clear cache: $e');
      rethrow;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      _cleanupTimer?.cancel();

      if (_isInitialized) {
        await _transactionsBox.close();
        await _metadataBox.close();
        await _configBox.close();
      }

      _isInitialized = false;
      dev.log('HiveCacheManager disposed');
    } catch (e) {
      dev.log('Error disposing HiveCacheManager: $e');
    }
  }

  // Private helper methods

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  String _generateCacheKey(filter.TransactionFilter? filter) {
    if (filter == null) return 'all_transactions';

    final parts = <String>[];
    if (filter.searchQuery.isNotEmpty) parts.add('q:${filter.searchQuery}');
    if (filter.selectedCategories.isNotEmpty) {
      parts.add('cat:${filter.selectedCategories.join(',')}');
    }
    if (filter.transactionType != TransactionType.all) {
      parts.add('type:${filter.transactionType.name}');
    }
    if (filter.dateRange != null) {
      parts.add(
          'date:${filter.dateRange!.start.millisecondsSinceEpoch}-${filter.dateRange!.end.millisecondsSinceEpoch}');
    }
    if (filter.amountRange != null) {
      parts.add('amount:${filter.amountRange!.min}-${filter.amountRange!.max}');
    }

    return parts.isEmpty ? 'all_transactions' : parts.join('|');
  }

  bool _matchesFilter(
      CachedTransaction transaction, filter.TransactionFilter? filter) {
    if (filter == null) return true;

    // Text search
    if (filter.searchQuery.isNotEmpty) {
      final query = filter.searchQuery.toLowerCase();
      if (!transaction.title.toLowerCase().contains(query) &&
          !(transaction.notes?.toLowerCase().contains(query) ?? false) &&
          !transaction.categoryName.toLowerCase().contains(query)) {
        return false;
      }
    }

    // Category filter
    if (filter.selectedCategories.isNotEmpty &&
        !filter.selectedCategories.contains(transaction.categoryId)) {
      return false;
    }

    // Type filter
    if (filter.transactionType != TransactionType.all) {
      final transactionType = transaction.type == 0
          ? TransactionType.income
          : TransactionType.expense;
      if (filter.transactionType != transactionType) {
        return false;
      }
    }

    // Date range filter
    if (filter.dateRange != null) {
      if (transaction.date.isBefore(filter.dateRange!.start) ||
          transaction.date.isAfter(filter.dateRange!.end)) {
        return false;
      }
    }

    // Amount range filter
    if (filter.amountRange != null) {
      if (transaction.amount < filter.amountRange!.min ||
          transaction.amount > filter.amountRange!.max) {
        return false;
      }
    }

    return true;
  }

  Future<bool> _hasFilterChanged(filter.TransactionFilter? filter) async {
    final cacheKey = _generateCacheKey(filter);
    final metadata = _metadataBox.get(cacheKey);
    return metadata == null;
  }

  Future<void> _clearFilteredCache(filter.TransactionFilter? filter) async {
    if (filter == null) {
      await _transactionsBox.clear();
      return;
    }

    final matchingKeys = <String>[];
    for (final entry in _transactionsBox.toMap().entries) {
      if (_matchesFilter(entry.value, filter)) {
        matchingKeys.add(entry.key);
      }
    }

    await _transactionsBox.deleteAll(matchingKeys);
  }

  Future<void> _updateCacheMetadata(
      String cacheKey, int itemCount, filter.TransactionFilter? filter) async {
    final metadata = _metadataBox.get(cacheKey) ??
        CacheMetadata(
          key: cacheKey,
          lastUpdated: DateTime.now(),
        );

    metadata.updateMetadata(
      totalItems: itemCount,
      filters: _filterToMap(filter),
    );
  }

  Map<String, dynamic> _filterToMap(filter.TransactionFilter? filter) {
    if (filter == null) return {};

    return {
      'searchQuery': filter.searchQuery,
      'categoryIds': filter.selectedCategories,
      'transactionType': filter.transactionType.name,
      'dateRange': filter.dateRange != null
          ? {
              'start': filter.dateRange!.start.millisecondsSinceEpoch,
              'end': filter.dateRange!.end.millisecondsSinceEpoch,
            }
          : null,
      'amountRange': filter.amountRange != null
          ? {
              'min': filter.amountRange!.min,
              'max': filter.amountRange!.max,
            }
          : null,
    };
  }

  Future<void> _enforceCacheLimits() async {
    if (_transactionsBox.length <= _maxCacheSize) return;

    // Remove oldest cached items
    final allTransactions = _transactionsBox.values.toList();
    allTransactions.sort((a, b) => a.cachedAt.compareTo(b.cachedAt));

    final itemsToRemove =
        allTransactions.take(_transactionsBox.length - _maxCacheSize);
    final keysToRemove = itemsToRemove.map((t) => t.id).toList();

    await _transactionsBox.deleteAll(keysToRemove);
    dev.log('Enforced cache size limit, removed ${keysToRemove.length} items');
  }

  Future<void> _invalidateAllCache(CacheInvalidationType type) async {
    switch (type) {
      case CacheInvalidationType.soft:
        // Mark all as expired
        for (final transaction in _transactionsBox.values) {
          transaction.expiresAt =
              DateTime.now().subtract(const Duration(seconds: 1));
          await transaction.save();
        }
        break;
      case CacheInvalidationType.hard:
        await _transactionsBox.clear();
        await _metadataBox.clear();
        break;
    }
  }

  Future<void> _invalidateTransactions(
      List<String> transactionIds, CacheInvalidationType type) async {
    for (final id in transactionIds) {
      final transaction = _transactionsBox.get(id);
      if (transaction != null) {
        switch (type) {
          case CacheInvalidationType.soft:
            transaction.expiresAt =
                DateTime.now().subtract(const Duration(seconds: 1));
            await transaction.save();
            break;
          case CacheInvalidationType.hard:
            await _transactionsBox.delete(id);
            break;
        }
      }
    }
  }

  Future<void> _invalidateFilteredCache(
      filter.TransactionFilter filter, CacheInvalidationType type) async {
    final matchingTransactions =
        _transactionsBox.values.where((t) => _matchesFilter(t, filter));

    for (final transaction in matchingTransactions) {
      switch (type) {
        case CacheInvalidationType.soft:
          transaction.expiresAt =
              DateTime.now().subtract(const Duration(seconds: 1));
          await transaction.save();
          break;
        case CacheInvalidationType.hard:
          await _transactionsBox.delete(transaction.id);
          break;
      }
    }
  }

  Future<void> _updateAllMetadata() async {
    final stats = await getCacheStats();

    for (final metadata in _metadataBox.values) {
      metadata.updateMetadata(
        totalItems: stats.activeItems,
        expiredItems: stats.expiredItems,
      );
    }
  }

  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) => cleanup());
  }

  void _incrementCacheHit() {
    final currentHits = _configBox.get('cache_hits', defaultValue: 0);
    _configBox.put('cache_hits', currentHits + 1);
  }

  void _incrementCacheMiss() {
    final currentMisses = _configBox.get('cache_misses', defaultValue: 0);
    _configBox.put('cache_misses', currentMisses + 1);
  }
}

/// Cache invalidation types
enum CacheInvalidationType {
  soft, // Mark as expired
  hard, // Delete from cache
}

/// Cache statistics model
class CacheStatistics {
  final int totalItems;
  final int activeItems;
  final int expiredItems;
  final int staleItems;
  final int cacheSize;
  final DateTime lastCleanup;
  final double hitRate;
  final int hitCount;
  final int missCount;

  CacheStatistics({
    required this.totalItems,
    required this.activeItems,
    required this.expiredItems,
    required this.staleItems,
    required this.cacheSize,
    required this.lastCleanup,
    required this.hitRate,
    required this.hitCount,
    required this.missCount,
  });

  @override
  String toString() {
    return 'CacheStatistics(total: $totalItems, active: $activeItems, expired: $expiredItems, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}

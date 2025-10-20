import 'dart:convert';
import 'package:hive_ce/hive.dart';
import '../../core/config/cache_config.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/analytics_model.dart';
import '../models/hive_key_value.dart';

import 'remote_data_source.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/analytics_repository.dart';

/// Represents a pending operation for offline sync
class PendingOperation {
  final String id;
  final String operationType; // 'CREATE', 'UPDATE', 'DELETE'
  final String resourceType; // 'transaction', 'category'
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  const PendingOperation({
    required this.id,
    required this.operationType,
    required this.resourceType,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'],
      operationType: json['operationType'],
      resourceType: json['resourceType'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operationType': operationType,
      'resourceType': resourceType,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  PendingOperation copyWith({
    String? id,
    String? operationType,
    String? resourceType,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
  }) {
    return PendingOperation(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      resourceType: resourceType ?? this.resourceType,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Extension methods for HiveKeyValue to check cache validity
extension HiveKeyValueExtension on HiveKeyValue {
  /// Check if this cached value is still valid
  bool isValid({Duration? maxAge}) {
    maxAge ??= kDefaultCacheTTL;
    if (timestamp == null) return false;
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp!);
    return DateTime.now().difference(cacheTime) < maxAge;
  }
}

/// Local data source for caching and offline support
abstract class LocalDataSource {
  // Initialization
  Future<void> initialize();

  // Transaction caching
  Future<PaginatedTransactionsResponse?> getCachedTransactions(
      TransactionQuery query);
  Future<void> cacheTransactions(
      TransactionQuery query, PaginatedTransactionsResponse response);
  Future<TransactionModel?> getCachedTransaction(String id);
  Future<void> cacheTransaction(TransactionModel transaction);
  Future<void> deleteCachedTransaction(String id);
  Future<void> clearTransactionCache();

  // Category caching
  Future<List<CategoryModel>?> getCachedCategories();
  Future<void> cacheCategories(List<CategoryModel> categories);
  Future<void> clearCategoryCache();

  // Analytics caching
  Future<AnalyticsDataModel?> getCachedAnalytics(AnalyticsQuery query);
  Future<void> cacheAnalytics(AnalyticsQuery query, AnalyticsDataModel data);
  Future<void> clearAnalyticsCache();

  // Offline support
  Future<List<PendingOperation>> getPendingOperations();
  Future<void> addPendingOperation(PendingOperation operation);
  Future<void> removePendingOperation(String operationId);
  Future<void> clearPendingOperations();

  // Replace temporary IDs with server-provided IDs across caches and
  // pending operations. The map keys are temp IDs and values are server IDs.
  Future<void> replaceTempIds(Map<String, String> idMap);

  // Cache management
  Future<bool> isCacheValid(String key, {Duration? maxAge});
  Future<void> clearAllCache();
}

/// Implementation of local data source using Hive CE
class LocalDataSourceImpl implements LocalDataSource {
  static const String _transactionsCachePrefix = 'transactions_cache_';
  static const String _transactionCachePrefix = 'transaction_cache_';
  static const String _categoriesCacheKey = 'categories_cache';
  static const String _analyticsCachePrefix = 'analytics_cache_';
  static const String _pendingOperationsKey = 'pending_operations';

  static const Duration _defaultCacheExpiry = kDefaultCacheTTL;

  late final Box<HiveKeyValue> _cacheBox;
  bool _isInitialized = false;

  LocalDataSourceImpl();

  @override
  Future<void> initialize() async {
    if (!_isInitialized) {
      _cacheBox = await Hive.openBox<HiveKeyValue>('local_cache');
      _isInitialized = true;
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  @override
  Future<PaginatedTransactionsResponse?> getCachedTransactions(
      TransactionQuery query) async {
    final key = _getTransactionsCacheKey(query);

    if (!await isCacheValid(key)) {
      return null;
    }

    final cached = _cacheBox.get(key);
    if (cached != null) {
      try {
        final json = jsonDecode(cached.value) as Map<String, dynamic>;
        return PaginatedTransactionsResponse.fromJson(json);
      } catch (e) {
        // Invalid cache, remove it
        await _cacheBox.delete(key);
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> cacheTransactions(
      TransactionQuery query, PaginatedTransactionsResponse response) async {
    await _ensureInitialized();
    final key = _getTransactionsCacheKey(query);
    final json = jsonEncode({
      'data': response.data.map((t) => t.toJson()).toList(),
      'meta': {
        'currentPage': response.meta.currentPage,
        'totalPages': response.meta.totalPages,
        'totalItems': response.meta.totalItems,
        'itemsPerPage': response.meta.itemsPerPage,
        'hasMore': response.meta.hasMore,
      },
    });

    await _cacheBox.put(
        key,
        HiveKeyValue(
          key: key,
          value: json,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
  }

  @override
  Future<TransactionModel?> getCachedTransaction(String id) async {
    await _ensureInitialized();
    final key = '$_transactionCachePrefix$id';

    if (!await isCacheValid(key)) {
      return null;
    }

    final cached = _cacheBox.get(key);
    if (cached != null) {
      try {
        final json = jsonDecode(cached.value) as Map<String, dynamic>;
        return TransactionModel.fromJson(json);
      } catch (e) {
        await _cacheBox.delete(key);
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> cacheTransaction(TransactionModel transaction) async {
    await _ensureInitialized();
    final key = '$_transactionCachePrefix${transaction.id}';
    final json = jsonEncode(transaction.toJson());

    await _cacheBox.put(
        key,
        HiveKeyValue(
          key: key,
          value: json,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
    // Also update any cached transaction list pages so the UI sees the
    // newly created/updated transaction immediately in lists.
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final listKeys = _cacheBox.keys
          .where((k) => k.toString().startsWith(_transactionsCachePrefix))
          .toList();

      for (final listKey in listKeys) {
        final cached = _cacheBox.get(listKey);
        if (cached == null) continue;

        try {
          final map = jsonDecode(cached.value) as Map<String, dynamic>;

          final originalData = (map['data'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              <Map<String, dynamic>>[];

          final existed = originalData.any((m) => m['id'] == transaction.id);

          // Remove any prior occurrence of this transaction
          final newData = originalData.where((m) => m['id'] != transaction.id).toList();

          // Insert at the top so newest appear first
          newData.insert(0, transaction.toJson());

          // Update meta
          final meta = (map['meta'] as Map<String, dynamic>?) ?? {};
          final itemsPerPage = (meta['itemsPerPage'] is int)
              ? meta['itemsPerPage'] as int
              : (meta['itemsPerPage'] is String ? int.tryParse(meta['itemsPerPage']) ?? newData.length : newData.length);

          int totalItems = (meta['totalItems'] is int)
              ? meta['totalItems'] as int
              : (meta['totalItems'] is String ? int.tryParse(meta['totalItems']) ?? originalData.length : originalData.length);

          if (!existed) {
            totalItems = totalItems + 1;
          }

          final totalPages = (itemsPerPage > 0) ? ((totalItems / itemsPerPage).ceil()) : 1;

          final newMap = {
            'data': newData,
            'meta': {
              'currentPage': meta['currentPage'] ?? 1,
              'totalPages': totalPages,
              'totalItems': totalItems,
              'itemsPerPage': itemsPerPage,
              'hasMore': (meta['hasMore'] ?? false),
            }
          };

          await _cacheBox.put(
            listKey,
            HiveKeyValue(
              key: listKey.toString(),
              value: jsonEncode(newMap),
              timestamp: now,
            ),
          );
        } catch (_) {
          // If parsing/updating a cached page fails, ignore and continue
          continue;
        }
      }
    } catch (_) {
      // Swallow any errors while updating list caches
    }
  }

  @override
  Future<void> deleteCachedTransaction(String id) async {
    await _ensureInitialized();
    final key = '$_transactionCachePrefix$id';
    await _cacheBox.delete(key);
  }

  @override
  Future<void> clearTransactionCache() async {
    await _ensureInitialized();
    final keys = _cacheBox.keys.where((key) {
      final keyStr = key.toString();
      return keyStr.startsWith(_transactionsCachePrefix) ||
          keyStr.startsWith(_transactionCachePrefix);
    }).toList();

    for (final key in keys) {
      await _cacheBox.delete(key);
    }
  }

  @override
  Future<List<CategoryModel>?> getCachedCategories() async {
    await _ensureInitialized();

    if (!await isCacheValid(_categoriesCacheKey)) {
      return null;
    }

    final cached = _cacheBox.get(_categoriesCacheKey);
    if (cached != null) {
      try {
        final jsonList = jsonDecode(cached.value) as List;
        return jsonList.map((json) => CategoryModel.fromJson(json)).toList();
      } catch (e) {
        await _cacheBox.delete(_categoriesCacheKey);
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> cacheCategories(List<CategoryModel> categories) async {
    await _ensureInitialized();
    final json = jsonEncode(categories.map((c) => c.toJson()).toList());

    await _cacheBox.put(
        _categoriesCacheKey,
        HiveKeyValue(
          key: _categoriesCacheKey,
          value: json,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
  }

  @override
  Future<void> clearCategoryCache() async {
    await _ensureInitialized();
    await _cacheBox.delete(_categoriesCacheKey);
  }

  @override
  Future<AnalyticsDataModel?> getCachedAnalytics(AnalyticsQuery query) async {
    await _ensureInitialized();
    final key = _getAnalyticsCacheKey(query);

    if (!await isCacheValid(key)) {
      return null;
    }

    final cached = _cacheBox.get(key);
    if (cached != null) {
      try {
        final json = jsonDecode(cached.value) as Map<String, dynamic>;
        return AnalyticsDataModel.fromJson(json);
      } catch (e) {
        await _cacheBox.delete(key);
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> cacheAnalytics(
      AnalyticsQuery query, AnalyticsDataModel data) async {
    await _ensureInitialized();
    final key = _getAnalyticsCacheKey(query);
    final json = jsonEncode(data.toJson());

    await _cacheBox.put(
        key,
        HiveKeyValue(
          key: key,
          value: json,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
  }

  @override
  Future<void> clearAnalyticsCache() async {
    await _ensureInitialized();
    final keys = _cacheBox.keys.where((key) {
      return key.toString().startsWith(_analyticsCachePrefix);
    }).toList();

    for (final key in keys) {
      await _cacheBox.delete(key);
    }
  }

  @override
  Future<List<PendingOperation>> getPendingOperations() async {
    await _ensureInitialized();
    final cached = _cacheBox.get(_pendingOperationsKey);
    if (cached != null) {
      try {
        final jsonList = jsonDecode(cached.value) as List;
        return jsonList.map((json) => PendingOperation.fromJson(json)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  @override
  Future<void> addPendingOperation(PendingOperation operation) async {
    await _ensureInitialized();
    final operations = await getPendingOperations();
    operations.add(operation);

    final json = jsonEncode(operations.map((op) => op.toJson()).toList());
    await _cacheBox.put(
        _pendingOperationsKey,
        HiveKeyValue(
          key: _pendingOperationsKey,
          value: json,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
  }

  @override
  Future<void> removePendingOperation(String operationId) async {
    await _ensureInitialized();
    final operations = await getPendingOperations();
    operations.removeWhere((op) => op.id == operationId);

    final json = jsonEncode(operations.map((op) => op.toJson()).toList());
    await _cacheBox.put(
        _pendingOperationsKey,
        HiveKeyValue(
          key: _pendingOperationsKey,
          value: json,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
  }

  @override
  Future<void> clearPendingOperations() async {
    await _ensureInitialized();
    await _cacheBox.delete(_pendingOperationsKey);
  }

  @override
  Future<bool> isCacheValid(String key, {Duration? maxAge}) async {
    await _ensureInitialized();
    final cached = _cacheBox.get(key);
    if (cached == null) return false;

    return cached.isValid(maxAge: maxAge ?? _defaultCacheExpiry);
  }

  @override
  Future<void> clearAllCache() async {
    await _ensureInitialized();
    await _cacheBox.clear();
  }

  // Helper methods
  String _getTransactionsCacheKey(TransactionQuery query) {
    // Ensure categories are in a deterministic order when building the key
    String? categoriesPart;
    if (query.categories != null && query.categories!.isNotEmpty) {
      final sorted = List<String>.from(query.categories!);
      sorted.sort();
      categoriesPart = sorted.join(",");
    }

    // Prepare amount range part if present
    String? amountPart;
    if (query.amountRange != null) {
      final minValRaw = query.amountRange!['min'];
      final maxValRaw = query.amountRange!['max'];
      double? minVal;
      double? maxVal;
      if (minValRaw is num) minVal = minValRaw.toDouble();
      if (maxValRaw is num) maxVal = maxValRaw.toDouble();
      if (minVal != null && maxVal != null) {
        amountPart = 'amount:$minVal-$maxVal';
      }
    }

    final params = [
      'page:${query.page}',
      'limit:${query.limit}',
      if (categoriesPart != null) 'categories:$categoriesPart',
      if (query.type != null) 'type:${query.type!.name}',
      if (query.startDate != null)
        'start:${query.startDate!.millisecondsSinceEpoch}',
      if (query.endDate != null) 'end:${query.endDate!.millisecondsSinceEpoch}',
      // Include amount range so different amount filters map to different cache keys
      if (amountPart != null) amountPart,
      // Include search query if provided
      if (query.searchQuery != null && query.searchQuery!.isNotEmpty)
        'search:${query.searchQuery}',
    ].join('_');
    return '$_transactionsCachePrefix$params';
  }

  String _getAnalyticsCacheKey(AnalyticsQuery query) {
    final params = [
      'start:${query.startDate.millisecondsSinceEpoch}',
      'end:${query.endDate.millisecondsSinceEpoch}',
    ].join('_');
    return '$_analyticsCachePrefix$params';
  }

  @override
  Future<void> replaceTempIds(Map<String, String> idMap) async {
    if (idMap.isEmpty) return;
    await _ensureInitialized();

    // Helper to recursively replace id strings in nested maps/lists
    dynamic replaceIdsInValue(dynamic value, Map<String, String> map) {
      if (value is Map<String, dynamic>) {
        final newMap = <String, dynamic>{};
        value.forEach((k, v) {
          newMap[k] = replaceIdsInValue(v, map);
        });
        return newMap;
      } else if (value is List) {
        return value.map((e) => replaceIdsInValue(e, map)).toList();
      } else if (value is String) {
        return map.containsKey(value) ? map[value] : value;
      }
      return value;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    // 1) Update individual transaction caches
    for (final entry in idMap.entries) {
      final tempId = entry.key;
      final serverId = entry.value;
      final oldKey = '$_transactionCachePrefix$tempId';
      final newKey = '$_transactionCachePrefix$serverId';

      final cached = _cacheBox.get(oldKey);
      if (cached != null) {
        try {
          final json = jsonDecode(cached.value) as Map<String, dynamic>;
          json['id'] = serverId;
          await _cacheBox.put(
            newKey,
            HiveKeyValue(key: newKey, value: jsonEncode(json), timestamp: now),
          );
          await _cacheBox.delete(oldKey);
        } catch (_) {
          // ignore parse errors
        }
      }
    }

    // 2) Update transaction list caches
    final listKeys = _cacheBox.keys
        .where((k) => k.toString().startsWith(_transactionsCachePrefix))
        .toList();

    for (final listKey in listKeys) {
      final cached = _cacheBox.get(listKey);
      if (cached == null) continue;
      try {
        final map = jsonDecode(cached.value) as Map<String, dynamic>;
        final data = (map['data'] as List<dynamic>?) ?? [];
        // Replace ids and dedupe if necessary
        final seen = <String>{};
        final newData = <dynamic>[];
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            final idVal = item['id'] as String?;
            final replacedId = (idVal != null && idMap.containsKey(idVal)) ? idMap[idVal] : idVal;
            if (replacedId != null) {
              item['id'] = replacedId;
            }
            final finalId = item['id'] as String?;
            if (finalId != null && !seen.contains(finalId)) {
              seen.add(finalId);
              newData.add(item);
            }
          } else {
            newData.add(item);
          }
        }

  map['data'] = newData;
        // totalItems should reflect unique seen count if changed
        final meta = (map['meta'] as Map<String, dynamic>?) ?? {};
        final itemsPerPage = (meta['itemsPerPage'] is int)
            ? meta['itemsPerPage'] as int
            : (meta['itemsPerPage'] is String ? int.tryParse(meta['itemsPerPage']) ?? newData.length : newData.length);
        final totalItems = seen.length;
        final totalPages = (itemsPerPage > 0) ? ((totalItems / itemsPerPage).ceil()) : 1;

        map['meta'] = {
          'currentPage': meta['currentPage'] ?? 1,
          'totalPages': totalPages,
          'totalItems': totalItems,
          'itemsPerPage': itemsPerPage,
          'hasMore': meta['hasMore'] ?? false,
        };

        await _cacheBox.put(
          listKey,
          HiveKeyValue(key: listKey.toString(), value: jsonEncode(map), timestamp: now),
        );
      } catch (_) {
        continue;
      }
    }

    // 3) Update pending operations
    try {
      final pending = await getPendingOperations();
      final updated = <PendingOperation>[];
      for (final op in pending) {
        final data = op.data;
        // Recursively replace ids in the operation data
        final newData = replaceIdsInValue(data, idMap) as Map<String, dynamic>;
        final updatedOp = op.copyWith(data: newData);
        updated.add(updatedOp);
      }

      final json = jsonEncode(updated.map((op) => op.toJson()).toList());
      await _cacheBox.put(
        _pendingOperationsKey,
        HiveKeyValue(key: _pendingOperationsKey, value: json, timestamp: now),
      );
    } catch (_) {
      // ignore errors updating pending operations
    }
  }
}

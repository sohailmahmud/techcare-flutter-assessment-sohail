import 'dart:convert';
import 'package:hive_ce/hive.dart';
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
    maxAge ??= const Duration(minutes: 30);
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

  static const Duration _defaultCacheExpiry = Duration(minutes: 5);

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
    final params = [
      'page:${query.page}',
      'limit:${query.limit}',
      if (query.categories != null && query.categories!.isNotEmpty)
        'categories:${query.categories!.join(",")}',
      if (query.type != null) 'type:${query.type!.name}',
      if (query.startDate != null)
        'start:${query.startDate!.millisecondsSinceEpoch}',
      if (query.endDate != null) 'end:${query.endDate!.millisecondsSinceEpoch}',
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
}

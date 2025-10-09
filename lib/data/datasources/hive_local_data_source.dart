import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/hive_models.dart';
import '../../core/utils/result.dart';
import '../../core/errors/enhanced_failures.dart';

/// Offline-first local data source using Hive
class HiveLocalDataSource {
  late Box<HiveTransaction> _transactionsBox;
  late Box<HiveCategory> _categoriesBox;
  late Box<HiveSyncQueueItem> _syncQueueBox;
  late Box<dynamic> _settingsBox;

  final Connectivity _connectivity;
  final Random _random = Random();

  /// Generate a simple UUID-like string
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = _random.nextInt(999999);
    return '${timestamp}_$randomPart';
  }

  bool _isInitialized = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  HiveLocalDataSource({
    required Connectivity connectivity,
  }) : _connectivity = connectivity;

  /// Initialize Hive boxes and register adapters
  Future<Result<void>> initialize() async {
    if (_isInitialized) return Result.success(null);

    try {
      // Note: Run 'flutter packages pub run build_runner build' first
      /*
      if (!Hive.isAdapterRegistered(HiveTypeIds.transactionType)) {
        Hive.registerAdapter(HiveTransactionTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(HiveTypeIds.syncOperation)) {
        Hive.registerAdapter(HiveSyncOperationAdapter());
      }
      if (!Hive.isAdapterRegistered(HiveTypeIds.syncStatus)) {
        Hive.registerAdapter(HiveSyncStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(HiveTypeIds.transaction)) {
        Hive.registerAdapter(HiveTransactionAdapter());
      }
      if (!Hive.isAdapterRegistered(HiveTypeIds.category)) {
        Hive.registerAdapter(HiveCategoryAdapter());
      }
      if (!Hive.isAdapterRegistered(HiveTypeIds.syncQueueItem)) {
        Hive.registerAdapter(HiveSyncQueueItemAdapter());
      }
      */

      // Open boxes
      _transactionsBox =
          await Hive.openBox<HiveTransaction>(HiveBoxNames.transactions);
      _categoriesBox =
          await Hive.openBox<HiveCategory>(HiveBoxNames.categories);
      _syncQueueBox =
          await Hive.openBox<HiveSyncQueueItem>(HiveBoxNames.syncQueue);
      _settingsBox = await Hive.openBox(HiveBoxNames.settings);

      // Set up connectivity monitoring
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
      );

      _isInitialized = true;
      return Result.success(null);
    } catch (e) {
      return Result.error(StorageFailure(
        'Failed to initialize local storage: $e',
        code: 'STORAGE_INIT_ERROR',
      ));
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) {
    final isOnline = result != ConnectivityResult.none;
    if (isOnline) {
      // Trigger sync when coming back online
      _triggerAutoSync();
    }
  }

  /// Check if device is online
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Get all transactions with filtering and pagination
  Future<Result<List<HiveTransaction>>> getTransactions({
    int? limit,
    int? offset,
    String? categoryId,
    HiveTransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    bool includeDeleted = false,
  }) async {
    try {
      var transactions = _transactionsBox.values.where((t) {
        if (!includeDeleted && t.isDeleted) return false;
        if (categoryId != null && t.categoryId != categoryId) return false;
        if (type != null && t.type != type) return false;

        if (startDate != null && t.date.isBefore(startDate)) return false;
        if (endDate != null && t.date.isAfter(endDate)) return false;

        if (search != null && search.isNotEmpty) {
          final searchLower = search.toLowerCase();
          if (!t.title.toLowerCase().contains(searchLower) &&
              !(t.description?.toLowerCase().contains(searchLower) ?? false)) {
            return false;
          }
        }

        return true;
      }).toList();

      // Sort by date (newest first)
      transactions.sort((a, b) => b.date.compareTo(a.date));

      // Apply pagination
      if (offset != null) {
        transactions = transactions.skip(offset).toList();
      }
      if (limit != null) {
        transactions = transactions.take(limit).toList();
      }

      return Result.success(transactions);
    } catch (e) {
      return Result.error(StorageFailure(
        'Failed to get transactions: $e',
        code: 'GET_TRANSACTIONS_ERROR',
      ));
    }
  }

  /// Get transaction by ID
  Future<Result<HiveTransaction?>> getTransactionById(String id) async {
    try {
      final transaction = _transactionsBox.values
          .where((t) => (t.id == id || t.localId == id) && !t.isDeleted)
          .firstOrNull;

      return Result.success(transaction);
    } catch (e) {
      return Result.error(StorageFailure(
        'Failed to get transaction by ID: $e',
        code: 'GET_TRANSACTION_ERROR',
      ));
    }
  }

  /// Create a new transaction
  Future<Result<HiveTransaction>> createTransaction(
      HiveTransaction transaction) async {
    try {
      // Generate local ID if not provided
      transaction.localId ??= _generateId();

      // Set sync status based on connectivity
      final online = await isOnline;
      transaction.syncStatus =
          online ? HiveSyncStatus.pending : HiveSyncStatus.pending;
      transaction.createdAt = DateTime.now();
      transaction.updatedAt = DateTime.now();

      // Save to local storage
      await _transactionsBox.add(transaction);

      // Add to sync queue if online or if offline mode is enabled
      await _addToSyncQueue(
        entityType: 'transaction',
        entityId: transaction.localId!,
        operation: HiveSyncOperation.create,
        data: transaction.toJson(),
      );

      return Result.success(transaction);
    } catch (e) {
      return Result.error(StorageFailure(
        'Failed to create transaction: $e',
        code: 'CREATE_TRANSACTION_ERROR',
      ));
    }
  }

  /// Update an existing transaction
  Future<Result<HiveTransaction>> updateTransaction(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final existingIndex = _transactionsBox.values
          .toList()
          .indexWhere((t) => (t.id == id || t.localId == id) && !t.isDeleted);

      if (existingIndex == -1) {
        return Result.error(const NotFoundFailure(
          'Transaction not found',
          code: 'TRANSACTION_NOT_FOUND',
        ));
      }

      final existing = _transactionsBox.getAt(existingIndex)!;

      // Create updated transaction
      final updated = existing.copyWith(
        title: updates['title'] ?? existing.title,
        amount: updates['amount']?.toDouble() ?? existing.amount,
        type: updates['type'] != null
            ? (updates['type'] == 'income'
                ? HiveTransactionType.income
                : HiveTransactionType.expense)
            : existing.type,
        categoryId: updates['categoryId'] ?? existing.categoryId,
        date: updates['date'] != null
            ? DateTime.tryParse(updates['date']) ?? existing.date
            : existing.date,
        description: updates['description'] ?? existing.description,
        paymentMethod: updates['paymentMethod'] ?? existing.paymentMethod,
        tags: updates['tags']?.cast<String>() ?? existing.tags,
        location: updates['location'] ?? existing.location,
        updatedAt: DateTime.now(),
        syncStatus: HiveSyncStatus.pending,
        version: (existing.version ?? 0) + 1,
      );

      // Save updated transaction
      await _transactionsBox.putAt(existingIndex, updated);

      // Add to sync queue
      await _addToSyncQueue(
        entityType: 'transaction',
        entityId: updated.localId ?? updated.id,
        operation: HiveSyncOperation.update,
        data: updated.toJson(),
      );

      return Result.success(updated);
    } catch (e) {
      return Result.error(StorageFailure(
        'Failed to update transaction: $e',
        code: 'UPDATE_TRANSACTION_ERROR',
      ));
    }
  }

  /// Delete a transaction (soft delete)
  Future<Result<void>> deleteTransaction(String id) async {
    try {
      final existingIndex = _transactionsBox.values
          .toList()
          .indexWhere((t) => (t.id == id || t.localId == id) && !t.isDeleted);

      if (existingIndex == -1) {
        return Result.error(const NotFoundFailure(
          'Transaction not found',
          code: 'TRANSACTION_NOT_FOUND',
        ));
      }

      final existing = _transactionsBox.getAt(existingIndex)!;

      // Mark as deleted
      final deleted = existing.copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
        syncStatus: HiveSyncStatus.pending,
        version: (existing.version ?? 0) + 1,
      );

      await _transactionsBox.putAt(existingIndex, deleted);

      // Add to sync queue
      await _addToSyncQueue(
        entityType: 'transaction',
        entityId: deleted.localId ?? deleted.id,
        operation: HiveSyncOperation.delete,
        data: {'id': deleted.id, 'localId': deleted.localId},
      );

      return Result.success(null);
    } catch (e) {
      return Result.error(StorageFailure(
        'Failed to delete transaction: $e',
        code: 'DELETE_TRANSACTION_ERROR',
      ));
    }
  }

  /// Get all categories
  Future<Result<List<HiveCategory>>> getCategories(
      {bool includeDeleted = false}) async {
    try {
      final categories = _categoriesBox.values
          .where((c) => includeDeleted || !c.isDeleted)
          .toList();

      // Sort by name
      categories.sort((a, b) => a.name.compareTo(b.name));

      return Result.success(categories);
    } catch (e) {
      return Result.error(StorageFailure(
        'Failed to get categories: $e',
        code: 'GET_CATEGORIES_ERROR',
      ));
    }
  }

  /// Create a new category
  Future<Result<HiveCategory>> createCategory(HiveCategory category) async {
    try {
      category.localId ??= _generateId();

      category.syncStatus = HiveSyncStatus.pending;
      category.createdAt = DateTime.now();
      category.updatedAt = DateTime.now();

      await _categoriesBox.add(category);

      await _addToSyncQueue(
        entityType: 'category',
        entityId: category.localId!,
        operation: HiveSyncOperation.create,
        data: category.toJson(),
      );

      return Result.success(category);
    } catch (e) {
      return Result.error(StorageFailure(
        'Failed to create category: $e',
        code: 'CREATE_CATEGORY_ERROR',
      ));
    }
  }

  /// Get pending sync queue items
  Future<Result<List<HiveSyncQueueItem>>> getPendingSyncItems() async {
    try {
      final items = _syncQueueBox.values
          .where((item) =>
              item.status == HiveSyncStatus.pending ||
              (item.status == HiveSyncStatus.failed && item.shouldRetry))
          .toList();

      // Sort by priority (higher first) then by creation date
      items.sort((a, b) {
        final priorityComparison = b.priority.compareTo(a.priority);
        if (priorityComparison != 0) return priorityComparison;
        return a.createdAt.compareTo(b.createdAt);
      });

      return Result.success(items);
    } catch (e) {
      return Result.error(StorageFailure(
        'Failed to get pending sync items: $e',
        code: 'GET_SYNC_ITEMS_ERROR',
      ));
    }
  }

  /// Mark sync item as completed
  Future<Result<void>> markSyncItemCompleted(String itemId) async {
    try {
      final itemIndex =
          _syncQueueBox.values.toList().indexWhere((item) => item.id == itemId);

      if (itemIndex != -1) {
        final item = _syncQueueBox.getAt(itemIndex)!;
        final updated = item.copyWith(
          status: HiveSyncStatus.synced,
          lastAttemptAt: DateTime.now(),
        );
        await _syncQueueBox.putAt(itemIndex, updated);
      }

      return Result.success(null);
    } catch (e) {
      return Result.error(StorageFailure(
        'Failed to mark sync item as completed: $e',
        code: 'MARK_SYNC_COMPLETED_ERROR',
      ));
    }
  }

  /// Mark sync item as failed
  Future<Result<void>> markSyncItemFailed(String itemId, String error) async {
    try {
      final itemIndex =
          _syncQueueBox.values.toList().indexWhere((item) => item.id == itemId);

      if (itemIndex != -1) {
        final item = _syncQueueBox.getAt(itemIndex)!;
        final updated = item.copyWith(
          status: HiveSyncStatus.failed,
          retryCount: item.retryCount + 1,
          lastAttemptAt: DateTime.now(),
          lastError: error,
        );
        await _syncQueueBox.putAt(itemIndex, updated);
      }

      return Result.success(null);
    } catch (e) {
      return Result.error(StorageFailure(
        'Failed to mark sync item as failed: $e',
        code: 'MARK_SYNC_FAILED_ERROR',
      ));
    }
  }

  /// Add item to sync queue
  Future<void> _addToSyncQueue({
    required String entityType,
    required String entityId,
    required HiveSyncOperation operation,
    required Map<String, dynamic> data,
    int priority = 0,
  }) async {
    final item = HiveSyncQueueItem(
      id: _generateId(),
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      data: data,
      createdAt: DateTime.now(),
      priority: priority,
    );

    await _syncQueueBox.add(item);
  }

  /// Trigger automatic sync if enabled
  void _triggerAutoSync() {
    final autoSyncEnabled =
        _settingsBox.get(HiveSettingsKeys.autoSync, defaultValue: true);
    if (autoSyncEnabled) {
      // This would be handled by a sync service
      debugPrint('Auto sync triggered');
    }
  }

  /// Get settings value
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  /// Set settings value
  Future<Result<void>> setSetting<T>(String key, T value) async {
    try {
      await _settingsBox.put(key, value);
      return Result.success(null);
    } catch (e) {
      return Result.error(StorageFailure(
        'Failed to save setting: $e',
        code: 'SAVE_SETTING_ERROR',
      ));
    }
  }

  /// Clean up old sync queue items
  Future<Result<void>> cleanupSyncQueue() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      final itemsToRemove = <int>[];

      for (int i = 0; i < _syncQueueBox.length; i++) {
        final item = _syncQueueBox.getAt(i);
        if (item != null &&
            item.status == HiveSyncStatus.synced &&
            item.createdAt.isBefore(cutoffDate)) {
          itemsToRemove.add(i);
        }
      }

      // Remove items in reverse order to maintain indices
      for (final index in itemsToRemove.reversed) {
        await _syncQueueBox.deleteAt(index);
      }

      return Result.success(null);
    } catch (e) {
      return Result.error(StorageFailure(
        'Failed to cleanup sync queue: $e',
        code: 'CLEANUP_SYNC_ERROR',
      ));
    }
  }

  /// Get storage statistics
  Future<Result<Map<String, dynamic>>> getStorageStats() async {
    try {
      final stats = {
        'transactions': {
          'total': _transactionsBox.length,
          'synced': _transactionsBox.values
              .where((t) => t.syncStatus == HiveSyncStatus.synced)
              .length,
          'pending': _transactionsBox.values
              .where((t) => t.syncStatus == HiveSyncStatus.pending)
              .length,
          'deleted': _transactionsBox.values.where((t) => t.isDeleted).length,
        },
        'categories': {
          'total': _categoriesBox.length,
          'synced': _categoriesBox.values
              .where((c) => c.syncStatus == HiveSyncStatus.synced)
              .length,
          'pending': _categoriesBox.values
              .where((c) => c.syncStatus == HiveSyncStatus.pending)
              .length,
        },
        'syncQueue': {
          'total': _syncQueueBox.length,
          'pending': _syncQueueBox.values
              .where((i) => i.status == HiveSyncStatus.pending)
              .length,
          'failed': _syncQueueBox.values
              .where((i) => i.status == HiveSyncStatus.failed)
              .length,
          'synced': _syncQueueBox.values
              .where((i) => i.status == HiveSyncStatus.synced)
              .length,
        },
        'lastSync': _settingsBox.get(HiveSettingsKeys.lastSyncAt),
      };

      return Result.success(stats);
    } catch (e) {
      return Result.error(StorageFailure(
        'Failed to get storage stats: $e',
        code: 'GET_STATS_ERROR',
      ));
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}

/// Extension to find first element or null
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    try {
      return first;
    } catch (e) {
      return null;
    }
  }
}

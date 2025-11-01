import 'package:fintrack/core/constants/app_constants.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';

part 'cached_transaction.g.dart';

/// Hive-compatible cached transaction model
@HiveType(typeId: 8)
class CachedTransaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  int type; // 0 for income, 1 for expense

  @HiveField(4)
  String categoryId;

  @HiveField(5)
  String categoryName;

  @HiveField(6)
  DateTime date;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime cachedAt;

  @HiveField(10)
  DateTime? expiresAt;

  @HiveField(11)
  bool isDeleted;

  @HiveField(12)
  DateTime? lastModified;

  CachedTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    this.notes,
    required this.createdAt,
    required this.cachedAt,
    this.expiresAt,
    this.isDeleted = false,
    this.lastModified,
  });

  /// Convert from domain entity to cached model
  factory CachedTransaction.fromTransaction(
    Transaction transaction, {
    Duration? ttl,
  }) {
    final now = DateTime.now();
    final effectiveTtl = ttl ?? AppConstants.cacheExpiry;
    return CachedTransaction(
      id: transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      type: transaction.type == TransactionType.income ? 0 : 1,
      categoryId: transaction.categoryId,
      categoryName: transaction.categoryName,
      date: transaction.date,
      notes: transaction.notes,
      createdAt: transaction.createdAt ?? now,
      cachedAt: now,
      expiresAt: now.add(effectiveTtl),
    );
  }

  /// Convert to domain entity (async for category lookup)
  Future<Transaction> toTransaction() async {
    // Find the category by ID, with fallback
    final category =
        (await AppCategories.findById(categoryId)) ??
        Category(
          id: categoryId,
          name: categoryName,
          icon: Icons.category,
          color: Colors.grey,
        );

    return Transaction(
      id: id,
      title: title,
      amount: amount,
      type: type == 0 ? TransactionType.income : TransactionType.expense,
      category: category,
      date: date,
      description: notes,
      createdAt: createdAt,
    );
  }

  /// Check if the cached transaction is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if the cached transaction is fresh
  bool get isFresh => !isExpired;

  /// Check if cache entry is stale (approaching expiration)
  bool get isStale {
    if (expiresAt == null) return false;
    final staleThreshold = expiresAt!.subtract(const Duration(hours: 2));
    return DateTime.now().isAfter(staleThreshold);
  }

  /// Age of the cached transaction in milliseconds
  int get age => DateTime.now().difference(cachedAt).inMilliseconds;

  /// Update TTL for cache entry
  void updateTTL(Duration ttl) {
    expiresAt = DateTime.now().add(ttl);
    lastModified = DateTime.now();
    save(); // Save to Hive
  }

  /// Mark as deleted (soft delete)
  void markDeleted() {
    isDeleted = true;
    lastModified = DateTime.now();
    save();
  }

  @override
  String toString() {
    return 'CachedTransaction(id: $id, title: $title, amount: $amount, '
        'type: $type, cached: $cachedAt, expires: $expiresAt)';
  }
}

import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/transaction.dart';

/// Query parameters for transaction filtering and pagination
class TransactionQuery {
  final int page;
  final int limit;
  final String? category;
  final TransactionType? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  const TransactionQuery({
    this.page = 1,
    this.limit = 20,
    this.category,
    this.type,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });

  TransactionQuery copyWith({
    int? page,
    int? limit,
    String? category,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    return TransactionQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      category: category ?? this.category,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Pagination metadata for API responses
class PaginationMeta {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasMore;

  const PaginationMeta({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasMore,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 20,
      hasMore: json['hasMore'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalItems': totalItems,
      'itemsPerPage': itemsPerPage,
      'hasMore': hasMore,
    };
  }
}

/// Paginated response wrapper
class PaginatedResponse<T> {
  final List<T> data;
  final PaginationMeta meta;

  const PaginatedResponse({
    required this.data,
    required this.meta,
  });
}

/// Repository interface for transaction data
abstract class TransactionRepository {
  /// Get paginated transactions with filtering
  Future<Either<Failure, PaginatedResponse<Transaction>>> getTransactions(
    TransactionQuery query,
  );

  /// Get a single transaction by ID
  Future<Either<Failure, Transaction>> getTransaction(String id);

  /// Create a new transaction
  Future<Either<Failure, Transaction>> createTransaction(Transaction transaction);

  /// Update an existing transaction
  Future<Either<Failure, Transaction>> updateTransaction(Transaction transaction);

  /// Delete a transaction
  Future<Either<Failure, void>> deleteTransaction(String id);

  /// Get cached transactions (for offline support)
  Future<Either<Failure, List<Transaction>>> getCachedTransactions();

  /// Clear transaction cache
  Future<Either<Failure, void>> clearCache();

  /// Sync offline changes when connection is restored
  Future<Either<Failure, void>> syncOfflineChanges();
}
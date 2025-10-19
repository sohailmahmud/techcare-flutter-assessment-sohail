import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/transaction.dart';

/// Query parameters for transaction filtering and pagination
class TransactionQuery {
  final int page;
  final int limit;
  final List<String>? categories;
  final TransactionType? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  final Map<String, dynamic>? amountRange;

  const TransactionQuery({
    this.page = 1,
    this.limit = 20,
    this.categories,
    this.type,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.amountRange,
  });

  TransactionQuery copyWith({
    int? page,
    int? limit,
    List<String>? categories,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    Map<String, dynamic>? amountRange,
  }) {
    return TransactionQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      categories: categories ?? this.categories,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
      amountRange: amountRange ?? this.amountRange,
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
    TransactionQuery query, {
    // Optional Dio cancellation token to allow cancelling outdated requests.
    dynamic cancelToken,
  });

  /// Get a single transaction by ID
  Future<Either<Failure, Transaction>> getTransaction(String id);

  /// Create a new transaction
  Future<Either<Failure, Transaction>> createTransaction(
      Transaction transaction);

  /// Update an existing transaction
  Future<Either<Failure, Transaction>> updateTransaction(
      Transaction transaction);

  /// Delete a transaction
  Future<Either<Failure, void>> deleteTransaction(String id);

  /// Get cached transactions (for offline support)
  Future<Either<Failure, List<Transaction>>> getCachedTransactions();

  /// Clear transaction cache
  Future<Either<Failure, void>> clearCache();

  /// Result of syncing a single queued item
  /// Used to report per-item success/failure when syncing offline operations
  // Simple data holder for an item that failed or succeeded during sync
  // Keeping this in the repository contract keeps the domain layer aware of
  // partial-sync semantics.
  // Note: callers should inspect `failed` to determine if any items failed.
  Future<Either<Failure, SyncResult>> syncOfflineChanges();

  /// Retry a set of previously failed sync items.
  ///
  /// Accepts the failed items (with operation data) and attempts to re-enqueue
  /// and resync them. Returns a SyncResult describing the outcome of the retry.
  Future<Either<Failure, SyncResult>> retryOperations(
      List<ItemSyncResult> failedItems);
}

/// Summary result of a sync run containing succeeded operation ids and
/// failed items with error details.
class SyncResult {
  final List<String> succeededOperationIds;
  final List<ItemSyncResult> failed;
  final Map<String, String> idMap; // tempId -> serverId

  const SyncResult({required this.succeededOperationIds, required this.failed, this.idMap = const {}});

  bool get hasFailures => failed.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'succeededOperationIds': succeededOperationIds,
      'failed': failed.map((f) => f.toJson()).toList(),
    };
  }
}

class ItemSyncResult {
  final String operationId;
  final String operationType;
  final String resourceType;
  final Map<String, dynamic> data;
  final String errorMessage;
  final int retryCount;

  const ItemSyncResult({
    required this.operationId,
    required this.operationType,
    required this.resourceType,
    required this.data,
    required this.errorMessage,
    required this.retryCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId,
      'operationType': operationType,
      'resourceType': resourceType,
      'data': data,
      'errorMessage': errorMessage,
      'retryCount': retryCount,
    };
  }
}

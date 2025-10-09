import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/remote_data_source.dart';
import '../datasources/local_data_source.dart';
import '../models/transaction_model.dart';

/// Implementation of TransactionRepository
class TransactionRepositoryImpl implements TransactionRepository {
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;
  final Connectivity _connectivity;

  TransactionRepositoryImpl({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
    required Connectivity connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _connectivity = connectivity;

  @override
  Future<Either<Failure, PaginatedResponse<Transaction>>> getTransactions(
    TransactionQuery query,
  ) async {
    return _executeWithRetry(() async {
      // Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline) {
        try {
          // Try to fetch from remote
          final remoteResponse = await _remoteDataSource.getTransactions(
            page: query.page,
            limit: query.limit,
            categoryId: query.category,
            type: query.type?.name,
            startDate: query.startDate?.toIso8601String(),
            endDate: query.endDate?.toIso8601String(),
          );

          // Cache the response by converting back to PaginatedTransactionsResponse
          final cacheResponse = PaginatedTransactionsResponse(
            data: remoteResponse.data
                .map((transaction) => TransactionModel.fromEntity(transaction))
                .toList(),
            meta: remoteResponse.meta,
          );
          await _localDataSource.cacheTransactions(query, cacheResponse);

          return Right(remoteResponse);
        } on ServerException catch (e) {
          // If remote fails, try cache
          final cachedResponse =
              await _localDataSource.getCachedTransactions(query);
          if (cachedResponse != null) {
            return Right(cachedResponse.toEntity());
          }
          return Left(ServerFailure(e.toString()));
        }
      } else {
        // Offline - try cache first
        final cachedResponse =
            await _localDataSource.getCachedTransactions(query);
        if (cachedResponse != null) {
          return Right(cachedResponse.toEntity());
        }
        return const Left(NetworkFailure(
            'No internet connection and no cached data available'));
      }
    });
  }

  @override
  Future<Either<Failure, Transaction>> getTransaction(String id) async {
    try {
      // Check cache first
      final cachedTransaction = await _localDataSource.getCachedTransaction(id);

      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline) {
        try {
          // Try to get from remote first by searching
          final response =
              await _remoteDataSource.getTransactions(page: 1, limit: 1000);
          final transaction = response.data.firstWhere(
            (t) => t.id == id,
            orElse: () => throw const ServerException('Transaction not found'),
          );

          // Cache the transaction
          await _localDataSource
              .cacheTransaction(TransactionModel.fromEntity(transaction));

          return Right(transaction);
        } on ServerException catch (e) {
          // If remote fails and we have cache, return cache
          if (cachedTransaction != null) {
            return Right(cachedTransaction.toEntity());
          }
          return Left(ServerFailure(e.toString()));
        }
      } else {
        // Offline - return cache if available
        if (cachedTransaction != null) {
          return Right(cachedTransaction.toEntity());
        }
        return const Left(NetworkFailure(
            'No internet connection and transaction not cached'));
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transaction>> createTransaction(
      Transaction transaction) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      final transactionModel = TransactionModel.fromEntity(transaction);

      if (isOnline) {
        try {
          // Try to create on remote
          final remoteTransaction =
              await _remoteDataSource.createTransaction(transaction);

          // Cache the created transaction
          await _localDataSource
              .cacheTransaction(TransactionModel.fromEntity(remoteTransaction));

          return Right(remoteTransaction);
        } on ServerException {
          // If remote fails, queue for later sync
          await _queuePendingOperation(
            'create',
            'transaction',
            transactionModel.toJson(),
          );

          // Return optimistic result
          return Right(transaction);
        }
      } else {
        // Offline - queue operation and return optimistic result
        await _queuePendingOperation(
          'create',
          'transaction',
          transactionModel.toJson(),
        );

        return Right(transaction);
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transaction>> updateTransaction(
      Transaction transaction) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      final transactionModel = TransactionModel.fromEntity(transaction);

      if (isOnline) {
        try {
          // Try to update on remote
          final remoteTransaction =
              await _remoteDataSource.updateTransaction(transaction);

          // Cache the updated transaction
          await _localDataSource
              .cacheTransaction(TransactionModel.fromEntity(remoteTransaction));

          return Right(remoteTransaction);
        } on ServerException {
          // If remote fails, queue for later sync
          await _queuePendingOperation(
            'update',
            'transaction',
            transactionModel.toJson(),
          );

          // Cache optimistic update
          await _localDataSource.cacheTransaction(transactionModel);

          return Right(transaction);
        }
      } else {
        // Offline - queue operation and cache optimistic result
        await _queuePendingOperation(
          'update',
          'transaction',
          transactionModel.toJson(),
        );

        await _localDataSource.cacheTransaction(transactionModel);

        return Right(transaction);
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline) {
        try {
          // Try to delete on remote
          await _remoteDataSource.deleteTransaction(id);

          // Remove from cache
          await _localDataSource.deleteCachedTransaction(id);

          return const Right(null);
        } on ServerException {
          // If remote fails, queue for later sync
          await _queuePendingOperation(
            'delete',
            'transaction',
            {'id': id},
          );

          // Remove from cache optimistically
          await _localDataSource.deleteCachedTransaction(id);

          return const Right(null);
        }
      } else {
        // Offline - queue operation and remove from cache
        await _queuePendingOperation(
          'delete',
          'transaction',
          {'id': id},
        );

        await _localDataSource.deleteCachedTransaction(id);

        return const Right(null);
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getCachedTransactions() async {
    try {
      // Get all cached transaction pages (this is simplified - in practice you'd need to manage this better)
      final cachedResponse = await _localDataSource.getCachedTransactions(
        const TransactionQuery(limit: 1000), // Get a large batch
      );

      if (cachedResponse != null) {
        return Right(
            cachedResponse.data.map((model) => model.toEntity()).toList());
      }

      return const Right([]);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    try {
      await _localDataSource.clearTransactionCache();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncOfflineChanges() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (!isOnline) {
        return const Left(NetworkFailure('No internet connection for sync'));
      }

      final pendingOperations = await _localDataSource.getPendingOperations();
      final failures = <String>[];

      for (final operation in pendingOperations) {
        if (operation.resourceType != 'transaction') continue;

        try {
          switch (operation.operationType) {
            case 'create':
              final transactionModel =
                  TransactionModel.fromJson(operation.data);
              await _remoteDataSource
                  .createTransaction(transactionModel.toEntity());
              break;
            case 'update':
              final transactionModel =
                  TransactionModel.fromJson(operation.data);
              await _remoteDataSource
                  .updateTransaction(transactionModel.toEntity());
              break;
            case 'delete':
              final id = operation.data['id'] as String;
              await _remoteDataSource.deleteTransaction(id);
              break;
          }

          // Remove successful operation
          await _localDataSource.removePendingOperation(operation.id);
        } on ServerException {
          // Handle retry logic
          if (operation.retryCount < 3) {
            final updatedOperation = operation.copyWith(
              retryCount: operation.retryCount + 1,
            );
            await _localDataSource.removePendingOperation(operation.id);
            await _localDataSource.addPendingOperation(updatedOperation);
          } else {
            failures.add(
                '${operation.operationType} ${operation.resourceType}: ${operation.toString()}');
            await _localDataSource.removePendingOperation(operation.id);
          }
        }
      }

      if (failures.isNotEmpty) {
        return Left(
            SyncFailure('Some operations failed: ${failures.join(', ')}'));
      }

      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<void> _queuePendingOperation(
    String operationType,
    String resourceType,
    Map<String, dynamic> data,
  ) async {
    final operation = PendingOperation(
      id: '${operationType}_${resourceType}_${DateTime.now().millisecondsSinceEpoch}',
      operationType: operationType,
      resourceType: resourceType,
      data: data,
      timestamp: DateTime.now(),
    );

    await _localDataSource.addPendingOperation(operation);
  }

  /// Execute operation with retry mechanism for network operations
  Future<Either<Failure, T>> _executeWithRetry<T>(
    Future<Either<Failure, T>> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final result = await operation();

        // If successful or it's a non-retryable error, return immediately
        if (result.isRight()) {
          return result;
        }

        final failure = result.fold((l) => l, (r) => null);
        if (failure != null && !_isRetryableFailure(failure)) {
          return result;
        }

        // If it's the last attempt, return the failure
        if (attempt == maxRetries - 1) {
          return result;
        }

        // Wait before retrying
        await Future.delayed(delay * (attempt + 1));
      } catch (e) {
        if (attempt == maxRetries - 1) {
          return Left(UnknownFailure(e.toString()));
        }
        await Future.delayed(delay * (attempt + 1));
      }
    }

    return const Left(UnknownFailure('Maximum retries exceeded'));
  }

  /// Check if a failure is retryable
  bool _isRetryableFailure(Failure failure) {
    return failure is NetworkFailure ||
        failure is ServerFailure ||
        (failure is UnknownFailure && failure.message.contains('timeout'));
  }
}

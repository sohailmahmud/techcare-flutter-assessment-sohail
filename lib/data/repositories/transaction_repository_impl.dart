import 'dart:math' as math;

import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../core/sync_notification_service.dart';
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
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _connectivity = connectivity;

  @override
  Future<Either<Failure, PaginatedResponse<Transaction>>> getTransactions(
    TransactionQuery query, {
    dynamic cancelToken,
  }) async {
    return _executeWithRetry(() async {
      // Try to serve from cache first if available and valid. This speeds up UI and
      // ensures previously loaded pages show instantly.
      try {
        final cachedResponse = await _localDataSource.getCachedTransactions(
          query,
        );
        if (cachedResponse != null && cachedResponse.data.isNotEmpty) {
          // Kick off a background refresh if online to update cache, don't await
          _connectivity.checkConnectivity().then((connectivityResult) async {
            final isOnline = connectivityResult != ConnectivityResult.none;
            if (isOnline) {
              try {
                final remoteResponse = await _remoteDataSource.getTransactions(
                  page: query.page,
                  limit: query.limit,
                  categories: query.categories,
                  type: query.type?.name,
                  startDate: query.startDate?.toIso8601String(),
                  endDate: query.endDate?.toIso8601String(),
                  amountRange: query.amountRange,
                  search: query.searchQuery,
                  cancelToken: cancelToken,
                );

                final cacheResponse = PaginatedTransactionsResponse(
                  data: remoteResponse.data
                      .map(
                        (transaction) =>
                            TransactionModel.fromEntity(transaction),
                      )
                      .toList(),
                  meta: remoteResponse.meta,
                );
                await _localDataSource.cacheTransactions(query, cacheResponse);
              } catch (_) {
                // Ignore background failures
              }
            }
          });

          return Right(cachedResponse.toEntity());
        }
      } catch (_) {
        // If cache read fails, continue to try remote fetch below
      }

      // No valid cache found or cache empty — fetch from remote when online
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline) {
        try {
          // Try to fetch from remote
          final remoteResponse = await _remoteDataSource.getTransactions(
            page: query.page,
            limit: query.limit,
            categories: query.categories,
            type: query.type?.name,
            startDate: query.startDate?.toIso8601String(),
            endDate: query.endDate?.toIso8601String(),
            amountRange: query.amountRange,
            search: query.searchQuery,
            cancelToken: cancelToken,
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
        } on NetworkException catch (e) {
          final cachedResponse = await _localDataSource.getCachedTransactions(
            query,
          );
          if (cachedResponse != null) {
            return Right(cachedResponse.toEntity());
          }
          return Left(NetworkFailure(e.toString()));
        } on AuthenticationException catch (e) {
          return Left(AuthenticationFailure(e.toString()));
        } on ValidationException catch (e) {
          // Validation on fetch is unexpected; convert to server failure
          return Left(ServerFailure(e.toString()));
        } on ServerException catch (e) {
          final cachedResponse = await _localDataSource.getCachedTransactions(
            query,
          );
          if (cachedResponse != null) {
            return Right(cachedResponse.toEntity());
          }
          return Left(ServerFailure(e.toString()));
        }
      } else {
        // Offline - try cache first
        final cachedResponse = await _localDataSource.getCachedTransactions(
          query,
        );
        if (cachedResponse != null) {
          return Right(cachedResponse.toEntity());
        }
        return const Left(
          NetworkFailure('No internet connection and no cached data available'),
        );
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
          final response = await _remoteDataSource.getTransactions(
            page: 1,
            limit: 1000,
          );
          final transaction = response.data.firstWhere(
            (t) => t.id == id,
            orElse: () => throw const ServerException('Transaction not found'),
          );

          // Cache the transaction
          await _localDataSource.cacheTransaction(
            TransactionModel.fromEntity(transaction),
          );

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
        return const Left(
          NetworkFailure('No internet connection and transaction not cached'),
        );
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transaction>> createTransaction(
    Transaction transaction,
  ) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      final transactionModel = TransactionModel.fromEntity(transaction);

      if (isOnline) {
        try {
          // Try to create on remote
          final remoteTransaction = await _remoteDataSource.createTransaction(
            transaction,
          );

          // Cache the created transaction
          await _localDataSource.cacheTransaction(
            TransactionModel.fromEntity(remoteTransaction),
          );

          return Right(remoteTransaction);
        } on NetworkException catch (_) {
          // Treat as offline: queue and return optimistic result
          await _queuePendingOperation(
            'create',
            'transaction',
            transactionModel.toJson(),
          );
          try {
            await _localDataSource.cacheTransaction(transactionModel);
          } catch (_) {}
          return Right(transaction);
        } on ValidationException catch (e) {
          return Left(ValidationFailure(e.toString()));
        } on AuthenticationException catch (e) {
          return Left(AuthenticationFailure(e.toString()));
        } on ServerException catch (_) {
          // Queue for later sync and return optimistic result
          await _queuePendingOperation(
            'create',
            'transaction',
            transactionModel.toJson(),
          );
          try {
            await _localDataSource.cacheTransaction(transactionModel);
          } catch (_) {}
          return Right(transaction);
        }
      } else {
        // Offline - queue operation and return optimistic result
        await _queuePendingOperation(
          'create',
          'transaction',
          transactionModel.toJson(),
        );

        // Cache optimistic created transaction locally so UI shows it immediately
        try {
          await _localDataSource.cacheTransaction(transactionModel);
        } catch (_) {}

        return Right(transaction);
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transaction>> updateTransaction(
    Transaction transaction,
  ) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      final transactionModel = TransactionModel.fromEntity(transaction);

      if (isOnline) {
        try {
          // Try to update on remote
          final remoteTransaction = await _remoteDataSource.updateTransaction(
            transaction,
          );

          // Cache the updated transaction
          await _localDataSource.cacheTransaction(
            TransactionModel.fromEntity(remoteTransaction),
          );

          return Right(remoteTransaction);
        } on NetworkException catch (_) {
          await _queuePendingOperation(
            'update',
            'transaction',
            transactionModel.toJson(),
          );
          await _localDataSource.cacheTransaction(transactionModel);
          return Right(transaction);
        } on ValidationException catch (e) {
          return Left(ValidationFailure(e.toString()));
        } on AuthenticationException catch (e) {
          return Left(AuthenticationFailure(e.toString()));
        } on ServerException catch (_) {
          await _queuePendingOperation(
            'update',
            'transaction',
            transactionModel.toJson(),
          );
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
        } on NetworkException catch (_) {
          await _queuePendingOperation('delete', 'transaction', {'id': id});
          await _localDataSource.deleteCachedTransaction(id);
          return const Right(null);
        } on AuthenticationException catch (e) {
          return Left(AuthenticationFailure(e.toString()));
        } on ServerException catch (_) {
          await _queuePendingOperation('delete', 'transaction', {'id': id});
          await _localDataSource.deleteCachedTransaction(id);
          return const Right(null);
        }
      } else {
        // Offline - queue operation and remove from cache
        await _queuePendingOperation('delete', 'transaction', {'id': id});

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
          cachedResponse.data.map((model) => model.toEntity()).toList(),
        );
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
  Future<Either<Failure, SyncResult>> syncOfflineChanges() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (!isOnline) {
        return const Left(NetworkFailure('No internet connection for sync'));
      }

      final pendingOperations = await _localDataSource.getPendingOperations();
      final succeededIds = <String>[];
      final failedItems = <ItemSyncResult>[];
      final idMap = <String, String>{};

      for (final operation in pendingOperations) {
        if (operation.resourceType != 'transaction') continue;

        try {
          switch (operation.operationType) {
            case 'create':
              final transactionModel = TransactionModel.fromJson(
                operation.data,
              );
              final created = await _remoteDataSource.createTransaction(
                transactionModel.toEntity(),
              );

              // If server returned a different ID than the temp one, record mapping
              if (created.id != transactionModel.id) {
                idMap[transactionModel.id] = created.id;

                // Update local cache: remove temp ID entry and cache under server ID
                try {
                  await _localDataSource.deleteCachedTransaction(
                    transactionModel.id,
                  );
                } catch (_) {}
                try {
                  await _localDataSource.cacheTransaction(
                    TransactionModel.fromEntity(created),
                  );
                } catch (_) {}
              } else {
                // Cache created transaction under same id
                try {
                  await _localDataSource.cacheTransaction(
                    TransactionModel.fromEntity(created),
                  );
                } catch (_) {}
              }

              break;
            case 'update':
              final transactionModel = TransactionModel.fromJson(
                operation.data,
              );
              await _remoteDataSource.updateTransaction(
                transactionModel.toEntity(),
              );
              break;
            case 'delete':
              final id = operation.data['id'] as String;
              await _remoteDataSource.deleteTransaction(id);
              break;
          }

          // Remove successful operation
          await _localDataSource.removePendingOperation(operation.id);
          succeededIds.add(operation.id);
        } on ServerException catch (e) {
          // Handle retry logic
          if (operation.retryCount < 3) {
            final updatedOperation = operation.copyWith(
              retryCount: operation.retryCount + 1,
            );
            await _localDataSource.removePendingOperation(operation.id);
            await _localDataSource.addPendingOperation(updatedOperation);
          } else {
            // Record failure but remove from queue so it doesn't block future syncs
            failedItems.add(
              ItemSyncResult(
                operationId: operation.id,
                operationType: operation.operationType,
                resourceType: operation.resourceType,
                data: operation.data,
                errorMessage: e.toString(),
                retryCount: operation.retryCount,
              ),
            );
            await _localDataSource.removePendingOperation(operation.id);
          }
        } catch (e) {
          // Unknown error - treat as failed and remove
          failedItems.add(
            ItemSyncResult(
              operationId: operation.id,
              operationType: operation.operationType,
              resourceType: operation.resourceType,
              data: operation.data,
              errorMessage: e.toString(),
              retryCount: operation.retryCount,
            ),
          );
          await _localDataSource.removePendingOperation(operation.id);
        }
      }

      final result = SyncResult(
        succeededOperationIds: succeededIds,
        failed: failedItems,
        idMap: idMap,
      );

      // If we have id mappings from temp -> server IDs, apply them to local
      // caches and pending operations so the app consistently references the
      // server-assigned IDs.
      if (idMap.isNotEmpty) {
        try {
          await _localDataSource.replaceTempIds(idMap);
        } catch (_) {
          // Ignore local replacement failures; sync already succeeded on
          // remote side and will be retried where necessary.
        }
      }

      // Notify SyncNotificationService (if registered) so UI layers and
      // BLoCs that listen on its stream can react (e.g., apply idMap). This
      // keeps the notification in-process and immediate.
      try {
        final sl = GetIt.instance;
        if (sl.isRegistered<SyncNotificationService>()) {
          final svc = sl<SyncNotificationService>();
          svc.notify(result);
        }
      } catch (_) {}

      return Right(result);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SyncResult>> retryOperations(
    List<ItemSyncResult> failedItems,
  ) async {
    try {
      // Re-enqueue failed items with retryCount reset to 0 (or decrement if desired)
      for (final item in failedItems) {
        final operation = PendingOperation(
          id: item.operationId,
          operationType: item.operationType,
          resourceType: item.resourceType,
          data: item.data,
          timestamp: DateTime.now(),
          retryCount: 0,
        );

        await _localDataSource.addPendingOperation(operation);
      }

      // Trigger a sync run to attempt the retried operations
      return await syncOfflineChanges();
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
    Duration baseDelay = const Duration(milliseconds: 500),
    Duration maxDelay = const Duration(seconds: 10),
  }) async {
    final rng = math.Random();
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

        // Compute exponential backoff with jitter
        final multiplier = math.pow(2, attempt).toInt();
        var waitMs = baseDelay.inMilliseconds * multiplier;
        if (waitMs > maxDelay.inMilliseconds) waitMs = maxDelay.inMilliseconds;
        // Add jitter up to 50% of waitMs
        final jitter = (rng.nextDouble() * 0.5 * waitMs).toInt();
        final totalWait = Duration(milliseconds: waitMs + jitter);
        await Future.delayed(totalWait);
      } catch (e) {
        if (attempt == maxRetries - 1) {
          return Left(UnknownFailure(e.toString()));
        }
        // Compute exponential backoff with jitter on exception as well
        final multiplier = math.pow(2, attempt).toInt();
        var waitMs = baseDelay.inMilliseconds * multiplier;
        if (waitMs > maxDelay.inMilliseconds) waitMs = maxDelay.inMilliseconds;
        final jitter = (rng.nextDouble() * 0.5 * waitMs).toInt();
        final totalWait = Duration(milliseconds: waitMs + jitter);
        await Future.delayed(totalWait);
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

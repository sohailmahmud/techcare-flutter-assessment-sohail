import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/entities/analytics.dart';
import '../datasources/remote_data_source.dart';
import '../datasources/local_data_source.dart';

/// Implementation of AnalyticsRepository
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;
  final Connectivity _connectivity;

  AnalyticsRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivity,
  );

  @override
  Future<Either<Failure, AnalyticsData>> getAnalytics(
      AnalyticsQuery query) async {
    try {
      // Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline) {
        try {
          // Try to fetch from remote
          final remoteAnalytics = await _remoteDataSource.getAnalyticsSummary(
            startDate: query.startDate.toIso8601String(),
            endDate: query.endDate.toIso8601String(),
          );

          // Cache the data model directly
          await _localDataSource.cacheAnalytics(query, remoteAnalytics);

          return Right(remoteAnalytics.toEntity());
        } on ServerException catch (e) {
          // If remote fails, try cache
          final cachedAnalytics =
              await _localDataSource.getCachedAnalytics(query);
          if (cachedAnalytics != null) {
            return Right(cachedAnalytics.toEntity());
          }
          return Left(ServerFailure(e.message));
        } on NetworkException catch (e) {
          // If network fails, try cache
          final cachedAnalytics =
              await _localDataSource.getCachedAnalytics(query);
          if (cachedAnalytics != null) {
            return Right(cachedAnalytics.toEntity());
          }
          return Left(NetworkFailure(e.message));
        }
      } else {
        // Offline - try cache first
        final cachedAnalytics =
            await _localDataSource.getCachedAnalytics(query);
        if (cachedAnalytics != null) {
          return Right(cachedAnalytics.toEntity());
        }
        return const Left(NetworkFailure(
            'No internet connection and no cached analytics available'));
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AnalyticsData?>> getCachedAnalytics(
      AnalyticsQuery query) async {
    try {
      final cachedAnalytics = await _localDataSource.getCachedAnalytics(query);
      return Right(cachedAnalytics?.toEntity());
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    try {
      await _localDataSource.clearAnalyticsCache();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}

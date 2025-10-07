import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/mock_dashboard_datasource.dart';

/// Dashboard repository implementation
class DashboardRepositoryImpl implements DashboardRepository {
  final MockDashboardDataSource dataSource;

  DashboardRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, DashboardSummary>> getDashboardSummary() async {
    try {
      final summary = await dataSource.getDashboardSummary();
      return Right(summary);
    } catch (e) {
      return const Left(CacheFailure('Failed to load dashboard data'));
    }
  }

  @override
  Future<Either<Failure, DashboardSummary>> refreshDashboard() async {
    try {
      final summary = await dataSource.getDashboardSummary();
      return Right(summary);
    } catch (e) {
      return const Left(NetworkFailure('Failed to refresh dashboard data'));
    }
  }
}
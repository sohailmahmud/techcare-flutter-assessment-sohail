import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/dashboard_summary.dart';

/// Repository interface for dashboard data
abstract class DashboardRepository {
  /// Get dashboard summary with financial overview
  Future<Either<Failure, DashboardSummary>> getDashboardSummary();

  /// Refresh dashboard data
  Future<Either<Failure, DashboardSummary>> refreshDashboard();
}
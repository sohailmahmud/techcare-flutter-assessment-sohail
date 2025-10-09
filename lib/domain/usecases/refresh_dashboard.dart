import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

/// Use case to refresh dashboard data
class RefreshDashboard implements UseCase<DashboardSummary, NoParams> {
  final DashboardRepository repository;

  RefreshDashboard(this.repository);

  @override
  Future<Either<Failure, DashboardSummary>> call(NoParams params) async {
    return await repository.refreshDashboard();
  }
}

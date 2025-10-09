import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/analytics.dart';
import '../repositories/analytics_repository.dart';

/// Use case to get analytics data
class GetAnalytics implements UseCase<AnalyticsData, AnalyticsQuery> {
  final AnalyticsRepository repository;

  GetAnalytics(this.repository);

  @override
  Future<Either<Failure, AnalyticsData>> call(AnalyticsQuery params) async {
    return await repository.getAnalytics(params);
  }
}

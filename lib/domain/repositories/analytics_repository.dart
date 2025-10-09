import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/analytics.dart';

/// Query parameters for analytics
class AnalyticsQuery {
  final DateTime startDate;
  final DateTime endDate;

  const AnalyticsQuery({
    required this.startDate,
    required this.endDate,
  });
}

/// Repository interface for analytics data
abstract class AnalyticsRepository {
  /// Get analytics data for a date range
  Future<Either<Failure, AnalyticsData>> getAnalytics(AnalyticsQuery query);

  /// Get cached analytics (for offline support)
  Future<Either<Failure, AnalyticsData?>> getCachedAnalytics(AnalyticsQuery query);

  /// Clear analytics cache
  Future<Either<Failure, void>> clearCache();
}
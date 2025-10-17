import 'package:json_annotation/json_annotation.dart';
import 'category_model.dart';
import '../../domain/entities/analytics.dart';

part 'analytics_model.g.dart';

@JsonSerializable()
class AnalyticsSummaryModel {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final double savingsRate;

  const AnalyticsSummaryModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.savingsRate,
  });

  factory AnalyticsSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsSummaryModelToJson(this);
}

@JsonSerializable()
class CategoryBreakdownModel {
  final CategoryModel category;
  final double amount;
  final double percentage;
  final int transactionCount;
  final double budget;
  final double budgetUtilization;

  const CategoryBreakdownModel({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
    required this.budget,
    required this.budgetUtilization,
  });

  factory CategoryBreakdownModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryBreakdownModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryBreakdownModelToJson(this);
}

@JsonSerializable()
class MonthlyTrendModel {
  final String month;
  final double income;
  final double expense;

  const MonthlyTrendModel({
    required this.month,
    required this.income,
    required this.expense,
  });

  factory MonthlyTrendModel.fromJson(Map<String, dynamic> json) =>
      _$MonthlyTrendModelFromJson(json);

  Map<String, dynamic> toJson() => _$MonthlyTrendModelToJson(this);
}

@JsonSerializable()
class AnalyticsDataModel {
  final AnalyticsSummaryModel summary;
  final List<CategoryBreakdownModel> categoryBreakdown;
  final List<MonthlyTrendModel> monthlyTrend;

  const AnalyticsDataModel({
    required this.summary,
    required this.categoryBreakdown,
    required this.monthlyTrend,
  });

  factory AnalyticsDataModel.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsDataModelToJson(this);

  /// Convert to domain entity
  AnalyticsData toEntity() {
    final dateRange = DateRange(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );

    return AnalyticsData(
      dateRange: dateRange,
      period: TimePeriod.thisMonth,
      totalIncome: summary.totalIncome,
      totalExpenses: summary.totalExpense,
      netBalance: summary.netBalance,
      savingsRate: summary.savingsRate,
      totalTransactions: categoryBreakdown.fold<int>(
        0, (sum, cat) => sum + cat.transactionCount),
      averageTransactionAmount: categoryBreakdown.isNotEmpty
          ? categoryBreakdown.map((c) => c.amount).reduce((a, b) => a + b) /
              categoryBreakdown.length
          : 0.0,
      lastUpdated: DateTime.now(),
      categoryBreakdown: categoryBreakdown
          .map((model) => CategoryBreakdown(
                category: model.category.toEntity(),
                amount: model.amount,
                percentage: model.percentage,
                transactionCount: model.transactionCount,
                budget: model.budget,
                budgetUtilization: model.budgetUtilization,
              ))
          .toList(),
      budgetComparisons: const [], // No budget comparisons in this model
      trendData: TrendData(
        dateRange: dateRange,
        incomePoints: monthlyTrend
            .map((trend) => ChartDataPoint(
                  label: trend.month,
                  value: trend.income,
                  date: _parseMonthString(trend.month),
                ))
            .toList(),
        expensePoints: monthlyTrend
            .map((trend) => ChartDataPoint(
                  label: trend.month,
                  value: trend.expense,
                  date: _parseMonthString(trend.month),
                ))
            .toList(),
      ),
      categories: categoryBreakdown.map((model) => model.category.toEntity()).toList(),
    );
  }

  /// Parse month string (e.g., "2025-04") to DateTime
  DateTime _parseMonthString(String monthString) {
    try {
      final parts = monthString.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        return DateTime(year, month);
      }
    } catch (e) {
      // Fallback to current date if parsing fails
    }
    return DateTime.now();
  }
}

@JsonSerializable()
class AnalyticsResponse {
  final AnalyticsDataModel analytics;

  const AnalyticsResponse({required this.analytics});

  factory AnalyticsResponse.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsResponseToJson(this);
}

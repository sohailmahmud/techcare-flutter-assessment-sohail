import 'package:equatable/equatable.dart';
import '../../domain/entities/category.dart';

/// Enum for different time period options
enum TimePeriod {
  thisWeek,
  thisMonth,
  lastThreeMonths,
  custom,
}

extension TimePeriodExtension on TimePeriod {
  String get displayName {
    switch (this) {
      case TimePeriod.thisWeek:
        return 'This Week';
      case TimePeriod.thisMonth:
        return 'This Month';
      case TimePeriod.lastThreeMonths:
        return 'Last 3 Months';
      case TimePeriod.custom:
        return 'Custom';
    }
  }

  String get shortName {
    switch (this) {
      case TimePeriod.thisWeek:
        return 'Week';
      case TimePeriod.thisMonth:
        return 'Month';
      case TimePeriod.lastThreeMonths:
        return '3M';
      case TimePeriod.custom:
        return 'Custom';
    }
  }
}

/// Model for date range selection
class DateRange extends Equatable {
  final DateTime startDate;
  final DateTime endDate;

  const DateRange({
    required this.startDate,
    required this.endDate,
  });

  DateRange copyWith({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return DateRange(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  bool contains(DateTime date) {
    return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
           date.isBefore(endDate.add(const Duration(days: 1)));
  }

  Duration get duration => endDate.difference(startDate);

  int get dayCount => duration.inDays + 1;

  @override
  List<Object> get props => [startDate, endDate];
}

/// Model for summary statistics
class SummaryStatistics extends Equatable {
  final double totalIncome;
  final double totalExpenses;
  final double netBalance;
  final double incomeChange; // Percentage change from previous period
  final double expenseChange; // Percentage change from previous period
  final double balanceChange; // Percentage change from previous period

  const SummaryStatistics({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netBalance,
    required this.incomeChange,
    required this.expenseChange,
    required this.balanceChange,
  });

  factory SummaryStatistics.empty() {
    return const SummaryStatistics(
      totalIncome: 0,
      totalExpenses: 0,
      netBalance: 0,
      incomeChange: 0,
      expenseChange: 0,
      balanceChange: 0,
    );
  }

  @override
  List<Object> get props => [
        totalIncome,
        totalExpenses,
        netBalance,
        incomeChange,
        expenseChange,
        balanceChange,
      ];
}

/// Data point for trend charts
class TrendDataPoint extends Equatable {
  final DateTime date;
  final double income;
  final double expenses;

  const TrendDataPoint({
    required this.date,
    required this.income,
    required this.expenses,
  });

  double get netAmount => income - expenses;

  @override
  List<Object> get props => [date, income, expenses];
}

/// Model for category spending data
class CategorySpendingData extends Equatable {
  final Category category;
  final double amount;
  final double percentage;
  final int transactionCount;

  const CategorySpendingData({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
  });

  @override
  List<Object> get props => [category, amount, percentage, transactionCount];
}

/// Model for budget progress tracking
class BudgetProgress extends Equatable {
  final Category category;
  final double budgetAmount;
  final double spentAmount;
  final double percentage;
  final BudgetStatus status;

  const BudgetProgress({
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
    required this.percentage,
    required this.status,
  });

  factory BudgetProgress.fromCategorySpending({
    required Category category,
    required double budgetAmount,
    required double spentAmount,
  }) {
    final percentage = budgetAmount > 0 ? (spentAmount / budgetAmount) * 100 : 0.0;
    final status = BudgetStatusExtension.fromPercentage(percentage);

    return BudgetProgress(
      category: category,
      budgetAmount: budgetAmount,
      spentAmount: spentAmount,
      percentage: percentage,
      status: status,
    );
  }

  double get remainingAmount => budgetAmount - spentAmount;

  bool get isOverBudget => spentAmount > budgetAmount;

  @override
  List<Object> get props => [category, budgetAmount, spentAmount, percentage, status];
}

/// Enum for budget status color coding
enum BudgetStatus {
  underBudget,    // 0-70% - Green
  approaching,    // 71-90% - Yellow
  exceeded,       // >90% - Red
}

extension BudgetStatusExtension on BudgetStatus {
  static BudgetStatus fromPercentage(double percentage) {
    if (percentage <= 70) {
      return BudgetStatus.underBudget;
    } else if (percentage <= 90) {
      return BudgetStatus.approaching;
    } else {
      return BudgetStatus.exceeded;
    }
  }

  String get displayName {
    switch (this) {
      case BudgetStatus.underBudget:
        return 'Under Budget';
      case BudgetStatus.approaching:
        return 'Approaching Limit';
      case BudgetStatus.exceeded:
        return 'Over Budget';
    }
  }
}

/// Comprehensive analytics data model
class AnalyticsData extends Equatable {
  final TimePeriod timePeriod;
  final DateRange dateRange;
  final SummaryStatistics summary;
  final List<TrendDataPoint> trendData;
  final List<CategorySpendingData> categoryBreakdown;
  final List<BudgetProgress> budgetProgress;
  final DateTime lastUpdated;

  const AnalyticsData({
    required this.timePeriod,
    required this.dateRange,
    required this.summary,
    required this.trendData,
    required this.categoryBreakdown,
    required this.budgetProgress,
    required this.lastUpdated,
  });

  factory AnalyticsData.empty() {
    final now = DateTime.now();
    return AnalyticsData(
      timePeriod: TimePeriod.thisMonth,
      dateRange: DateRange(
        startDate: DateTime(now.year, now.month, 1),
        endDate: now,
      ),
      summary: SummaryStatistics.empty(),
      trendData: const [],
      categoryBreakdown: const [],
      budgetProgress: const [],
      lastUpdated: now,
    );
  }

  AnalyticsData copyWith({
    TimePeriod? timePeriod,
    DateRange? dateRange,
    SummaryStatistics? summary,
    List<TrendDataPoint>? trendData,
    List<CategorySpendingData>? categoryBreakdown,
    List<BudgetProgress>? budgetProgress,
    DateTime? lastUpdated,
  }) {
    return AnalyticsData(
      timePeriod: timePeriod ?? this.timePeriod,
      dateRange: dateRange ?? this.dateRange,
      summary: summary ?? this.summary,
      trendData: trendData ?? this.trendData,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      budgetProgress: budgetProgress ?? this.budgetProgress,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object> get props => [
        timePeriod,
        dateRange,
        summary,
        trendData,
        categoryBreakdown,
        budgetProgress,
        lastUpdated,
      ];
}

/// Utility class for date range calculations
class DateRangeUtils {
  static DateRange getDateRangeForPeriod(TimePeriod period, {DateRange? customRange}) {
    final now = DateTime.now();
    
    switch (period) {
      case TimePeriod.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateRange(
          startDate: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          endDate: now,
        );
        
      case TimePeriod.thisMonth:
        return DateRange(
          startDate: DateTime(now.year, now.month, 1),
          endDate: now,
        );
        
      case TimePeriod.lastThreeMonths:
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        return DateRange(
          startDate: threeMonthsAgo,
          endDate: now,
        );
        
      case TimePeriod.custom:
        return customRange ?? DateRange(
          startDate: DateTime(now.year, now.month, 1),
          endDate: now,
        );
    }
  }

  static DateRange getPreviousPeriod(DateRange currentRange) {
    final duration = currentRange.duration;
    return DateRange(
      startDate: currentRange.startDate.subtract(duration),
      endDate: currentRange.startDate.subtract(const Duration(days: 1)),
    );
  }
}
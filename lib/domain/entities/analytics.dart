import 'package:equatable/equatable.dart';

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

  /// Get a human-readable description of the date range
  String get description {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(this.startDate.year, this.startDate.month, this.startDate.day);
    final endDate = DateTime(this.endDate.year, this.endDate.month, this.endDate.day);

    if (startDate == endDate) {
      if (startDate == today) {
        return 'Today';
      } else {
        return _formatDate(startDate);
      }
    } else {
      return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get the number of days in this date range
  int get dayCount {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Check if the date range contains the given date
  bool contains(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    
    return (dateOnly.isAfter(startOnly) || dateOnly.isAtSameMomentAs(startOnly)) &&
           (dateOnly.isBefore(endOnly) || dateOnly.isAtSameMomentAs(endOnly));
  }

  @override
  List<Object> get props => [startDate, endDate];
}

/// Model for chart data points
class ChartDataPoint extends Equatable {
  final String label;
  final double value;
  final DateTime date;
  final String? category;

  const ChartDataPoint({
    required this.label,
    required this.value,
    required this.date,
    this.category,
  });

  @override
  List<Object?> get props => [label, value, date, category];
}

/// Model for trend data over time
class TrendData extends Equatable {
  final List<ChartDataPoint> incomePoints;
  final List<ChartDataPoint> expensePoints;
  final DateRange dateRange;

  const TrendData({
    required this.incomePoints,
    required this.expensePoints,
    required this.dateRange,
  });

  /// Get the maximum value across all data points
  double get maxValue {
    final incomeMax = incomePoints.isEmpty ? 0.0 : incomePoints.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final expenseMax = expensePoints.isEmpty ? 0.0 : expensePoints.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return incomeMax > expenseMax ? incomeMax : expenseMax;
  }

  /// Get the total income for the period
  double get totalIncome {
    return incomePoints.fold(0.0, (sum, point) => sum + point.value);
  }

  /// Get the total expenses for the period
  double get totalExpenses {
    return expensePoints.fold(0.0, (sum, point) => sum + point.value);
  }

  /// Get the net amount (income - expenses)
  double get netAmount {
    return totalIncome - totalExpenses;
  }

  @override
  List<Object> get props => [incomePoints, expensePoints, dateRange];
}

/// Model for category breakdown data
class CategoryBreakdown extends Equatable {
  final String categoryId;
  final String categoryName;
  final double amount;
  final int transactionCount;
  final double percentage;

  const CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.transactionCount,
    required this.percentage,
  });

  @override
  List<Object> get props => [categoryId, categoryName, amount, transactionCount, percentage];
}

/// Model for budget vs actual spending
class BudgetComparison extends Equatable {
  final String categoryId;
  final String categoryName;
  final double budgetAmount;
  final double actualAmount;
  final double remainingAmount;
  final double percentage;
  final bool isOverBudget;

  const BudgetComparison({
    required this.categoryId,
    required this.categoryName,
    required this.budgetAmount,
    required this.actualAmount,
    required this.remainingAmount,
    required this.percentage,
    required this.isOverBudget,
  });

  /// Factory constructor to create from budget and actual amounts
  factory BudgetComparison.fromAmounts({
    required String categoryId,
    required String categoryName,
    required double budgetAmount,
    required double actualAmount,
  }) {
    final remaining = budgetAmount - actualAmount;
    final percentage = budgetAmount > 0 ? (actualAmount / budgetAmount) * 100 : 0.0;
    final isOverBudget = actualAmount > budgetAmount;

    return BudgetComparison(
      categoryId: categoryId,
      categoryName: categoryName,
      budgetAmount: budgetAmount,
      actualAmount: actualAmount,
      remainingAmount: remaining,
      percentage: percentage,
      isOverBudget: isOverBudget,
    );
  }

  @override
  List<Object> get props => [
        categoryId,
        categoryName,
        budgetAmount,
        actualAmount,
        remainingAmount,
        percentage,
        isOverBudget,
      ];
}

/// Complete analytics data model
class AnalyticsData extends Equatable {
  final DateRange dateRange;
  final TimePeriod period;
  final TrendData trendData;
  final List<CategoryBreakdown> categoryBreakdown;
  final List<BudgetComparison> budgetComparisons;
  final double totalIncome;
  final double totalExpenses;
  final double netAmount;
  final int totalTransactions;
  final double averageTransactionAmount;
  final DateTime lastUpdated;

  const AnalyticsData({
    required this.dateRange,
    required this.period,
    required this.trendData,
    required this.categoryBreakdown,
    required this.budgetComparisons,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netAmount,
    required this.totalTransactions,
    required this.averageTransactionAmount,
    required this.lastUpdated,
  });

  /// Get savings rate as a percentage
  double get savingsRate {
    if (totalIncome <= 0) return 0.0;
    return ((totalIncome - totalExpenses) / totalIncome) * 100;
  }

  /// Get the category with highest spending
  CategoryBreakdown? get topSpendingCategory {
    if (categoryBreakdown.isEmpty) return null;
    return categoryBreakdown.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  /// Get budget adherence percentage (categories within budget / total categories)
  double get budgetAdherenceRate {
    if (budgetComparisons.isEmpty) return 100.0;
    final withinBudget = budgetComparisons.where((b) => !b.isOverBudget).length;
    return (withinBudget / budgetComparisons.length) * 100;
  }

  /// Copy with new values
  AnalyticsData copyWith({
    DateRange? dateRange,
    TimePeriod? period,
    TrendData? trendData,
    List<CategoryBreakdown>? categoryBreakdown,
    List<BudgetComparison>? budgetComparisons,
    double? totalIncome,
    double? totalExpenses,
    double? netAmount,
    int? totalTransactions,
    double? averageTransactionAmount,
    DateTime? lastUpdated,
  }) {
    return AnalyticsData(
      dateRange: dateRange ?? this.dateRange,
      period: period ?? this.period,
      trendData: trendData ?? this.trendData,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      budgetComparisons: budgetComparisons ?? this.budgetComparisons,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netAmount: netAmount ?? this.netAmount,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      averageTransactionAmount: averageTransactionAmount ?? this.averageTransactionAmount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object> get props => [
        dateRange,
        period,
        trendData,
        categoryBreakdown,
        budgetComparisons,
        totalIncome,
        totalExpenses,
        netAmount,
        totalTransactions,
        averageTransactionAmount,
        lastUpdated,
      ];
}
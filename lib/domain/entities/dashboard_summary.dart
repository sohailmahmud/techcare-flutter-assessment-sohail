import 'package:equatable/equatable.dart';
import 'transaction.dart';

/// Dashboard summary entity containing financial overview
class DashboardSummary extends Equatable {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final List<CategoryExpense> categoryExpenses;
  final List<Transaction> recentTransactions;
  final DateTime lastUpdated;

  const DashboardSummary({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.categoryExpenses,
    required this.recentTransactions,
    required this.lastUpdated,
  });

  double get monthlySavings => monthlyIncome - monthlyExpense;
  double get savingsRate =>
      monthlyIncome > 0 ? (monthlySavings / monthlyIncome) * 100 : 0;

  @override
  List<Object?> get props => [
    totalBalance,
    monthlyIncome,
    monthlyExpense,
    categoryExpenses,
    recentTransactions,
    lastUpdated,
  ];
}

/// Category-wise expense breakdown
class CategoryExpense extends Equatable {
  final String categoryId;
  final String categoryName;
  final double amount;
  final double percentage;
  final int transactionCount;

  const CategoryExpense({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
  });

  @override
  List<Object?> get props => [
    categoryId,
    categoryName,
    amount,
    percentage,
    transactionCount,
  ];
}

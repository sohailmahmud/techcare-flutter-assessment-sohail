import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fintrack/domain/entities/dashboard_summary.dart';
import 'package:fintrack/domain/entities/transaction.dart';
import 'package:fintrack/domain/entities/category.dart';

void main() {
  group('DashboardSummary Entity', () {
    const testCategory = Category(
      id: 'cat1',
      name: 'Food',
      icon: Icons.restaurant,
      color: Colors.orange,
      isIncome: false,
    );

    final testTransaction = Transaction(
      id: 'trans1',
      title: 'Lunch',
      amount: 25.50,
      type: TransactionType.expense,
      category: testCategory,
      date: DateTime(2024, 1, 15),
    );

    const categoryExpense = CategoryExpense(
      categoryId: 'cat1',
      categoryName: 'Food',
      amount: 150.0,
      percentage: 30.0,
      transactionCount: 5,
    );

    final dashboardSummary = DashboardSummary(
      totalBalance: 5000.0,
      monthlyIncome: 8000.0,
      monthlyExpense: 3000.0,
      categoryExpenses: const [categoryExpense],
      recentTransactions: [testTransaction],
      lastUpdated: DateTime(2024, 1, 15, 10, 30),
    );

    test('should create DashboardSummary instance correctly', () {
      expect(dashboardSummary.totalBalance, equals(5000.0));
      expect(dashboardSummary.monthlyIncome, equals(8000.0));
      expect(dashboardSummary.monthlyExpense, equals(3000.0));
      expect(dashboardSummary.categoryExpenses, contains(categoryExpense));
      expect(dashboardSummary.recentTransactions, contains(testTransaction));
      expect(
          dashboardSummary.lastUpdated, equals(DateTime(2024, 1, 15, 10, 30)));
    });

    group('Calculated Properties', () {
      test('should calculate monthly savings correctly', () {
        expect(dashboardSummary.monthlySavings, equals(5000.0)); // 8000 - 3000
      });

      test('should calculate savings rate correctly', () {
        expect(
            dashboardSummary.savingsRate, equals(62.5)); // (5000 / 8000) * 100
      });

      test('should handle zero income for savings rate', () {
        final zeroIncomeSummary = DashboardSummary(
          totalBalance: 1000.0,
          monthlyIncome: 0.0,
          monthlyExpense: 500.0,
          categoryExpenses: const [],
          recentTransactions: const [],
          lastUpdated: DateTime.now(),
        );

        expect(zeroIncomeSummary.savingsRate, equals(0.0));
        expect(zeroIncomeSummary.monthlySavings, equals(-500.0));
      });

      test('should handle negative savings correctly', () {
        final negativeSavingsSummary = DashboardSummary(
          totalBalance: 1000.0,
          monthlyIncome: 2000.0,
          monthlyExpense: 3000.0,
          categoryExpenses: const [],
          recentTransactions: const [],
          lastUpdated: DateTime.now(),
        );

        expect(negativeSavingsSummary.monthlySavings, equals(-1000.0));
        expect(negativeSavingsSummary.savingsRate, equals(-50.0));
      });
    });

    group('Equality and Props', () {
      test('should be equal to another summary with same properties', () {
        final anotherSummary = DashboardSummary(
          totalBalance: 5000.0,
          monthlyIncome: 8000.0,
          monthlyExpense: 3000.0,
          categoryExpenses: const [categoryExpense],
          recentTransactions: [testTransaction],
          lastUpdated: DateTime(2024, 1, 15, 10, 30),
        );

        expect(dashboardSummary, equals(anotherSummary));
        expect(dashboardSummary.hashCode, equals(anotherSummary.hashCode));
      });

      test('should not be equal to summary with different properties', () {
        final differentSummary = DashboardSummary(
          totalBalance: 6000.0, // Different balance
          monthlyIncome: 8000.0,
          monthlyExpense: 3000.0,
          categoryExpenses: const [categoryExpense],
          recentTransactions: [testTransaction],
          lastUpdated: DateTime(2024, 1, 15, 10, 30),
        );

        expect(dashboardSummary, isNot(equals(differentSummary)));
      });

      test('should include all properties in props list', () {
        expect(dashboardSummary.props, contains(dashboardSummary.totalBalance));
        expect(
            dashboardSummary.props, contains(dashboardSummary.monthlyIncome));
        expect(
            dashboardSummary.props, contains(dashboardSummary.monthlyExpense));
        expect(dashboardSummary.props,
            contains(dashboardSummary.categoryExpenses));
        expect(dashboardSummary.props,
            contains(dashboardSummary.recentTransactions));
        expect(dashboardSummary.props, contains(dashboardSummary.lastUpdated));
      });
    });

    group('Edge Cases', () {
      test('should handle empty lists', () {
        final emptySummary = DashboardSummary(
          totalBalance: 0.0,
          monthlyIncome: 0.0,
          monthlyExpense: 0.0,
          categoryExpenses: const [],
          recentTransactions: const [],
          lastUpdated: DateTime.now(),
        );

        expect(emptySummary.categoryExpenses, isEmpty);
        expect(emptySummary.recentTransactions, isEmpty);
        expect(emptySummary.monthlySavings, equals(0.0));
        expect(emptySummary.savingsRate, equals(0.0));
      });

      test('should handle large numbers', () {
        final largeSummary = DashboardSummary(
          totalBalance: 1000000.0,
          monthlyIncome: 100000.0,
          monthlyExpense: 50000.0,
          categoryExpenses: const [],
          recentTransactions: const [],
          lastUpdated: DateTime.now(),
        );

        expect(largeSummary.monthlySavings, equals(50000.0));
        expect(largeSummary.savingsRate, equals(50.0));
      });
    });
  });

  group('CategoryExpense Entity', () {
    const categoryExpense = CategoryExpense(
      categoryId: 'cat1',
      categoryName: 'Food',
      amount: 250.0,
      percentage: 25.0,
      transactionCount: 10,
    );

    test('should create CategoryExpense instance correctly', () {
      expect(categoryExpense.categoryId, equals('cat1'));
      expect(categoryExpense.categoryName, equals('Food'));
      expect(categoryExpense.amount, equals(250.0));
      expect(categoryExpense.percentage, equals(25.0));
      expect(categoryExpense.transactionCount, equals(10));
    });

    test('should be equal to another CategoryExpense with same properties', () {
      const anotherExpense = CategoryExpense(
        categoryId: 'cat1',
        categoryName: 'Food',
        amount: 250.0,
        percentage: 25.0,
        transactionCount: 10,
      );

      expect(categoryExpense, equals(anotherExpense));
      expect(categoryExpense.hashCode, equals(anotherExpense.hashCode));
    });

    test('should not be equal to CategoryExpense with different properties',
        () {
      const differentExpense = CategoryExpense(
        categoryId: 'cat1',
        categoryName: 'Food',
        amount: 300.0, // Different amount
        percentage: 25.0,
        transactionCount: 10,
      );

      expect(categoryExpense, isNot(equals(differentExpense)));
    });

    group('Edge Cases', () {
      test('should handle zero values', () {
        const zeroExpense = CategoryExpense(
          categoryId: 'cat2',
          categoryName: 'Entertainment',
          amount: 0.0,
          percentage: 0.0,
          transactionCount: 0,
        );

        expect(zeroExpense.amount, equals(0.0));
        expect(zeroExpense.percentage, equals(0.0));
        expect(zeroExpense.transactionCount, equals(0));
      });

      test('should handle high percentage values', () {
        const highPercentageExpense = CategoryExpense(
          categoryId: 'cat3',
          categoryName: 'Rent',
          amount: 2000.0,
          percentage: 80.0,
          transactionCount: 1,
        );

        expect(highPercentageExpense.percentage, equals(80.0));
        expect(highPercentageExpense.transactionCount, equals(1));
      });
    });
  });
}

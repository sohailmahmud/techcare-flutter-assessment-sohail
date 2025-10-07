import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/transaction.dart';

/// Mock data source for dashboard
class MockDashboardDataSource {
  /// Simulate API delay
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 1500)); // Realistic API delay
  }

  /// Get mock dashboard summary
  Future<DashboardSummary> getDashboardSummary() async {
    await _simulateDelay();

    final now = DateTime.now();
    final recentTransactions = _generateMockTransactions();
    final categoryExpenses = _generateCategoryExpenses();

    return DashboardSummary(
      totalBalance: 78450.00, // Calculated from: 100000 (total income) - 21550 (total expenses)
      monthlyIncome: 100000.00, // Salary (85000) + Freelance (15000)
      monthlyExpense: 14600.00, // Total of all expense transactions
      categoryExpenses: categoryExpenses,
      recentTransactions: recentTransactions,
      lastUpdated: now,
    );
  }

  List<Transaction> _generateMockTransactions() {
    return [
      Transaction(
        id: 'txn_001',
        title: 'Salary',
        amount: 85000.00,
        type: TransactionType.income,
        categoryId: 'cat_income',
        categoryName: 'Salary',
        date: DateTime.parse('2025-10-01T00:00:00Z'),
        notes: 'Monthly salary deposit',
        createdAt: DateTime.parse('2025-10-01T00:00:00Z'),
      ),
      Transaction(
        id: 'txn_002',
        title: 'Grocery Shopping',
        amount: 2500.00,
        type: TransactionType.expense,
        categoryId: 'cat_001',
        categoryName: 'Food & Dining',
        date: DateTime.parse('2025-10-01T10:30:00Z'),
        notes: 'Weekly groceries from Shwapno',
        createdAt: DateTime.parse('2025-10-01T10:30:00Z'),
      ),
      Transaction(
        id: 'txn_003',
        title: 'Uber Ride',
        amount: 350.00,
        type: TransactionType.expense,
        categoryId: 'cat_002',
        categoryName: 'Transportation',
        date: DateTime.parse('2025-10-01T14:15:00Z'),
        notes: 'Ride to office',
        createdAt: DateTime.parse('2025-10-01T14:15:00Z'),
      ),
      Transaction(
        id: 'txn_004',
        title: 'Netflix Subscription',
        amount: 800.00,
        type: TransactionType.expense,
        categoryId: 'cat_004',
        categoryName: 'Entertainment',
        date: DateTime.parse('2025-09-30T08:00:00Z'),
        notes: 'Monthly subscription',
        createdAt: DateTime.parse('2025-09-30T08:00:00Z'),
      ),
      Transaction(
        id: 'txn_005',
        title: 'Electricity Bill',
        amount: 3200.00,
        type: TransactionType.expense,
        categoryId: 'cat_005',
        categoryName: 'Bills & Utilities',
        date: DateTime.parse('2025-09-28T16:45:00Z'),
        notes: 'September electricity bill',
        createdAt: DateTime.parse('2025-09-28T16:45:00Z'),
      ),
      Transaction(
        id: 'txn_006',
        title: 'Online Shopping',
        amount: 4500.00,
        type: TransactionType.expense,
        categoryId: 'cat_003',
        categoryName: 'Shopping',
        date: DateTime.parse('2025-09-27T20:30:00Z'),
        notes: 'Clothing from Daraz',
        createdAt: DateTime.parse('2025-09-27T20:30:00Z'),
      ),
      Transaction(
        id: 'txn_007',
        title: 'Restaurant Dinner',
        amount: 1800.00,
        type: TransactionType.expense,
        categoryId: 'cat_001',
        categoryName: 'Food & Dining',
        date: DateTime.parse('2025-09-26T19:00:00Z'),
        notes: 'Dinner at The Kabab Factory',
        createdAt: DateTime.parse('2025-09-26T19:00:00Z'),
      ),
      Transaction(
        id: 'txn_008',
        title: 'Freelance Project',
        amount: 15000.00,
        type: TransactionType.income,
        categoryId: 'cat_freelance',
        categoryName: 'Freelance',
        date: DateTime.parse('2025-09-25T12:00:00Z'),
        notes: 'Payment for mobile app project',
        createdAt: DateTime.parse('2025-09-25T12:00:00Z'),
      ),
      Transaction(
        id: 'txn_009',
        title: 'Internet Bill',
        amount: 1500.00,
        type: TransactionType.expense,
        categoryId: 'cat_005',
        categoryName: 'Bills & Utilities',
        date: DateTime.parse('2025-09-24T11:00:00Z'),
        notes: 'Monthly broadband bill',
        createdAt: DateTime.parse('2025-09-24T11:00:00Z'),
      ),
      Transaction(
        id: 'txn_010',
        title: 'Coffee Shop',
        amount: 450.00,
        type: TransactionType.expense,
        categoryId: 'cat_001',
        categoryName: 'Food & Dining',
        date: DateTime.parse('2025-09-23T09:30:00Z'),
        notes: 'Morning coffee at Barista',
        createdAt: DateTime.parse('2025-09-23T09:30:00Z'),
      ),
    ];
  }

  List<CategoryExpense> _generateCategoryExpenses() {
    return [
      const CategoryExpense(
        categoryId: 'cat_001',
        categoryName: 'Food & Dining',
        amount: 4750.00, // Grocery (2500) + Restaurant (1800) + Coffee (450)
        percentage: 32.5,
        transactionCount: 3,
      ),
      const CategoryExpense(
        categoryId: 'cat_005',
        categoryName: 'Bills & Utilities',
        amount: 4700.00, // Electricity (3200) + Internet (1500)
        percentage: 32.2,
        transactionCount: 2,
      ),
      const CategoryExpense(
        categoryId: 'cat_003',
        categoryName: 'Shopping',
        amount: 4500.00, // Online Shopping
        percentage: 30.8,
        transactionCount: 1,
      ),
      const CategoryExpense(
        categoryId: 'cat_004',
        categoryName: 'Entertainment',
        amount: 800.00, // Netflix Subscription
        percentage: 5.5,
        transactionCount: 1,
      ),
      const CategoryExpense(
        categoryId: 'cat_002',
        categoryName: 'Transportation',
        amount: 350.00, // Uber Ride
        percentage: 2.4,
        transactionCount: 1,
      ),
    ];
  }
}
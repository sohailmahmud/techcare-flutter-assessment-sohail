import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/mock_api_service.dart';

/// Dashboard repository implementation using enhanced MockApiService
class DashboardRepositoryImpl implements DashboardRepository {
  final MockApiService apiService;

  DashboardRepositoryImpl({
    required this.apiService,
  });

  @override
  Future<Either<Failure, DashboardSummary>> getDashboardSummary() async {
    try {
      await apiService.initialize();
      final response = await apiService.getDashboardSummary();
      final responseData = response.data as Map<String, dynamic>;
      
      if (responseData['success'] == true) {
        final data = responseData['data'] as Map<String, dynamic>;
        final summary = _mapToDashboardSummary(data);
        return Right(summary);
      } else {
        return const Left(ServerFailure('Dashboard API returned error'));
      }
    } catch (e) {
      return Left(NetworkFailure('Failed to get dashboard summary: $e'));
    }
  }

  @override
  Future<Either<Failure, DashboardSummary>> refreshDashboard() async {
    // For refresh, we simply call getDashboardSummary again
    // The API service handles fresh data fetching
    return getDashboardSummary();
  }

  /// Map API response data to DashboardSummary entity
  DashboardSummary _mapToDashboardSummary(Map<String, dynamic> data) {
    final summaryData = data['summary'] as Map<String, dynamic>;
    final categoryExpensesData = data['categoryExpenses'] as List<dynamic>;
    final recentTransactionsData = data['recentTransactions'] as List<dynamic>;

    // Map category expenses
    final categoryExpenses = categoryExpensesData.map((item) {
      final category = item as Map<String, dynamic>;
      return CategoryExpense(
        categoryId: category['categoryId'] ?? '',
        categoryName: category['categoryName'] ?? '',
        amount: (category['amount'] as num?)?.toDouble() ?? 0.0,
        percentage: (category['percentage'] as num?)?.toDouble() ?? 0.0,
        transactionCount: category['transactionCount'] as int? ?? 0,
      );
    }).toList();

    // Map recent transactions
    final recentTransactions = recentTransactionsData.map((item) {
      final transaction = item as Map<String, dynamic>;
      final categoryData = transaction['category'] as Map<String, dynamic>;
      
      return Transaction(
        id: transaction['id'] ?? '',
        title: transaction['title'] ?? '',
        amount: (transaction['amount'] as num?)?.toDouble() ?? 0.0,
        type: _parseTransactionType(transaction['type'] as String?),
        category: Category(
          id: categoryData['id'] ?? '',
          name: categoryData['name'] ?? '',
          icon: categoryData['icon'] ?? '',
          color: categoryData['color'] ?? '',
          budget: (categoryData['budget'] as num?)?.toDouble(),
        ),
        date: DateTime.tryParse(transaction['date'] ?? '') ?? DateTime.now(),
        description: transaction['description'] as String?,
      );
    }).toList();

    return DashboardSummary(
      totalBalance: (summaryData['totalBalance'] as num?)?.toDouble() ?? 0.0,
      monthlyIncome: (summaryData['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
      monthlyExpense: (summaryData['monthlyExpense'] as num?)?.toDouble() ?? 0.0,
      categoryExpenses: categoryExpenses,
      recentTransactions: recentTransactions,
      lastUpdated: DateTime.now(),
    );
  }

  /// Parse transaction type string to enum
  TransactionType _parseTransactionType(String? type) {
    switch (type?.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      default:
        return TransactionType.expense;
    }
  }
}
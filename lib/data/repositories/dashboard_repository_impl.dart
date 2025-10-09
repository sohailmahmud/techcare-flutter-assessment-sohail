import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
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
      print('🔄 DashboardRepo: Initializing API service');
      await apiService.initialize();
      
      print('🔄 DashboardRepo: Calling API service getDashboardSummary');
      final response = await apiService.getDashboardSummary();
      final responseData = response.data as Map<String, dynamic>;
      
      print('🔄 DashboardRepo: Got response: ${responseData.keys}');
      
      if (responseData['success'] == true) {
        final data = responseData['data'] as Map<String, dynamic>;
        print('✅ DashboardRepo: Response data keys: ${data.keys}');
        final summary = _mapToDashboardSummary(data);
        print('✅ DashboardRepo: Successfully mapped to DashboardSummary');
        return Right(summary);
      } else {
        print('❌ DashboardRepo: API returned success=false');
        return const Left(ServerFailure('Dashboard API returned error'));
      }
    } catch (e, stackTrace) {
      print('💥 DashboardRepo: Error occurred: $e');
      print('💥 StackTrace: $stackTrace');
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
          icon: _parseIconData(categoryData['icon'] as String?),
          color: _parseColor(categoryData['color'] as String?),
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

  /// Parse icon string to IconData
  IconData _parseIconData(String? iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'movie':
        return Icons.movie;
      case 'receipt':
        return Icons.receipt;
      case 'payments':
        return Icons.payments;
      case 'work':
        return Icons.work;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'school':
        return Icons.school;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.category; // Default fallback icon
    }
  }

  /// Parse color string to Color
  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return Colors.grey; // Default fallback color
    }
    
    try {
      // Remove # if present
      String hex = colorHex.replaceAll('#', '');
      
      // Add alpha channel if not present (6 digits -> 8 digits)
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      print('Failed to parse color: $colorHex, using default grey');
      return Colors.grey;
    }
  }
}
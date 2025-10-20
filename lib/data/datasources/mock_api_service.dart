import 'dart:math' as math;
import 'package:dio/dio.dart';
import '../../core/utils/logger.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/analytics_model.dart';
import 'asset_data_source.dart';

/// Simple Mock API service that uses asset data
class MockApiService {
  final AssetDataSource _assetDataSource = AssetDataSource();
  final math.Random _random = math.Random();
  final double _failureChance; // failure probability (0.0 - 1.0)

  // In-memory storage for CRUD operations
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  AnalyticsDataModel? _analytics;

  bool _isInitialized = false;
  // Optional forced error for the next API call (test-only)
  DioException? _forcedNextError;

  /// Test-only: force the next API call to throw [error]. Pass null to clear.
  void setNextError(DioException? error) {
    _forcedNextError = error;
  }

  /// Create the MockApiService
  MockApiService({double failureChance = 0.10}) : _failureChance = failureChance;

  /// Initialize service with JSON data loading
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.d('MockApiService: Starting initialization');
      // Load data from assets
      final transactionsResponse = await _assetDataSource.getTransactions();
      final categoriesResponse = await _assetDataSource.getCategories();
      final analyticsResponse = await _assetDataSource.getAnalytics();

      _transactions = transactionsResponse.data;
      _categories = categoriesResponse.categories;
      _analytics = analyticsResponse.analytics;

      _isInitialized = true;
      Logger.i(
          'MockApiService initialized with ${_transactions.length} transactions and ${_categories.length} categories');
    } catch (e) {
      Logger.e('Failed to initialize MockApiService', error: e);
      rethrow;
    }
  }

  /// Simulate network delay
  Future<void> _simulateDelay() async {
    // Delay between 500ms and 1000ms (inclusive) to simulate API latency
    final delay = 500 + _random.nextInt(501); // 500..1000 ms
    await Future.delayed(Duration(milliseconds: delay));
  }

  /// Simulate network error (disabled for debugging)
  void _simulateNetworkError() {
    // If a forced error was provided (from tests), throw it and clear the
    // forced error so subsequent calls behave normally.
    if (_forcedNextError != null) {
      final err = _forcedNextError!;
      _forcedNextError = null;
      throw err;
    }
    // Inject a random failure to help test error handling in the app.
    // This uses a 1-in-N integer sampling derived from _failureChance so that
    // when _failureChance == 0.1 the behavior is equivalent to
    // `Random().nextInt(10) == 0` (approx. 10% chance).
    if (_failureChance <= 0.0) return;

    if (_failureChance >= 1.0) {
      // Always fail - throw one of the simulated errors
    } else {
      // Derive an integer denominator from the failure chance. For common
      // fractions like 0.10 this will produce denom=10 and simulate
      // `nextInt(10) == 0`.
      final denom = (_failureChance > 0) ? (1 / _failureChance).round() : 0;
      if (denom <= 1) {
        // denom <= 1 means always fail
      } else {
        final shouldFail = _random.nextInt(denom) == 0;
        if (!shouldFail) return;
      }
    }

    Logger.w('MockApiService: Simulating network error (failureChance=$_failureChance)');

    // Choose an error class to simulate (same weighted distribution as before)
    final choice = _random.nextDouble();
    if (choice < 0.25) {
      // Simulate a connection error (no internet)
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
        message: 'Simulated connection error (no internet)',
      );
    } else if (choice < 0.50) {
      // Simulate a timeout
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.receiveTimeout,
        message: 'Simulated timeout',
      );
    } else if (choice < 0.70) {
      // Simulate a 500 server error
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(path: ''), statusCode: 500, data: {'message': 'Simulated server error'}),
        message: 'Simulated server error',
      );
    } else if (choice < 0.85) {
      // Simulate a 400 validation error
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(path: ''), statusCode: 400, data: {'message': 'Simulated validation error'}),
        message: 'Simulated validation error',
      );
    } else if (choice < 0.95) {
      // Simulate authentication error
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(path: ''), statusCode: 401, data: {'message': 'Simulated unauthorized'}),
        message: 'Simulated unauthorized',
      );
    } else {
      // Unknown / network hiccup
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.unknown,
        message: 'Simulated unknown network error',
      );
    }
  }

  /// Get transactions with pagination and filtering
  Future<Response<Map<String, dynamic>>> getTransactions({
    int page = 1,
    int limit = 20,
  List<String>? categories,
  String? type,
  String? search,
  dynamic cancelToken,
  String? startDate,
  String? endDate,
  Map<String, dynamic>? amountRange,
  }) async {
    await initialize();
    await _simulateDelay();
    _simulateNetworkError();

    List<TransactionModel> filteredTransactions = List.from(_transactions);

    // Category filter (single or multiple)
    if (categories != null && categories.isNotEmpty) {
      filteredTransactions = filteredTransactions.where((t) => categories.contains(t.category.id)).toList();
    }

    if (type != null && type.isNotEmpty) {
      filteredTransactions =
          filteredTransactions.where((t) => t.typeString == type).toList();
    }

    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      double? searchAmount;
      try {
        searchAmount = double.parse(search);
      } catch (_) {
        searchAmount = null;
      }
      filteredTransactions = filteredTransactions.where((t) {
        final matchesText = t.title.toLowerCase().contains(searchLower) ||
            (t.description?.toLowerCase().contains(searchLower) ?? false) ||
            t.category.name.toLowerCase().contains(searchLower);
        final matchesAmount = searchAmount != null && t.amount.abs() == searchAmount;
        // Also allow partial match for amount as string
        final matchesAmountString = t.amount.toString().contains(searchLower);
        return matchesText || matchesAmount || matchesAmountString;
      }).toList();
    }

    // Amount range filter
    if (amountRange != null) {
      final min = (amountRange['min'] ?? 0.0) as double;
      final max = (amountRange['max'] ?? double.infinity) as double;
      filteredTransactions = filteredTransactions.where((t) {
        final absAmount = t.amount.abs();
        return absAmount >= min && absAmount <= max;
      }).toList();
    }

    // Date filter
    if (startDate != null && endDate != null) {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      filteredTransactions = filteredTransactions.where((t) {
        return !t.date.isBefore(start) && !t.date.isAfter(end);
      }).toList();
    }

    // Sort by date (newest first)
    filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

    // Pagination
    final totalItems = filteredTransactions.length;
    final totalPages = (totalItems / limit).ceil();
    final startIndex = (page - 1) * limit;
    final endIndex = math.min(startIndex + limit, totalItems);

    final paginatedTransactions = startIndex < filteredTransactions.length
        ? filteredTransactions.sublist(startIndex, endIndex)
        : <TransactionModel>[];

    final response = {
      'success': true,
      'data': paginatedTransactions.map((t) => t.toJson()).toList(),
      'meta': {
        'currentPage': page,
        'totalPages': totalPages,
        'totalItems': totalItems,
        'itemsPerPage': limit,
        'hasMore': page < totalPages,
      }
    };

    return Response<Map<String, dynamic>>(
      data: response,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/api/transactions'),
    );
  }

  /// Get categories
  Future<Response<Map<String, dynamic>>> getCategories() async {
    await initialize();
    await _simulateDelay();
    _simulateNetworkError();

    final response = {
      'success': true,
      'data': _categories.map((c) => c.toJson()).toList(),
    };

    return Response<Map<String, dynamic>>(
      data: response,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/api/categories'),
    );
  }

  /// Get analytics
  Future<Response<Map<String, dynamic>>> getAnalytics({
    dynamic cancelToken,
  }) async {
    await initialize();
    await _simulateDelay();
    _simulateNetworkError();

    if (_analytics == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/analytics'),
        type: DioExceptionType.unknown,
        message: 'Analytics data not available',
      );
    }

    final response = {
      'success': true,
      'data': _analytics!.toJson(),
    };

    return Response<Map<String, dynamic>>(
      data: response,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/api/analytics'),
    );
  }

  /// Create transaction
  Future<Response<Map<String, dynamic>>> createTransaction(
    TransactionModel transaction, {dynamic cancelToken}) async {
    await initialize();
    await _simulateDelay();
    _simulateNetworkError();

    // Generate new ID
    final newId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
    // Create new transaction with generated ID
    final transactionWithId = TransactionModel(
      id: newId,
      title: transaction.title,
      amount: transaction.amount,
      typeString: transaction.typeString,
      category: transaction.category,
      date: transaction.date,
      description: transaction.description,
    );

    _transactions.insert(0, transactionWithId); // Add to beginning

    final response = {
      'success': true,
      'data': transactionWithId.toJson(),
      'message': 'Transaction created successfully',
    };

    return Response<Map<String, dynamic>>(
      data: response,
      statusCode: 201,
      requestOptions: RequestOptions(path: '/api/transactions'),
    );
  }

  /// Update transaction
  Future<Response<Map<String, dynamic>>> updateTransaction(
    String id, TransactionModel transaction,
    {dynamic cancelToken}) async {
    await initialize();
    await _simulateDelay();
    _simulateNetworkError();

    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/transactions/$id'),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: '/api/transactions/$id'),
        ),
        message: 'Transaction not found',
      );
    }

    final updatedTransaction = TransactionModel(
      id: id,
      title: transaction.title,
      amount: transaction.amount,
      typeString: transaction.typeString,
      category: transaction.category,
      date: transaction.date,
      description: transaction.description,
    );

    _transactions[index] = updatedTransaction;

    final response = {
      'success': true,
      'data': updatedTransaction.toJson(),
      'message': 'Transaction updated successfully',
    };

    return Response<Map<String, dynamic>>(
      data: response,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/api/transactions/$id'),
    );
  }

  /// Delete transaction
  Future<Response<Map<String, dynamic>>> deleteTransaction(String id,
      {dynamic cancelToken}) async {
    await initialize();
    await _simulateDelay();
    _simulateNetworkError();

    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/transactions/$id'),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: '/api/transactions/$id'),
        ),
        message: 'Transaction not found',
      );
    }

    _transactions.removeAt(index);

    final response = {
      'success': true,
      'message': 'Transaction deleted successfully',
    };

    return Response<Map<String, dynamic>>(
      data: response,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/api/transactions/$id'),
    );
  }

  /// Get single transaction
  Future<Response<Map<String, dynamic>>> getTransaction(String id,
      {dynamic cancelToken}) async {
    await initialize();
    await _simulateDelay();
    _simulateNetworkError();

    final transaction = _transactions.firstWhere(
      (t) => t.id == id,
      orElse: () => throw DioException(
        requestOptions: RequestOptions(path: '/api/transactions/$id'),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: '/api/transactions/$id'),
        ),
        message: 'Transaction not found',
      ),
    );

    final response = {
      'success': true,
      'data': transaction.toJson(),
    };

    return Response<Map<String, dynamic>>(
      data: response,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/api/transactions/$id'),
    );
  }

  /// Create category
  Future<Response<Map<String, dynamic>>> createCategory(
      CategoryModel category) async {
    await initialize();
    await _simulateDelay();
    _simulateNetworkError();

    // Generate new ID
    final newId = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    final newCategory = CategoryModel(
      id: newId,
      name: category.name,
      icon: category.icon,
      color: category.color,
      budget: category.budget,
    );

    _categories.add(newCategory);

    final response = {
      'success': true,
      'data': newCategory.toJson(),
    };

    return Response<Map<String, dynamic>>(
      data: response,
      statusCode: 201,
      requestOptions: RequestOptions(path: '/api/categories'),
    );
  }

  /// Update category
  Future<Response<Map<String, dynamic>>> updateCategory(
      String id, CategoryModel category) async {
    await initialize();
    await _simulateDelay();
    _simulateNetworkError();

    final index = _categories.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/categories/$id'),
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: '/api/categories/$id'),
        ),
        type: DioExceptionType.badResponse,
        message: 'Category not found',
      );
    }

    final updatedCategory = CategoryModel(
      id: id,
      name: category.name,
      icon: category.icon,
      color: category.color,
      budget: category.budget,
    );

    _categories[index] = updatedCategory;

    final response = {
      'success': true,
      'data': updatedCategory.toJson(),
    };

    return Response<Map<String, dynamic>>(
      data: response,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/api/categories/$id'),
    );
  }

  /// Delete category
  Future<Response<Map<String, dynamic>>> deleteCategory(String id) async {
    await initialize();
    await _simulateDelay();
    _simulateNetworkError();

    final index = _categories.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/categories/$id'),
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: '/api/categories/$id'),
        ),
        type: DioExceptionType.badResponse,
        message: 'Category not found',
      );
    }

    _categories.removeAt(index);

    final response = {
      'success': true,
      'message': 'Category deleted successfully',
    };

    return Response<Map<String, dynamic>>(
      data: response,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/api/categories/$id'),
    );
  }

  /// Get dashboard summary data
  Future<Response<Map<String, dynamic>>> getDashboardSummary() async {
    try {
      Logger.d('MockApiService: Starting getDashboardSummary');
      await initialize();
      await _simulateDelay();
      _simulateNetworkError();

      Logger.d(
          'MockApiService: Processing ${_transactions.length} transactions');

      // If no transactions loaded, return empty but valid response
      if (_transactions.isEmpty) {
        Logger.w(
            'MockApiService: No transactions found, returning empty response');
        final response = {
          'success': true,
          'data': {
            'summary': {
              'totalBalance': 0.0,
              'monthlyIncome': 0.0,
              'monthlyExpense': 0.0,
            },
            'categoryExpenses': <Map<String, dynamic>>[],
            'recentTransactions': <Map<String, dynamic>>[],
          }
        };
        return Response<Map<String, dynamic>>(
          data: response,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/dashboard/summary'),
        );
      }

      // Calculate summary from current transactions
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      final currentMonthTransactions = _transactions.where((t) {
        final transactionDate = t.date;
        return transactionDate
            .isAfter(currentMonth.subtract(const Duration(days: 1)));
      }).toList();

      Logger.d(
          'MockApiService: Found ${currentMonthTransactions.length} transactions for current month');

      final totalIncome = currentMonthTransactions
          .where((t) => t.typeString == 'income')
          .fold<double>(0.0, (sum, t) => sum + t.amount);

      final totalExpenses = currentMonthTransactions
          .where((t) => t.typeString == 'expense')
          .fold<double>(0.0, (sum, t) => sum + t.amount);

      Logger.d(
          'MockApiService: Total income: $totalIncome, Total expenses: $totalExpenses');

      // Calculate category expenses
      final categoryExpenseMap = <String, Map<String, dynamic>>{};
      final expenseTransactions = currentMonthTransactions
          .where((t) => t.typeString == 'expense')
          .toList();

      for (final transaction in expenseTransactions) {
        final categoryId = transaction.category.id;
        if (categoryExpenseMap.containsKey(categoryId)) {
          categoryExpenseMap[categoryId]!['amount'] += transaction.amount;
          categoryExpenseMap[categoryId]!['transactionCount']++;
        } else {
          categoryExpenseMap[categoryId] = {
            'categoryId': categoryId,
            'categoryName': transaction.category.name,
            'amount': transaction.amount,
            'transactionCount': 1,
          };
        }
      }

      // Calculate percentages and create category expenses list
      final categoryExpenses = categoryExpenseMap.values.map((category) {
        final amount = category['amount'] as double;
        final percentage =
            totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0.0;
        return {
          'categoryId': category['categoryId'],
          'categoryName': category['categoryName'],
          'amount': amount,
          'percentage': percentage,
          'transactionCount': category['transactionCount'],
        };
      }).toList();

      // Get recent transactions (limit to 10) - sorted by date descending (newest first)
      final sortedTransactions = List<TransactionModel>.from(_transactions);
      sortedTransactions.sort((a, b) => b.date.compareTo(a.date));

      final recentTransactions = sortedTransactions
          .take(10)
          .map((t) => {
                'id': t.id,
                'title': t.title,
                'amount': t.amount,
                'type': t.typeString,
                'category': {
                  'id': t.category.id,
                  'name': t.category.name,
                  'icon': t.category.icon,
                  'color': t.category.color,
                  'budget': t.category.budget,
                },
                'date': t.date.toIso8601String(),
                'description': t.description,
              })
          .toList();

      final response = {
        'success': true,
        'data': {
          'summary': {
            'totalBalance': totalIncome - totalExpenses,
            'monthlyIncome': totalIncome,
            'monthlyExpense': totalExpenses,
          },
          'categoryExpenses': categoryExpenses,
          'recentTransactions': recentTransactions,
        }
      };

      Logger.i(
          'MockApiService: Returning dashboard summary with ${categoryExpenses.length} categories and ${recentTransactions.length} recent transactions');

      return Response<Map<String, dynamic>>(
        data: response,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/dashboard/summary'),
      );
    } catch (e, stackTrace) {
      Logger.e('MockApiService: Error in getDashboardSummary',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

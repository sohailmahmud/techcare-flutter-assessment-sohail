import 'dart:math' as math;
import 'package:dio/dio.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/analytics_model.dart';
import 'asset_data_source.dart';

/// Simple Mock API service that uses asset data
class MockApiService {
  final AssetDataSource _assetDataSource = AssetDataSource();
  final math.Random _random = math.Random();
  
  // In-memory storage for CRUD operations
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  AnalyticsDataModel? _analytics;
  
  bool _isInitialized = false;

  /// Initialize service with JSON data loading
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load data from assets
      final transactionsResponse = await _assetDataSource.getTransactions();
      final categoriesResponse = await _assetDataSource.getCategories();
      final analyticsResponse = await _assetDataSource.getAnalytics();
      
      _transactions = transactionsResponse.data;
      _categories = categoriesResponse.categories;
      _analytics = analyticsResponse.analytics;
      
      _isInitialized = true;
      print('MockApiService initialized with ${_transactions.length} transactions and ${_categories.length} categories');
    } catch (e) {
      print('Failed to initialize MockApiService: $e');
      rethrow;
    }
  }

  /// Simulate network delay
  Future<void> _simulateDelay() async {
    final delay = 300 + _random.nextInt(700); // 300-1000ms delay
    await Future.delayed(Duration(milliseconds: delay));
  }

  /// Simulate network error (10% chance)
  void _simulateNetworkError() {
    if (_random.nextInt(10) == 0) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        type: DioExceptionType.connectionTimeout,
        message: 'Simulated network error',
      );
    }
  }

  /// Get transactions with pagination and filtering
  Future<Response<Map<String, dynamic>>> getTransactions({
    int page = 1,
    int limit = 20,
    String? category,
    String? type,
    String? search,
  }) async {
    await initialize();
    await _simulateDelay();
    _simulateNetworkError();

    List<TransactionModel> filteredTransactions = List.from(_transactions);

    // Apply filters
    if (category != null && category.isNotEmpty) {
      filteredTransactions = filteredTransactions
          .where((t) => t.category.id == category)
          .toList();
    }

    if (type != null && type.isNotEmpty) {
      filteredTransactions = filteredTransactions
          .where((t) => t.typeString == type)
          .toList();
    }

    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      filteredTransactions = filteredTransactions
          .where((t) => 
              t.title.toLowerCase().contains(searchLower) ||
              (t.description?.toLowerCase().contains(searchLower) ?? false) ||
              t.category.name.toLowerCase().contains(searchLower))
          .toList();
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
  Future<Response<Map<String, dynamic>>> getAnalytics() async {
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
  Future<Response<Map<String, dynamic>>> createTransaction(TransactionModel transaction) async {
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
  Future<Response<Map<String, dynamic>>> updateTransaction(String id, TransactionModel transaction) async {
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
  Future<Response<Map<String, dynamic>>> deleteTransaction(String id) async {
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
  Future<Response<Map<String, dynamic>>> getTransaction(String id) async {
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
  Future<Response<Map<String, dynamic>>> createCategory(CategoryModel category) async {
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
  Future<Response<Map<String, dynamic>>> updateCategory(String id, CategoryModel category) async {
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
    await initialize();
    await _simulateDelay();
    _simulateNetworkError();

    // Calculate summary from current transactions
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final currentMonthTransactions = _transactions.where((t) {
      final transactionDate = t.date;
      return transactionDate.isAfter(currentMonth.subtract(const Duration(days: 1)));
    }).toList();

    final totalIncome = currentMonthTransactions
        .where((t) => t.typeString == 'income')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    
    final totalExpenses = currentMonthTransactions
        .where((t) => t.typeString == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final response = {
      'data': {
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netBalance': totalIncome - totalExpenses,
        'totalTransactions': currentMonthTransactions.length,
        'savingsRate': totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0.0,
        'lastUpdated': DateTime.now().toIso8601String(),
      }
    };

    return Response<Map<String, dynamic>>(
      data: response,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/api/dashboard/summary'),
    );
  }
}
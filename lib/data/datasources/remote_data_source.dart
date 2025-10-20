import 'package:dio/dio.dart';
import '../../core/errors/exceptions.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/analytics_model.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';

import '../../domain/repositories/transaction_repository.dart';
import 'mock_api_service.dart';

/// Paginated response for transactions
class PaginatedTransactionsResponse {
  final List<TransactionModel> data;
  final PaginationMeta meta;

  const PaginatedTransactionsResponse({
    required this.data,
    required this.meta,
  });

  factory PaginatedTransactionsResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedTransactionsResponse(
      data: (json['data'] as List)
          .map((item) => TransactionModel.fromJson(item))
          .toList(),
      meta: PaginationMeta.fromJson(json['meta']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }

  PaginatedResponse<Transaction> toEntity() {
    return PaginatedResponse<Transaction>(
      data:
          data.map((transactionModel) => transactionModel.toEntity()).toList(),
      meta: meta,
    );
  }
}

abstract class RemoteDataSource {
  Future<PaginatedResponse<Transaction>> getTransactions({
    int page = 1,
    int limit = 10,
    List<String>? categories,
    String? type,
    String? startDate,
    String? endDate,
    Map<String, dynamic>? amountRange,
    String? search,
    // Optional Dio CancelToken to allow request cancellation
    dynamic cancelToken,
  });

  Future<Transaction> createTransaction(Transaction transaction);
  Future<Transaction> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);

  Future<List<Category>> getCategories();
  Future<Category> createCategory(Category category);
  Future<Category> updateCategory(Category category);
  Future<void> deleteCategory(String id);

  Future<AnalyticsDataModel> getAnalyticsSummary({
    String? startDate,
    String? endDate,
  });
}

class RemoteDataSourceImpl implements RemoteDataSource {
  final MockApiService _apiService;

  RemoteDataSourceImpl(this._apiService);

  Future<T> _withApiCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      // Map DioException to domain exceptions
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw const NetworkException('Connection timeout');
        case DioExceptionType.connectionError:
          throw const NetworkException('No internet connection');
        case DioExceptionType.cancel:
          throw const NetworkException('Request cancelled');
        case DioExceptionType.badResponse:
          final status = e.response?.statusCode ?? 0;
          if (status >= 500) {
            throw const ServerException('Server error occurred');
          }
          if (status == 401 || status == 403) {
            throw const AuthenticationException('Unauthorized');
          }
          if (status >= 400 && status < 500) {
            // Try to extract message
            final msg = e.response?.data is Map ? (e.response!.data['message']?.toString() ?? 'Validation error') : 'Validation error';
            throw ValidationException(msg);
          }
          throw NetworkException(e.message ?? 'Network error');
        case DioExceptionType.unknown:
        default:
          throw NetworkException(e.message ?? 'Unknown network error');
      }
    }
  }

  @override
  Future<PaginatedResponse<Transaction>> getTransactions({
    int page = 1,
    int limit = 10,
    List<String>? categories,
    String? type,
    String? startDate,
    String? endDate,
    Map<String, dynamic>? amountRange,
    String? search,
    dynamic cancelToken,
  }) async {
    final response = await _apiService.getTransactions(
      page: page,
      limit: limit,
      categories: categories,
      type: type,
      startDate: startDate,
      endDate: endDate,
      amountRange: amountRange,
      search: search,
      cancelToken: cancelToken,
    );

  final paginatedResponse =
    PaginatedTransactionsResponse.fromJson(response.data!);
    return paginatedResponse.toEntity();
  }

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    final transactionModel = TransactionModel.fromEntity(transaction);

    final response = await _withApiCall(() => _apiService.createTransaction(transactionModel));
    final createdModel = TransactionModel.fromJson(response.data!['data']);
    return createdModel.toEntity();
  }

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    final transactionModel = TransactionModel.fromEntity(transaction);

  final response = await _withApiCall(() => _apiService.updateTransaction(transaction.id, transactionModel));
    final updatedModel = TransactionModel.fromJson(response.data!['data']);
    return updatedModel.toEntity();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _withApiCall(() => _apiService.deleteTransaction(id));
  }

  @override
  Future<List<Category>> getCategories() async {
  final response = await _withApiCall(() => _apiService.getCategories());
    final categoriesResponse = CategoriesResponse.fromJson(response.data!);
    return categoriesResponse.categories
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<Category> createCategory(Category category) async {
    final categoryModel = CategoryModel.fromEntity(category);
    final response = await _withApiCall(() => _apiService.createCategory(categoryModel));
    final createdModel = CategoryModel.fromJson(response.data!);
    return createdModel.toEntity();
  }

  @override
  Future<Category> updateCategory(Category category) async {
    final categoryModel = CategoryModel.fromEntity(category);
  final response = await _withApiCall(() => _apiService.updateCategory(category.id, categoryModel));
    final updatedModel = CategoryModel.fromJson(response.data!);
    return updatedModel.toEntity();
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _withApiCall(() => _apiService.deleteCategory(id));
  }

  @override
  Future<AnalyticsDataModel> getAnalyticsSummary({
    String? startDate,
    String? endDate,
  }) async {
    final response = await _withApiCall(() => _apiService.getAnalytics());
    final analyticsModel = AnalyticsDataModel.fromJson(response.data!);

    return analyticsModel;
  }
}

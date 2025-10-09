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
    String? categoryId,
    String? type,
    String? startDate,
    String? endDate,
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

  @override
  Future<PaginatedResponse<Transaction>> getTransactions({
    int page = 1,
    int limit = 10,
    String? categoryId,
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _apiService.getTransactions(
      page: page,
      limit: limit,
      category: categoryId,
      type: type,
    );

    final paginatedResponse =
        PaginatedTransactionsResponse.fromJson(response.data!);
    return paginatedResponse.toEntity();
  }

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    final transactionModel = TransactionModel.fromEntity(transaction);

    final response = await _apiService.createTransaction(transactionModel);
    final createdModel = TransactionModel.fromJson(response.data!);
    return createdModel.toEntity();
  }

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    final transactionModel = TransactionModel.fromEntity(transaction);

    final response =
        await _apiService.updateTransaction(transaction.id, transactionModel);
    final updatedModel = TransactionModel.fromJson(response.data!);
    return updatedModel.toEntity();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _apiService.deleteTransaction(id);
  }

  @override
  Future<List<Category>> getCategories() async {
    final response = await _apiService.getCategories();
    final categoriesResponse = CategoriesResponse.fromJson(response.data!);
    return categoriesResponse.categories
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<Category> createCategory(Category category) async {
    final categoryModel = CategoryModel.fromEntity(category);
    final response = await _apiService.createCategory(categoryModel);
    final createdModel = CategoryModel.fromJson(response.data!);
    return createdModel.toEntity();
  }

  @override
  Future<Category> updateCategory(Category category) async {
    final categoryModel = CategoryModel.fromEntity(category);
    final response =
        await _apiService.updateCategory(category.id, categoryModel);
    final updatedModel = CategoryModel.fromJson(response.data!);
    return updatedModel.toEntity();
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _apiService.deleteCategory(id);
  }

  @override
  Future<AnalyticsDataModel> getAnalyticsSummary({
    String? startDate,
    String? endDate,
  }) async {
    final response = await _apiService.getAnalytics();
    final analyticsModel = AnalyticsDataModel.fromJson(response.data!);

    return analyticsModel;
  }
}

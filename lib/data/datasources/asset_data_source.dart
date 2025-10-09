import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/utils/logger.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/analytics_model.dart';
import 'remote_data_source.dart';

class AssetDataSource {
  static const String _transactionsPath = 'assets/mock_data/transactions.json';
  static const String _categoriesPath = 'assets/mock_data/categories.json';
  static const String _analyticsPath = 'assets/mock_data/analytics.json';

  Future<PaginatedTransactionsResponse> getTransactions() async {
    try {
      Logger.d('AssetDataSource: Loading transactions from $_transactionsPath');
      final jsonString = await rootBundle.loadString(_transactionsPath);
      Logger.d('AssetDataSource: Loaded transactions JSON, length: ${jsonString.length}');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      Logger.d('AssetDataSource: Decoded JSON, keys: ${jsonData.keys}');
      final response = PaginatedTransactionsResponse.fromJson(jsonData);
      Logger.d('AssetDataSource: Created response with ${response.data.length} transactions');
      return response;
    } catch (e, stackTrace) {
      Logger.e('AssetDataSource: Failed to load transactions', error: e, stackTrace: stackTrace);
      throw Exception('Failed to load transactions: $e');
    }
  }

  Future<CategoriesResponse> getCategories() async {
    try {
      Logger.d('AssetDataSource: Loading categories from $_categoriesPath');
      final jsonString = await rootBundle.loadString(_categoriesPath);
      Logger.d('AssetDataSource: Loaded categories JSON, length: ${jsonString.length}');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      Logger.d('AssetDataSource: Decoded JSON, keys: ${jsonData.keys}');
      final response = CategoriesResponse.fromJson(jsonData);
      Logger.d('AssetDataSource: Created response with ${response.categories.length} categories');
      return response;
    } catch (e, stackTrace) {
      Logger.e('AssetDataSource: Failed to load categories', error: e, stackTrace: stackTrace);
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<AnalyticsResponse> getAnalytics() async {
    try {
      Logger.d('AssetDataSource: Loading analytics from $_analyticsPath');
      final jsonString = await rootBundle.loadString(_analyticsPath);
      Logger.d('AssetDataSource: Loaded analytics JSON, length: ${jsonString.length}');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      Logger.d('AssetDataSource: Decoded JSON, keys: ${jsonData.keys}');
      final response = AnalyticsResponse.fromJson(jsonData);
      Logger.d('AssetDataSource: Created analytics response');
      return response;
    } catch (e, stackTrace) {
      Logger.e('AssetDataSource: Failed to load analytics', error: e, stackTrace: stackTrace);
      throw Exception('Failed to load analytics: $e');
    }
  }

  // Save methods for CRUD operations (these will save to local storage)
  Future<void> saveTransaction(TransactionModel transaction) async {
    // In a real app, this would save to local storage/database
    // For now, we'll just simulate success
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    // In a real app, this would update in local storage/database
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> deleteTransaction(String transactionId) async {
    // In a real app, this would delete from local storage/database
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
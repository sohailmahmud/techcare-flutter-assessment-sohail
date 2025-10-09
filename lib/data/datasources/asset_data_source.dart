import 'dart:convert';
import 'package:flutter/services.dart';
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
      print('🔄 AssetDataSource: Loading transactions from $_transactionsPath');
      final jsonString = await rootBundle.loadString(_transactionsPath);
      print('✅ AssetDataSource: Loaded transactions JSON, length: ${jsonString.length}');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      print('✅ AssetDataSource: Decoded JSON, keys: ${jsonData.keys}');
      final response = PaginatedTransactionsResponse.fromJson(jsonData);
      print('✅ AssetDataSource: Created response with ${response.data.length} transactions');
      return response;
    } catch (e, stackTrace) {
      print('💥 AssetDataSource: Failed to load transactions: $e');
      print('💥 StackTrace: $stackTrace');
      throw Exception('Failed to load transactions: $e');
    }
  }

  Future<CategoriesResponse> getCategories() async {
    try {
      print('🔄 AssetDataSource: Loading categories from $_categoriesPath');
      final jsonString = await rootBundle.loadString(_categoriesPath);
      print('✅ AssetDataSource: Loaded categories JSON, length: ${jsonString.length}');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      print('✅ AssetDataSource: Decoded JSON, keys: ${jsonData.keys}');
      final response = CategoriesResponse.fromJson(jsonData);
      print('✅ AssetDataSource: Created response with ${response.categories.length} categories');
      return response;
    } catch (e, stackTrace) {
      print('💥 AssetDataSource: Failed to load categories: $e');
      print('💥 StackTrace: $stackTrace');
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<AnalyticsResponse> getAnalytics() async {
    try {
      print('🔄 AssetDataSource: Loading analytics from $_analyticsPath');
      final jsonString = await rootBundle.loadString(_analyticsPath);
      print('✅ AssetDataSource: Loaded analytics JSON, length: ${jsonString.length}');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      print('✅ AssetDataSource: Decoded JSON, keys: ${jsonData.keys}');
      final response = AnalyticsResponse.fromJson(jsonData);
      print('✅ AssetDataSource: Created analytics response');
      return response;
    } catch (e, stackTrace) {
      print('💥 AssetDataSource: Failed to load analytics: $e');  
      print('💥 StackTrace: $stackTrace');
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
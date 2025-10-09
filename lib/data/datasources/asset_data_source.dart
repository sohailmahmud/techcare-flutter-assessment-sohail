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
      final jsonString = await rootBundle.loadString(_transactionsPath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return PaginatedTransactionsResponse.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }

  Future<CategoriesResponse> getCategories() async {
    try {
      final jsonString = await rootBundle.loadString(_categoriesPath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return CategoriesResponse.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<AnalyticsResponse> getAnalytics() async {
    try {
      final jsonString = await rootBundle.loadString(_analyticsPath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return AnalyticsResponse.fromJson(jsonData);
    } catch (e) {
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
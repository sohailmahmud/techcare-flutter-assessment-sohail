import '../../data/datasources/asset_data_source.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Category entity representing transaction categories
class Category extends Equatable {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  // Removed isIncome, now determined by transaction type
  final double? budget;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.budget,
  });

  // Helper methods for API integration
  String get iconName => _getIconName(icon);
  String get colorHex => '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

  static String _getIconName(IconData icon) {
    // Map common icons to string names for API
    final iconMap = {
      Icons.restaurant: 'restaurant',
      Icons.directions_car: 'directions_car',
      Icons.shopping_bag: 'shopping_bag',
      Icons.movie: 'movie',
      Icons.receipt: 'receipt',
      Icons.fitness_center: 'fitness_center',
      Icons.school: 'school',
      Icons.payments: 'payments',
      Icons.work: 'work',
      Icons.trending_up: 'trending_up',
      Icons.category: 'category',
    };
    return iconMap[icon] ?? 'category';
  }

  static IconData _getIconFromName(String iconName) {
    // Map string names back to IconData
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
      case 'fitness_center':
        return Icons.fitness_center;
      case 'school':
        return Icons.school;
      case 'payments':
        return Icons.payments;
      case 'work':
        return Icons.work;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }

  static Color _getColorFromHex(String hexColor) {
    // Convert hex string to Color
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  factory Category.fromApiData({
    required String id,
    required String name,
    required String iconName,
    required String colorHex,
    double? budget,
  }) {
    return Category(
      id: id,
      name: name,
      icon: _getIconFromName(iconName),
      color: _getColorFromHex(colorHex),
      budget: budget,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, color, budget];
}

/// Predefined categories for the application
class AppCategories {
  /// Loads categories from local JSON asset using AssetDataSource
  static Future<List<Category>> loadFromJsonAsset() async {
    final assetDataSource = AssetDataSource();
    final response = await assetDataSource.getCategories();
    return response.categories.map((model) => model.toEntity()).toList();
  }
  /// Loads expense categories by grouping transaction categories from transactions.json
  static Future<List<Category>> expenseCategories() async {
    final assetDataSource = AssetDataSource();
    final transactionsResponse = await assetDataSource.getTransactions();
    final expenseCategories = <Category>{};
    for (final txn in transactionsResponse.data) {
      if (txn.typeString.toLowerCase() == 'expense') {
        final cat = txn.category;
        expenseCategories.add(Category(
          id: cat.id,
          name: cat.name,
          icon: Category._getIconFromName(cat.icon),
          color: Category._getColorFromHex(cat.color),
          budget: cat.budget,
        ));
      }
    }
    return expenseCategories.toList();
  }

  /// Loads income categories by grouping transaction categories from transactions.json
  static Future<List<Category>> incomeCategories() async {
    final assetDataSource = AssetDataSource();
    final transactionsResponse = await assetDataSource.getTransactions();
    final incomeCategories = <Category>{};
    for (final txn in transactionsResponse.data) {
      if (txn.typeString.toLowerCase() == 'income') {
        final cat = txn.category;
        incomeCategories.add(Category(
          id: cat.id,
          name: cat.name,
          icon: Category._getIconFromName(cat.icon),
          color: Category._getColorFromHex(cat.color),
          budget: cat.budget,
        ));
      }
    }
    return incomeCategories.toList();
  }

  static Future<List<Category>> getAllCategories() async {
    final expenses = await expenseCategories();
    final incomes = await incomeCategories();
    return [...expenses, ...incomes];
  }

  static Future<List<Category>> getCategoriesFor(bool isIncome) async {
    return isIncome ? await incomeCategories() : await expenseCategories();
  }

  static Future<Category?> findById(String id) async {
    final allCategories = await getAllCategories();
    return allCategories.firstWhere(
      (category) => category.id == id,
      orElse: () => const Category(
        id: 'unknown',
        name: 'Unknown',
        icon: Icons.help_outline,
        color: Colors.grey,
      ),
    );
  }
}
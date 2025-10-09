import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Category entity representing transaction categories
class Category extends Equatable {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isIncome;
  final double? budget;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isIncome = false,
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
      Icons.receipt: 'receipt',
      Icons.movie: 'movie',
      Icons.payments: 'payments',
      Icons.work: 'work',
      Icons.home: 'home',
      Icons.local_hospital: 'local_hospital',
      Icons.school: 'school',
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
      case 'receipt':
        return Icons.receipt;
      case 'movie':
        return Icons.movie;
      case 'payments':
        return Icons.payments;
      case 'work':
        return Icons.work;
      case 'home':
        return Icons.home;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
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
    bool isIncome = false,
    double? budget,
  }) {
    return Category(
      id: id,
      name: name,
      icon: _getIconFromName(iconName),
      color: _getColorFromHex(colorHex),
      isIncome: isIncome,
      budget: budget,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, color, isIncome, budget];
}

/// Predefined categories for the application
class AppCategories {
  // Expense Categories
  static const List<Category> expenseCategories = [
    Category(
      id: 'food',
      name: 'Food',
      icon: Icons.restaurant,
      color: Colors.orange,
    ),
    Category(
      id: 'transport',
      name: 'Transport',
      icon: Icons.directions_car,
      color: Colors.blue,
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: Colors.purple,
    ),
    Category(
      id: 'bills',
      name: 'Bills',
      icon: Icons.receipt_long,
      color: Colors.red,
    ),
    Category(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.movie,
      color: Colors.pink,
    ),
    Category(
      id: 'health',
      name: 'Health',
      icon: Icons.medical_services,
      color: Colors.green,
    ),
    Category(
      id: 'education',
      name: 'Education',
      icon: Icons.school,
      color: Colors.indigo,
    ),
    Category(
      id: 'utilities',
      name: 'Utilities',
      icon: Icons.electrical_services,
      color: Colors.amber,
    ),
    Category(
      id: 'insurance',
      name: 'Insurance',
      icon: Icons.security,
      color: Colors.teal,
    ),
    Category(
      id: 'other_expense',
      name: 'Other',
      icon: Icons.more_horiz,
      color: Colors.grey,
    ),
  ];

  // Income Categories
  static const List<Category> incomeCategories = [
    Category(
      id: 'salary',
      name: 'Salary',
      icon: Icons.work,
      color: Colors.green,
      isIncome: true,
    ),
    Category(
      id: 'freelance',
      name: 'Freelance',
      icon: Icons.laptop,
      color: Colors.lightGreen,
      isIncome: true,
    ),
    Category(
      id: 'business',
      name: 'Business',
      icon: Icons.business,
      color: Colors.teal,
      isIncome: true,
    ),
    Category(
      id: 'investment',
      name: 'Investment',
      icon: Icons.trending_up,
      color: Colors.cyan,
      isIncome: true,
    ),
    Category(
      id: 'gift',
      name: 'Gift',
      icon: Icons.card_giftcard,
      color: Colors.pink,
      isIncome: true,
    ),
    Category(
      id: 'bonus',
      name: 'Bonus',
      icon: Icons.stars,
      color: Colors.amber,
      isIncome: true,
    ),
    Category(
      id: 'other_income',
      name: 'Other',
      icon: Icons.more_horiz,
      color: Colors.grey,
      isIncome: true,
    ),
  ];

  static List<Category> getAllCategories() {
    return [...expenseCategories, ...incomeCategories];
  }

  static List<Category> getCategoriesFor(bool isIncome) {
    return isIncome ? incomeCategories : expenseCategories;
  }

  static Category? findById(String id) {
    return getAllCategories().firstWhere(
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
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Category entity representing transaction categories
class Category extends Equatable {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isIncome;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isIncome = false,
  });

  @override
  List<Object?> get props => [id, name, icon, color, isIncome];
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
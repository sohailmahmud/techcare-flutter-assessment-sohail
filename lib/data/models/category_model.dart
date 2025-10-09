import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';

part 'category_model.g.dart';

@JsonSerializable()
class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final double? budget;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.budget,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => 
      _$CategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);

  Category toEntity() {
    return Category(
      id: id,
      name: name,
      icon: _getIconFromName(icon),
      color: _getColorFromHex(color),
      budget: budget,
    );
  }

  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      icon: category.iconName,
      color: category.colorHex,
      budget: category.budget,
    );
  }

  static IconData _getIconFromName(String iconName) {
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
      case 'fitness_center':
        return Icons.fitness_center;
      case 'school':
        return Icons.school;
      case 'local_hospital':
        return Icons.local_hospital;
      default:
        return Icons.category;
    }
  }

  static Color _getColorFromHex(String colorHex) {
    // Remove # if present
    String hex = colorHex.replaceAll('#', '');
    // Add alpha channel if not present
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}

@JsonSerializable()
class CategoriesResponse {
  final List<CategoryModel> categories;

  const CategoriesResponse({required this.categories});

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) => 
      _$CategoriesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CategoriesResponseToJson(this);
}
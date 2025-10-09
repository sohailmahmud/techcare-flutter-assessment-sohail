import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/transaction.dart';
import 'category_model.dart';

part 'transaction_model.g.dart';

@JsonSerializable()
class TransactionModel {
  final String id;
  final String title;
  final String? description;
  final double amount;
  @JsonKey(name: 'type')
  final String typeString;
  @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
  final CategoryModel category;
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime date;

  const TransactionModel({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.typeString,
    required this.category,
    required this.date,
  });

  // Enhanced category serialization to handle type casting issues
  static CategoryModel _categoryFromJson(dynamic json) {
    if (json == null) {
      throw ArgumentError('Category cannot be null');
    }

    if (json is Map<String, dynamic>) {
      return CategoryModel.fromJson(json);
    }

    if (json is CategoryModel) {
      return json;
    }

    // Handle string category ID (fallback)
    if (json is String) {
      // Create a default category model for the ID
      return CategoryModel(
        id: json,
        name: 'Unknown Category',
        icon: 'help_outline',
        color: '#9E9E9E',
        budget: 0.0,
      );
    }

    throw ArgumentError(
        'Invalid category data type: ${json.runtimeType}. Expected Map<String, dynamic> or CategoryModel, got: $json');
  }

  static dynamic _categoryToJson(CategoryModel category) {
    return category.toJson();
  }

  // Enhanced date serialization
  static DateTime _dateFromJson(dynamic json) {
    if (json == null) {
      throw ArgumentError('Date cannot be null');
    }

    if (json is String) {
      try {
        return DateTime.parse(json);
      } catch (e) {
        throw ArgumentError('Invalid date string format: $json');
      }
    }

    if (json is DateTime) {
      return json;
    }

    if (json is int) {
      // Handle timestamp in milliseconds
      return DateTime.fromMillisecondsSinceEpoch(json);
    }

    throw ArgumentError(
        'Invalid date data type: ${json.runtimeType}. Expected String, DateTime, or int, got: $json');
  }

  static String _dateToJson(DateTime date) {
    return date.toIso8601String();
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    try {
      return _$TransactionModelFromJson(json);
    } catch (e) {
      throw ArgumentError(
          'Failed to parse TransactionModel from JSON: $json. Error: $e');
    }
  }

  Map<String, dynamic> toJson() {
    try {
      return _$TransactionModelToJson(this);
    } catch (e) {
      throw ArgumentError(
          'Failed to convert TransactionModel to JSON. Error: $e');
    }
  }

  Transaction toEntity() {
    return Transaction(
      id: id,
      title: title,
      description: description,
      amount: amount,
      type: _parseTransactionType(typeString),
      category: category.toEntity(),
      date: date,
    );
  }

  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      title: transaction.title,
      description: transaction.description,
      amount: transaction.amount,
      typeString: _transactionTypeToString(transaction.type),
      category: CategoryModel.fromEntity(transaction.category),
      date: transaction.date,
    );
  }

  // Helper methods for transaction type conversion
  static TransactionType _parseTransactionType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      default:
        throw ArgumentError(
            'Invalid transaction type: $typeString. Expected "income" or "expense"');
    }
  }

  static String _transactionTypeToString(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
      case TransactionType.all:
        throw ArgumentError('Cannot convert TransactionType.all to string');
    }
  }

  // Validation method to ensure data integrity
  bool isValid() {
    return id.isNotEmpty &&
        title.isNotEmpty &&
        amount > 0 &&
        (typeString == 'income' || typeString == 'expense');
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, title: $title, amount: $amount, type: $typeString, category: ${category.name}, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.amount == amount &&
        other.typeString == typeString &&
        other.category == category &&
        other.date == date;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      amount,
      typeString,
      category,
      date,
    );
  }
}

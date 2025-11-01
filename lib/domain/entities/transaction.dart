import 'package:equatable/equatable.dart';
import 'category.dart';

/// Transaction entity representing a financial transaction
class Transaction extends Equatable {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final Category category;
  final DateTime date;
  final String? description;
  final DateTime? createdAt;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.description,
    this.createdAt,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  // Convenience getters for backward compatibility
  String get categoryId => category.id;
  String get categoryName => category.name;
  String? get notes => description;

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    Category? category,
    DateTime? date,
    String? description,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    type,
    category,
    date,
    description,
    createdAt,
  ];
}

enum TransactionType { all, income, expense }

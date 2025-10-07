import 'package:equatable/equatable.dart';

/// Transaction entity representing a financial transaction
class Transaction extends Equatable {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String categoryName;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        type,
        categoryId,
        categoryName,
        date,
        notes,
        createdAt,
      ];
}

enum TransactionType {
  income,
  expense,
}
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fintrack/domain/entities/transaction.dart';
import 'package:fintrack/domain/entities/category.dart';

void main() {
  group('Transaction', () {
    const category = Category(
      id: 'cat1',
      name: 'Food',
      icon: Icons.restaurant,
      color: Colors.orange,
      isIncome: false,
    );

    final transaction = Transaction(
      id: '1',
      title: 'Lunch',
      amount: 25.50,
      type: TransactionType.expense,
      category: category,
      date: DateTime(2025, 1, 15, 12, 30),
      description: 'Had lunch at restaurant',
      createdAt: DateTime(2025, 1, 15, 12, 32),
    );

    group('constructor', () {
      test('creates transaction with required parameters', () {
        final minimalTransaction = Transaction(
          id: '2',
          title: 'Salary',
          amount: 5000.0,
          type: TransactionType.income,
          category: category,
          date: DateTime(2025, 1, 1),
        );

        expect(minimalTransaction.id, '2');
        expect(minimalTransaction.title, 'Salary');
        expect(minimalTransaction.amount, 5000.0);
        expect(minimalTransaction.type, TransactionType.income);
        expect(minimalTransaction.category, category);
        expect(minimalTransaction.date, DateTime(2025, 1, 1));
        expect(minimalTransaction.description, isNull);
        expect(minimalTransaction.createdAt, isNull);
      });

      test('creates transaction with all parameters', () {
        expect(transaction.id, '1');
        expect(transaction.title, 'Lunch');
        expect(transaction.amount, 25.50);
        expect(transaction.type, TransactionType.expense);
        expect(transaction.category, category);
        expect(transaction.date, DateTime(2025, 1, 15, 12, 30));
        expect(transaction.description, 'Had lunch at restaurant');
        expect(transaction.createdAt, DateTime(2025, 1, 15, 12, 32));
      });
    });

    group('convenience getters', () {
      test('isIncome returns true for income transactions', () {
        final incomeTransaction =
            transaction.copyWith(type: TransactionType.income);
        expect(incomeTransaction.isIncome, isTrue);
        expect(incomeTransaction.isExpense, isFalse);
      });

      test('isExpense returns true for expense transactions', () {
        expect(transaction.isExpense, isTrue);
        expect(transaction.isIncome, isFalse);
      });

      test('categoryId returns category id', () {
        expect(transaction.categoryId, 'cat1');
      });

      test('categoryName returns category name', () {
        expect(transaction.categoryName, 'Food');
      });

      test('notes returns description for backward compatibility', () {
        expect(transaction.notes, 'Had lunch at restaurant');
      });
    });

    group('copyWith', () {
      test('returns new instance with updated properties', () {
        final updatedTransaction = transaction.copyWith(
          title: 'Updated Lunch',
          amount: 30.0,
          description: 'Updated description',
        );

        expect(updatedTransaction.id, transaction.id);
        expect(updatedTransaction.title, 'Updated Lunch');
        expect(updatedTransaction.amount, 30.0);
        expect(updatedTransaction.type, transaction.type);
        expect(updatedTransaction.category, transaction.category);
        expect(updatedTransaction.date, transaction.date);
        expect(updatedTransaction.description, 'Updated description');
        expect(updatedTransaction.createdAt, transaction.createdAt);
      });

      test('returns identical instance when no parameters provided', () {
        final copiedTransaction = transaction.copyWith();

        expect(copiedTransaction, equals(transaction));
        expect(copiedTransaction.hashCode, equals(transaction.hashCode));
      });

      test('maintains optional properties when not explicitly set', () {
        final updatedTransaction = transaction.copyWith(
          title: 'Updated Title',
        );

        expect(updatedTransaction.description, 'Had lunch at restaurant');
        expect(updatedTransaction.createdAt, DateTime(2025, 1, 15, 12, 32));
        expect(updatedTransaction.title, 'Updated Title');
        expect(updatedTransaction.amount, transaction.amount);
      });
    });

    group('equality', () {
      test('two transactions with same properties are equal', () {
        final transaction1 = Transaction(
          id: '1',
          title: 'Test',
          amount: 100.0,
          type: TransactionType.expense,
          category: category,
          date: DateTime(2025, 1, 1),
        );

        final transaction2 = Transaction(
          id: '1',
          title: 'Test',
          amount: 100.0,
          type: TransactionType.expense,
          category: category,
          date: DateTime(2025, 1, 1),
        );

        expect(transaction1, equals(transaction2));
        expect(transaction1.hashCode, equals(transaction2.hashCode));
      });

      test('two transactions with different properties are not equal', () {
        final transaction1 = Transaction(
          id: '1',
          title: 'Test',
          amount: 100.0,
          type: TransactionType.expense,
          category: category,
          date: DateTime(2025, 1, 1),
        );

        final transaction2 = Transaction(
          id: '2',
          title: 'Test',
          amount: 100.0,
          type: TransactionType.expense,
          category: category,
          date: DateTime(2025, 1, 1),
        );

        expect(transaction1, isNot(equals(transaction2)));
        expect(transaction1.hashCode, isNot(equals(transaction2.hashCode)));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        final string = transaction.toString();

        expect(string, contains('Transaction'));
        expect(string, contains('1'));
        expect(string, contains('Lunch'));
        expect(string, contains('25.5'));
      });
    });
  });
}

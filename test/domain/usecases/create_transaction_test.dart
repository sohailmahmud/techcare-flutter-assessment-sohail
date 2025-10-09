import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:fintrack/domain/usecases/create_transaction.dart';
import 'package:fintrack/domain/repositories/transaction_repository.dart';
import 'package:fintrack/domain/entities/transaction.dart';
import 'package:fintrack/domain/entities/category.dart';
import 'package:fintrack/core/errors/failures.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class FakeTransaction extends Fake implements Transaction {}

void main() {
  late CreateTransaction usecase;
  late MockTransactionRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeTransaction());
  });

  setUp(() {
    mockRepository = MockTransactionRepository();
    usecase = CreateTransaction(mockRepository);
  });

  group('CreateTransaction UseCase', () {
    const testCategory = Category(
      id: 'cat1',
      name: 'Food',
      icon: Icons.restaurant,
      color: Colors.orange,
      isIncome: false,
    );

    final testTransaction = Transaction(
      id: 'trans1',
      title: 'Lunch',
      amount: 25.50,
      type: TransactionType.expense,
      category: testCategory,
      date: DateTime(2024, 1, 15),
      description: 'Had lunch at restaurant',
    );

    test('should create transaction through repository', () async {
      // Arrange
      when(() => mockRepository.createTransaction(any()))
          .thenAnswer((_) async => Right(testTransaction));

      // Act
      final result = await usecase(testTransaction);

      // Assert
      expect(result, Right(testTransaction));
      verify(() => mockRepository.createTransaction(testTransaction)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to create transaction');
      when(() => mockRepository.createTransaction(any()))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await usecase(testTransaction);

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.createTransaction(testTransaction)).called(1);
    });

    test('should handle validation failure', () async {
      // Arrange
      const validationFailure = ValidationFailure('Amount must be greater than 0');
      when(() => mockRepository.createTransaction(any()))
          .thenAnswer((_) async => const Left(validationFailure));

      // Act
      final result = await usecase(testTransaction);

      // Assert
      expect(result, const Left(validationFailure));
      verify(() => mockRepository.createTransaction(testTransaction)).called(1);
    });

    test('should pass transaction with all fields to repository', () async {
      // Arrange
      final fullTransaction = Transaction(
        id: 'trans2',
        title: 'Grocery Shopping',
        amount: 150.75,
        type: TransactionType.expense,
        category: testCategory,
        date: DateTime(2024, 1, 20),
        description: 'Weekly groceries from supermarket',
        createdAt: DateTime.now(),
      );

      when(() => mockRepository.createTransaction(fullTransaction))
          .thenAnswer((_) async => Right(fullTransaction));

      // Act
      final result = await usecase(fullTransaction);

      // Assert
      expect(result, Right(fullTransaction));
      verify(() => mockRepository.createTransaction(fullTransaction)).called(1);
    });

    test('should handle income transaction creation', () async {
      // Arrange
      const incomeCategory = Category(
        id: 'income1',
        name: 'Salary',
        icon: Icons.payments,
        color: Colors.green,
        isIncome: true,
      );

      final incomeTransaction = Transaction(
        id: 'income_trans1',
        title: 'Monthly Salary',
        amount: 5000.0,
        type: TransactionType.income,
        category: incomeCategory,
        date: DateTime(2024, 1, 1),
        description: 'Salary for January',
      );

      when(() => mockRepository.createTransaction(incomeTransaction))
          .thenAnswer((_) async => Right(incomeTransaction));

      // Act
      final result = await usecase(incomeTransaction);

      // Assert
      expect(result, Right(incomeTransaction));
      verify(() => mockRepository.createTransaction(incomeTransaction)).called(1);
    });
  });
}
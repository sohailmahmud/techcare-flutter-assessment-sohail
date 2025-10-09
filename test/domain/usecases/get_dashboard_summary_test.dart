import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:fintrack/domain/usecases/get_dashboard_summary.dart';
import 'package:fintrack/domain/repositories/dashboard_repository.dart';
import 'package:fintrack/domain/entities/dashboard_summary.dart';
import 'package:fintrack/domain/entities/transaction.dart';
import 'package:fintrack/domain/entities/category.dart';
import 'package:fintrack/core/errors/failures.dart';
import 'package:fintrack/core/usecases/usecase.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late GetDashboardSummary usecase;
  late MockDashboardRepository mockRepository;

  setUp(() {
    mockRepository = MockDashboardRepository();
    usecase = GetDashboardSummary(mockRepository);
  });

  group('GetDashboardSummary UseCase', () {
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
    );

    const categoryExpense = CategoryExpense(
      categoryId: 'cat1',
      categoryName: 'Food',
      amount: 150.0,
      percentage: 30.0,
      transactionCount: 5,
    );

    final mockSummary = DashboardSummary(
      totalBalance: 5000.0,
      monthlyIncome: 8000.0,
      monthlyExpense: 3000.0,
      categoryExpenses: const [categoryExpense],
      recentTransactions: [testTransaction],
      lastUpdated: DateTime(2024, 1, 15, 10, 30),
    );

    test('should get dashboard summary from repository', () async {
      // Arrange
      when(() => mockRepository.getDashboardSummary())
          .thenAnswer((_) async => Right(mockSummary));

      // Act
      final result = await usecase(NoParams());

      // Assert
      expect(result, Right(mockSummary));
      verify(() => mockRepository.getDashboardSummary()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to load dashboard');
      when(() => mockRepository.getDashboardSummary())
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await usecase(NoParams());

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.getDashboardSummary()).called(1);
    });

    test('should handle network failure', () async {
      // Arrange
      const networkFailure = NetworkFailure('No internet connection');
      when(() => mockRepository.getDashboardSummary())
          .thenAnswer((_) async => const Left(networkFailure));

      // Act
      final result = await usecase(NoParams());

      // Assert
      expect(result, const Left(networkFailure));
      verify(() => mockRepository.getDashboardSummary()).called(1);
    });

    test('should handle cache failure', () async {
      // Arrange
      const cacheFailure = CacheFailure('Cache read error');
      when(() => mockRepository.getDashboardSummary())
          .thenAnswer((_) async => const Left(cacheFailure));

      // Act
      final result = await usecase(NoParams());

      // Assert
      expect(result, const Left(cacheFailure));
      verify(() => mockRepository.getDashboardSummary()).called(1);
    });

    test('should not require any parameters', () async {
      // Arrange
      when(() => mockRepository.getDashboardSummary())
          .thenAnswer((_) async => Right(mockSummary));

      // Act
      final result = await usecase(NoParams());

      // Assert
      expect(result, isA<Right<Failure, DashboardSummary>>());
      verify(() => mockRepository.getDashboardSummary()).called(1);
    });

    test('should work with empty dashboard data', () async {
      // Arrange
      final emptySummary = DashboardSummary(
        totalBalance: 0.0,
        monthlyIncome: 0.0,
        monthlyExpense: 0.0,
        categoryExpenses: const [],
        recentTransactions: const [],
        lastUpdated: DateTime.now(),
      );

      when(() => mockRepository.getDashboardSummary())
          .thenAnswer((_) async => Right(emptySummary));

      // Act
      final result = await usecase(NoParams());

      // Assert
      expect(result, Right(emptySummary));
      final summary = result.fold((l) => null, (r) => r);
      expect(summary?.categoryExpenses, isEmpty);
      expect(summary?.recentTransactions, isEmpty);
      expect(summary?.totalBalance, equals(0.0));
    });
  });
}

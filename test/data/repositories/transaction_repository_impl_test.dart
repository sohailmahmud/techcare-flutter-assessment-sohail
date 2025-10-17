import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:fintrack/domain/entities/transaction.dart';
import 'package:fintrack/domain/entities/category.dart';
import 'package:fintrack/domain/repositories/transaction_repository.dart';
import 'package:fintrack/core/errors/failures.dart';

// Mock implementation of TransactionRepository for testing
class MockTransactionRepository extends Mock implements TransactionRepository {}

class FakeTransaction extends Fake implements Transaction {}

class FakeTransactionQuery extends Fake implements TransactionQuery {}

void main() {
  late MockTransactionRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeTransaction());
    registerFallbackValue(FakeTransactionQuery());
  });

  setUp(() {
    mockRepository = MockTransactionRepository();
  });

  group('TransactionRepository Contract Tests', () {
    const testCategory = Category(
      id: 'cat1',
      name: 'Food',
      icon: Icons.restaurant,
      color: Colors.orange,
    );

    final testTransaction = Transaction(
      id: 'trans1',
      title: 'Lunch',
      amount: 25.50,
      type: TransactionType.expense,
      category: testCategory,
      date: DateTime(2024, 1, 15),
    );

    const query = TransactionQuery(page: 1, limit: 20);

    const mockMeta = PaginationMeta(
      currentPage: 1,
      totalPages: 1,
      totalItems: 1,
      itemsPerPage: 20,
      hasMore: false,
    );

    final mockResponse = PaginatedResponse<Transaction>(
      data: [testTransaction],
      meta: mockMeta,
    );

    group('getTransactions', () {
      test('should return paginated transactions successfully', () async {
        // Arrange
        when(() => mockRepository.getTransactions(any()))
            .thenAnswer((_) async => Right(mockResponse));

        // Act
        final result = await mockRepository.getTransactions(query);

        // Assert
        expect(result, Right(mockResponse));
        verify(() => mockRepository.getTransactions(query)).called(1);
      });

      test('should return failure when network fails', () async {
        // Arrange
        const failure = NetworkFailure('No internet connection');
        when(() => mockRepository.getTransactions(any()))
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await mockRepository.getTransactions(query);

        // Assert
        expect(result, const Left(failure));
        verify(() => mockRepository.getTransactions(query)).called(1);
      });

      test('should handle server errors', () async {
        // Arrange
        const failure = ServerFailure('Internal server error');
        when(() => mockRepository.getTransactions(any()))
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await mockRepository.getTransactions(query);

        // Assert
        expect(result, const Left(failure));
      });

      test('should work with filtered query', () async {
        // Arrange
        final filteredQuery = TransactionQuery(
          page: 1,
          limit: 20,
          categories: ['cat_001'],
          type: TransactionType.expense,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );

        when(() => mockRepository.getTransactions(filteredQuery))
            .thenAnswer((_) async => Right(mockResponse));

        // Act
        final result = await mockRepository.getTransactions(filteredQuery);

        // Assert
        expect(result, Right(mockResponse));
        verify(() => mockRepository.getTransactions(filteredQuery)).called(1);
      });
    });

    group('getTransaction', () {
      test('should return single transaction by ID', () async {
        // Arrange
        const transactionId = 'trans1';
        when(() => mockRepository.getTransaction(transactionId))
            .thenAnswer((_) async => Right(testTransaction));

        // Act
        final result = await mockRepository.getTransaction(transactionId);

        // Assert
        expect(result, Right(testTransaction));
        verify(() => mockRepository.getTransaction(transactionId)).called(1);
      });

      test('should return not found failure for invalid ID', () async {
        // Arrange
        const transactionId = 'invalid_id';
        const failure = NotFoundFailure('Transaction not found');
        when(() => mockRepository.getTransaction(transactionId))
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await mockRepository.getTransaction(transactionId);

        // Assert
        expect(result, const Left(failure));
      });
    });

    group('createTransaction', () {
      test('should create transaction successfully', () async {
        // Arrange
        when(() => mockRepository.createTransaction(any()))
            .thenAnswer((_) async => Right(testTransaction));

        // Act
        final result = await mockRepository.createTransaction(testTransaction);

        // Assert
        expect(result, Right(testTransaction));
        verify(() => mockRepository.createTransaction(testTransaction))
            .called(1);
      });

      test('should return validation failure for invalid data', () async {
        // Arrange
        const failure = ValidationFailure('Amount must be greater than 0');
        when(() => mockRepository.createTransaction(any()))
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await mockRepository.createTransaction(testTransaction);

        // Assert
        expect(result, const Left(failure));
      });

      test('should handle server errors on creation', () async {
        // Arrange
        const failure = ServerFailure('Failed to create transaction');
        when(() => mockRepository.createTransaction(any()))
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await mockRepository.createTransaction(testTransaction);

        // Assert
        expect(result, const Left(failure));
      });
    });

    group('updateTransaction', () {
      test('should update transaction successfully', () async {
        // Arrange
        final updatedTransaction = testTransaction.copyWith(amount: 30.0);
        when(() => mockRepository.updateTransaction(any()))
            .thenAnswer((_) async => Right(updatedTransaction));

        // Act
        final result =
            await mockRepository.updateTransaction(updatedTransaction);

        // Assert
        expect(result, Right(updatedTransaction));
        verify(() => mockRepository.updateTransaction(updatedTransaction))
            .called(1);
        expect(result.fold((l) => null, (r) => r)?.amount, equals(30.0));
      });

      test('should return not found failure for non-existent transaction',
          () async {
        // Arrange
        const failure = NotFoundFailure('Transaction not found');
        when(() => mockRepository.updateTransaction(any()))
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await mockRepository.updateTransaction(testTransaction);

        // Assert
        expect(result, const Left(failure));
      });
    });

    group('deleteTransaction', () {
      test('should delete transaction successfully', () async {
        // Arrange
        const transactionId = 'trans1';
        when(() => mockRepository.deleteTransaction(transactionId))
            .thenAnswer((_) async => const Right(null));

        // Act
        final result = await mockRepository.deleteTransaction(transactionId);

        // Assert
        expect(result, const Right(null));
        verify(() => mockRepository.deleteTransaction(transactionId)).called(1);
      });

      test('should return not found failure for invalid ID', () async {
        // Arrange
        const transactionId = 'invalid_id';
        const failure = NotFoundFailure('Transaction not found');
        when(() => mockRepository.deleteTransaction(transactionId))
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await mockRepository.deleteTransaction(transactionId);

        // Assert
        expect(result, const Left(failure));
      });
    });

    group('Cache Operations', () {
      test('should get cached transactions when available', () async {
        // Arrange
        final cachedTransactions = [testTransaction];
        when(() => mockRepository.getCachedTransactions())
            .thenAnswer((_) async => Right(cachedTransactions));

        // Act
        final result = await mockRepository.getCachedTransactions();

        // Assert
        expect(result, Right(cachedTransactions));
        verify(() => mockRepository.getCachedTransactions()).called(1);
      });

      test('should handle cache errors', () async {
        // Arrange
        const failure = CacheFailure('Cache read error');
        when(() => mockRepository.getCachedTransactions())
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await mockRepository.getCachedTransactions();

        // Assert
        expect(result, const Left(failure));
      });

      test('should clear cache successfully', () async {
        // Arrange
        when(() => mockRepository.clearCache())
            .thenAnswer((_) async => const Right(null));

        // Act
        final result = await mockRepository.clearCache();

        // Assert
        expect(result, const Right(null));
        verify(() => mockRepository.clearCache()).called(1);
      });
    });

    group('Offline Sync', () {
      test('should sync offline changes successfully', () async {
        // Arrange
        when(() => mockRepository.syncOfflineChanges())
            .thenAnswer((_) async => const Right(null));

        // Act
        final result = await mockRepository.syncOfflineChanges();

        // Assert
        expect(result, const Right(null));
        verify(() => mockRepository.syncOfflineChanges()).called(1);
      });

      test('should handle sync failures', () async {
        // Arrange
        const failure = NetworkFailure('Sync failed - no connection');
        when(() => mockRepository.syncOfflineChanges())
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await mockRepository.syncOfflineChanges();

        // Assert
        expect(result, const Left(failure));
      });
    });

    group('Error Scenarios', () {
      test('should handle multiple failure types', () async {
        // Test all major failure types
        const failures = [
          NetworkFailure('Network error'),
          ServerFailure('Server error'),
          CacheFailure('Cache error'),
          ValidationFailure('Validation error'),
          NotFoundFailure('Not found error'),
        ];

        for (final failure in failures) {
          when(() => mockRepository.getTransactions(any()))
              .thenAnswer((_) async => Left(failure));

          final result = await mockRepository.getTransactions(query);
          expect(result, Left(failure));
        }
      });

      test('should preserve error messages', () async {
        // Arrange
        const errorMessage = 'Specific error message';
        const failure = ServerFailure(errorMessage);
        when(() => mockRepository.getTransactions(any()))
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await mockRepository.getTransactions(query);

        // Assert
        expect(result, const Left(failure));
        final actualFailure = result.fold((l) => l, (r) => null);
        expect((actualFailure as ServerFailure).message, equals(errorMessage));
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:fintrack/domain/usecases/delete_transaction.dart';
import 'package:fintrack/domain/repositories/transaction_repository.dart';
import 'package:fintrack/core/errors/failures.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late DeleteTransaction usecase;
  late MockTransactionRepository mockRepository;

  setUp(() {
    mockRepository = MockTransactionRepository();
    usecase = DeleteTransaction(mockRepository);
  });

  group('DeleteTransaction UseCase', () {
    const transactionId = 'trans123';

    test('should delete transaction through repository', () async {
      // Arrange
      when(
        () => mockRepository.deleteTransaction(any()),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await usecase(transactionId);

      // Assert
      expect(result, const Right(null));
      verify(() => mockRepository.deleteTransaction(transactionId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to delete transaction');
      when(
        () => mockRepository.deleteTransaction(any()),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await usecase(transactionId);

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.deleteTransaction(transactionId)).called(1);
    });

    test('should handle not found error', () async {
      // Arrange
      const notFoundFailure = NotFoundFailure('Transaction not found');
      when(
        () => mockRepository.deleteTransaction(any()),
      ).thenAnswer((_) async => const Left(notFoundFailure));

      // Act
      final result = await usecase(transactionId);

      // Assert
      expect(result, const Left(notFoundFailure));
      verify(() => mockRepository.deleteTransaction(transactionId)).called(1);
    });

    test('should handle network failure', () async {
      // Arrange
      const networkFailure = NetworkFailure('No internet connection');
      when(
        () => mockRepository.deleteTransaction(any()),
      ).thenAnswer((_) async => const Left(networkFailure));

      // Act
      final result = await usecase(transactionId);

      // Assert
      expect(result, const Left(networkFailure));
      verify(() => mockRepository.deleteTransaction(transactionId)).called(1);
    });

    test('should pass correct transaction ID to repository', () async {
      // Arrange
      const customTransactionId = 'custom_trans_456';
      when(
        () => mockRepository.deleteTransaction(customTransactionId),
      ).thenAnswer((_) async => const Right(null));

      // Act
      await usecase(customTransactionId);

      // Assert
      verify(
        () => mockRepository.deleteTransaction(customTransactionId),
      ).called(1);
    });

    test('should handle empty transaction ID', () async {
      // Arrange
      const emptyId = '';
      const validationFailure = ValidationFailure(
        'Transaction ID cannot be empty',
      );
      when(
        () => mockRepository.deleteTransaction(emptyId),
      ).thenAnswer((_) async => const Left(validationFailure));

      // Act
      final result = await usecase(emptyId);

      // Assert
      expect(result, const Left(validationFailure));
      verify(() => mockRepository.deleteTransaction(emptyId)).called(1);
    });
  });
}

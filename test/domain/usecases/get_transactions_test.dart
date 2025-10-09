import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:fintrack/domain/usecases/get_transactions.dart';
import 'package:fintrack/domain/repositories/transaction_repository.dart';
import 'package:fintrack/domain/entities/transaction.dart';
import 'package:fintrack/core/errors/failures.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class FakeTransactionQuery extends Fake implements TransactionQuery {}

void main() {
  late GetTransactions usecase;
  late MockTransactionRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeTransactionQuery());
  });

  setUp(() {
    mockRepository = MockTransactionRepository();
    usecase = GetTransactions(mockRepository);
  });

  group('GetTransactions UseCase', () {
    const query = TransactionQuery(
      page: 1,
      limit: 20,
    );

    final mockTransactions = <Transaction>[];
    const mockMeta = PaginationMeta(
      currentPage: 1,
      totalPages: 1,
      totalItems: 0,
      itemsPerPage: 20,
      hasMore: false,
    );
    final mockResponse = PaginatedResponse<Transaction>(
      data: mockTransactions,
      meta: mockMeta,
    );

    test('should get transactions from repository', () async {
      // Arrange
      when(() => mockRepository.getTransactions(any()))
          .thenAnswer((_) async => Right(mockResponse));

      // Act
      final result = await usecase(query);

      // Assert
      expect(result, Right(mockResponse));
      verify(() => mockRepository.getTransactions(query)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const failure = ServerFailure('Server error');
      when(() => mockRepository.getTransactions(any()))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await usecase(query);

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.getTransactions(query)).called(1);
    });

    test('should pass correct parameters to repository', () async {
      // Arrange
      const customQuery = TransactionQuery(
        page: 2,
        limit: 10,
        category: 'cat1',
        type: TransactionType.expense,
      );
      
      when(() => mockRepository.getTransactions(customQuery))
          .thenAnswer((_) async => Right(mockResponse));

      // Act
      await usecase(customQuery);

      // Assert
      verify(() => mockRepository.getTransactions(customQuery)).called(1);
    });

    test('should handle query with search parameters', () async {
      // Arrange
      final searchQuery = TransactionQuery(
        page: 1,
        limit: 20,
        searchQuery: 'lunch',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );
      
      when(() => mockRepository.getTransactions(searchQuery))
          .thenAnswer((_) async => Right(mockResponse));

      // Act
      final result = await usecase(searchQuery);

      // Assert
      expect(result, Right(mockResponse));
      verify(() => mockRepository.getTransactions(searchQuery)).called(1);
    });
  });
}
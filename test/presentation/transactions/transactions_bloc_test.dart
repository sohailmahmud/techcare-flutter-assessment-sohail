import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fintrack/presentation/transactions/list/bloc/transactions_bloc.dart';
import 'package:fintrack/domain/repositories/transaction_repository.dart';
import 'package:fintrack/domain/entities/transaction.dart' as tx;
import 'package:fintrack/domain/entities/category.dart' as cat;
import 'package:fintrack/data/cache/hive_cache_manager.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockHiveCacheManager extends Mock implements HiveCacheManager {}

void main() {
  late MockTransactionRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(const TransactionQuery());
  });

  setUp(() {
    mockRepo = MockTransactionRepository();
  });

  group('TransactionsBloc cancellation', () {
    test('ignores stale load response when a newer load is issued', () async {
      final bloc = TransactionsBloc(
        cacheManager: MockHiveCacheManager(),
        transactionRepository: mockRepo,
      );

      final slowResponse = PaginatedResponse<tx.Transaction>(
        data: [
          tx.Transaction(
            id: 'load_slow',
            title: 'load slow',
            amount: 5.0,
            type: tx.TransactionType.income,
            category: const cat.Category(
              id: 'lc1',
              name: 'LC1',
              icon: Icons.category,
              color: Colors.green,
            ),
            date: DateTime.now(),
          ),
        ],
        meta: const PaginationMeta(
          currentPage: 1,
          totalPages: 1,
          totalItems: 1,
          itemsPerPage: 20,
          hasMore: false,
        ),
      );

      final fastResponse = PaginatedResponse<tx.Transaction>(
        data: [
          tx.Transaction(
            id: 'load_fast',
            title: 'load fast',
            amount: 6.0,
            type: tx.TransactionType.expense,
            category: const cat.Category(
              id: 'lc2',
              name: 'LC2',
              icon: Icons.category,
              color: Colors.orange,
            ),
            date: DateTime.now(),
          ),
        ],
        meta: const PaginationMeta(
          currentPage: 1,
          totalPages: 1,
          totalItems: 1,
          itemsPerPage: 20,
          hasMore: false,
        ),
      );

      int callCount = 0;
      const emptyResponse = PaginatedResponse<tx.Transaction>(
        data: [],
        meta: PaginationMeta(
          currentPage: 1,
          totalPages: 1,
          totalItems: 0,
          itemsPerPage: 20,
          hasMore: false,
        ),
      );

      when(
        () => mockRepo.getTransactions(
          any(),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) async {
        callCount += 1;
        if (callCount == 1) {
          return const Right(emptyResponse);
        } else if (callCount == 2) {
          await Future.delayed(const Duration(milliseconds: 300));
          return Right(slowResponse);
        } else {
          await Future.delayed(const Duration(milliseconds: 10));
          return Right(fastResponse);
        }
      });

      final states = <TransactionsState>[];
      final sub = bloc.stream.listen(states.add);

      // Fire two LoadTransactions quickly
      bloc.add(const LoadTransactions(page: 1));
      await Future.delayed(const Duration(milliseconds: 20));
      bloc.add(const LoadTransactions(page: 1));

      await Future.delayed(const Duration(milliseconds: 500));
      await sub.cancel();

      final lastLoaded =
          states.lastWhere((s) => s is TransactionLoaded) as TransactionLoaded;
      expect(lastLoaded.transactions.any((t) => t.id == 'load_fast'), isTrue);
      expect(lastLoaded.transactions.any((t) => t.id == 'load_slow'), isFalse);

      await bloc.close();
    });

    test(
      'ignores stale filter response when a newer filter is issued',
      () async {
        final bloc = TransactionsBloc(
          cacheManager: MockHiveCacheManager(),
          transactionRepository: mockRepo,
        );

        final slowResponse = PaginatedResponse<tx.Transaction>(
          data: [
            tx.Transaction(
              id: 'filter_slow',
              title: 'filter slow',
              amount: 7.0,
              type: tx.TransactionType.income,
              category: const cat.Category(
                id: 'fc1',
                name: 'FC1',
                icon: Icons.category,
                color: Colors.purple,
              ),
              date: DateTime.now(),
            ),
          ],
          meta: const PaginationMeta(
            currentPage: 1,
            totalPages: 1,
            totalItems: 1,
            itemsPerPage: 20,
            hasMore: false,
          ),
        );

        final fastResponse = PaginatedResponse<tx.Transaction>(
          data: [
            tx.Transaction(
              id: 'filter_fast',
              title: 'filter fast',
              amount: 8.0,
              type: tx.TransactionType.expense,
              category: const cat.Category(
                id: 'fc2',
                name: 'FC2',
                icon: Icons.category,
                color: Colors.brown,
              ),
              date: DateTime.now(),
            ),
          ],
          meta: const PaginationMeta(
            currentPage: 1,
            totalPages: 1,
            totalItems: 1,
            itemsPerPage: 20,
            hasMore: false,
          ),
        );

        int callCount = 0;
        const emptyResponse = PaginatedResponse<tx.Transaction>(
          data: [],
          meta: PaginationMeta(
            currentPage: 1,
            totalPages: 1,
            totalItems: 0,
            itemsPerPage: 20,
            hasMore: false,
          ),
        );

        when(
          () => mockRepo.getTransactions(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((invocation) async {
          callCount += 1;
          if (callCount == 1) {
            return const Right(emptyResponse);
          } else if (callCount == 2) {
            await Future.delayed(const Duration(milliseconds: 300));
            return Right(slowResponse);
          } else {
            await Future.delayed(const Duration(milliseconds: 10));
            return Right(fastResponse);
          }
        });

        final states = <TransactionsState>[];
        final sub = bloc.stream.listen(states.add);

        // Fire two FilterTransactions with enough gap to bypass throttle (150ms)
        bloc.add(const FilterTransactions({'type': 'income'}));
        await Future.delayed(const Duration(milliseconds: 200));
        bloc.add(const FilterTransactions({'type': 'expense'}));

        await Future.delayed(const Duration(milliseconds: 500));
        await sub.cancel();

        final lastLoaded =
            states.lastWhere((s) => s is TransactionLoaded)
                as TransactionLoaded;
        expect(
          lastLoaded.transactions.any((t) => t.id == 'filter_fast'),
          isTrue,
        );
        expect(
          lastLoaded.transactions.any((t) => t.id == 'filter_slow'),
          isFalse,
        );

        await bloc.close();
      },
    );
  });
}

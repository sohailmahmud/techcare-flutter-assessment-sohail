import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fintrack/presentation/analytics/bloc/analytics_bloc.dart';
import 'package:fintrack/presentation/transactions/list/bloc/transactions_bloc.dart';
import 'package:fintrack/domain/entities/analytics.dart';
import 'package:fintrack/domain/entities/transaction.dart' as tx;
import 'package:fintrack/domain/entities/category.dart';

class MockTransactionsBloc extends Mock implements TransactionsBloc {}

void main() {
  group('AnalyticsBloc', () {
    late AnalyticsBloc analyticsBloc;
    late MockTransactionsBloc mockTransactionsBloc;

    final now = DateTime.now();
    final mockTransactions = [
      tx.Transaction(
        id: '1',
        title: 'Grocery',
        amount: 100.0,
        type: tx.TransactionType.expense,
        category: const Category(
          id: 'food',
          name: 'Food',
          icon: Icons.restaurant,
          color: Colors.orange,
        ),
        date: now,
      ),
      tx.Transaction(
        id: '2',
        title: 'Salary',
        amount: 5000.0,
        type: tx.TransactionType.income,
        category: const Category(
          id: 'salary',
          name: 'Salary',
          icon: Icons.work,
          color: Colors.green,
        ),
        date: now,
      ),
    ];

    setUp(() {
      mockTransactionsBloc = MockTransactionsBloc();
      // Default stub: return the mockTransactions list for the allUnfilteredTransactions getter
      when(
        () => mockTransactionsBloc.allUnfilteredTransactions,
      ).thenReturn(mockTransactions);
      analyticsBloc = AnalyticsBloc(
        transactionsBloc: mockTransactionsBloc,
        categories: [],
      );
    });

    tearDown(() {
      analyticsBloc.close();
    });

    test('initial state is AnalyticsInitial', () {
      expect(analyticsBloc.state, equals(const AnalyticsInitial()));
    });

    group('ChangePeriod', () {
      blocTest<AnalyticsBloc, AnalyticsState>(
        'emits [AnalyticsLoading, AnalyticsLoaded] when period changes successfully',
        build: () => analyticsBloc,
        setUp: () {
          when(() => mockTransactionsBloc.state).thenReturn(
            TransactionLoaded(
              transactions: mockTransactions,
              hasMore: false,
              currentPage: 1,
            ),
          );
          when(
            () => mockTransactionsBloc.allUnfilteredTransactions,
          ).thenReturn(mockTransactions);
        },
        act: (bloc) => bloc.add(const ChangePeriod(TimePeriod.thisWeek)),
        expect: () => [const AnalyticsLoading(), isA<AnalyticsLoaded>()],
      );

      blocTest<AnalyticsBloc, AnalyticsState>(
        'emits [AnalyticsLoading, AnalyticsLoaded] for different time periods',
        build: () => analyticsBloc,
        setUp: () {
          when(() => mockTransactionsBloc.state).thenReturn(
            TransactionLoaded(
              transactions: mockTransactions,
              hasMore: false,
              currentPage: 1,
            ),
          );
          when(
            () => mockTransactionsBloc.allUnfilteredTransactions,
          ).thenReturn(mockTransactions);
        },
        act: (bloc) => bloc.add(const ChangePeriod(TimePeriod.thisMonth)),
        expect: () => [const AnalyticsLoading(), isA<AnalyticsLoaded>()],
      );
    });

    group('LoadAnalytics', () {
      blocTest<AnalyticsBloc, AnalyticsState>(
        'emits [AnalyticsLoading, AnalyticsLoaded] when analytics loaded successfully',
        build: () => analyticsBloc,
        setUp: () {
          when(() => mockTransactionsBloc.state).thenReturn(
            TransactionLoaded(
              transactions: mockTransactions,
              hasMore: false,
              currentPage: 1,
            ),
          );
          when(
            () => mockTransactionsBloc.allUnfilteredTransactions,
          ).thenReturn(mockTransactions);
        },
        act: (bloc) => bloc.add(const LoadAnalytics()),
        expect: () => [const AnalyticsLoading(), isA<AnalyticsLoaded>()],
      );

      blocTest<AnalyticsBloc, AnalyticsState>(
        'calculates correct summary from transactions',
        build: () => analyticsBloc,
        setUp: () {
          when(() => mockTransactionsBloc.state).thenReturn(
            TransactionLoaded(
              transactions: mockTransactions,
              hasMore: false,
              currentPage: 1,
            ),
          );
          when(
            () => mockTransactionsBloc.allUnfilteredTransactions,
          ).thenReturn(mockTransactions);
        },
        act: (bloc) => bloc.add(const LoadAnalytics()),
        verify: (bloc) {
          final state = bloc.state;
          if (state is AnalyticsLoaded) {
            expect(state.data.totalIncome, 5000.0);
            expect(state.data.totalExpenses, 100.0);
            expect(state.data.netBalance, 4900.0);
          }
        },
      );
    });

    group('RefreshAnalytics', () {
      blocTest<AnalyticsBloc, AnalyticsState>(
        'refreshes analytics data',
        build: () => analyticsBloc,
        setUp: () {
          when(() => mockTransactionsBloc.state).thenReturn(
            TransactionLoaded(
              transactions: mockTransactions,
              hasMore: false,
              currentPage: 1,
            ),
          );
          when(
            () => mockTransactionsBloc.allUnfilteredTransactions,
          ).thenReturn(mockTransactions);
        },
        act: (bloc) => bloc.add(const RefreshAnalytics()),
        expect: () => [const AnalyticsLoading(), isA<AnalyticsLoaded>()],
      );
    });

    group('FilterByCategory', () {
      blocTest<AnalyticsBloc, AnalyticsState>(
        'filters analytics by specific category',
        build: () => analyticsBloc,
        setUp: () {
          when(() => mockTransactionsBloc.state).thenReturn(
            TransactionLoaded(
              transactions: mockTransactions,
              hasMore: false,
              currentPage: 1,
            ),
          );
        },
        act: (bloc) async {
          // First load analytics to get into AnalyticsLoaded state
          bloc.add(const LoadAnalytics());
          await Future.delayed(const Duration(milliseconds: 100));
          // Then filter by category
          bloc.add(const FilterByCategory('food'));
        },
        expect: () => [
          const AnalyticsLoading(),
          isA<AnalyticsLoaded>(),
          isA<AnalyticsLoaded>(),
        ],
      );

      blocTest<AnalyticsBloc, AnalyticsState>(
        'shows all categories when filter is null',
        build: () => analyticsBloc,
        setUp: () {
          when(() => mockTransactionsBloc.state).thenReturn(
            TransactionLoaded(
              transactions: mockTransactions,
              hasMore: false,
              currentPage: 1,
            ),
          );
        },
        act: (bloc) async {
          // First load analytics to get into AnalyticsLoaded state
          bloc.add(const LoadAnalytics());
          await Future.delayed(const Duration(milliseconds: 100));
          // Then filter by category
          bloc.add(const FilterByCategory(null));
        },
        expect: () => [
          const AnalyticsLoading(),
          isA<AnalyticsLoaded>(),
          isA<AnalyticsLoaded>(),
        ],
      );
    });

    group('Error Handling', () {
      blocTest<AnalyticsBloc, AnalyticsState>(
        'emits error when transactions bloc is in error state',
        build: () => analyticsBloc,
        setUp: () {
          when(() => mockTransactionsBloc.state).thenReturn(
            const TransactionError(error: 'Failed to load transactions'),
          );
          // Simulate failure to provide transactions via the getter
          when(
            () => mockTransactionsBloc.allUnfilteredTransactions,
          ).thenThrow(Exception('Failed to load transactions'));
        },
        act: (bloc) => bloc.add(const LoadAnalytics()),
        expect: () => [
          const AnalyticsLoading(),
          const AnalyticsError(
            'Failed to load analytics: Exception: Failed to load transactions',
          ),
        ],
      );
    });

    group('Edge Cases', () {
      blocTest<AnalyticsBloc, AnalyticsState>(
        'handles empty transaction list',
        build: () => analyticsBloc,
        setUp: () {
          when(() => mockTransactionsBloc.state).thenReturn(
            const TransactionLoaded(
              transactions: [],
              hasMore: false,
              currentPage: 1,
            ),
          );
          when(
            () => mockTransactionsBloc.allUnfilteredTransactions,
          ).thenReturn([]);
        },
        act: (bloc) => bloc.add(const LoadAnalytics()),
        expect: () => [const AnalyticsLoading(), isA<AnalyticsLoaded>()],
        verify: (bloc) {
          final state = bloc.state;
          if (state is AnalyticsLoaded) {
            expect(state.data.totalIncome, 0.0);
            expect(state.data.totalExpenses, 0.0);
            expect(state.data.netBalance, 0.0);
            expect(state.data.categoryBreakdown, isEmpty);
          }
        },
      );

      blocTest<AnalyticsBloc, AnalyticsState>(
        'handles custom date range',
        build: () => analyticsBloc,
        setUp: () {
          when(() => mockTransactionsBloc.state).thenReturn(
            TransactionLoaded(
              transactions: mockTransactions,
              hasMore: false,
              currentPage: 1,
            ),
          );
        },
        act: (bloc) => bloc.add(
          ChangePeriod(
            TimePeriod.custom,
            customRange: DateRange(
              startDate: DateTime(2025, 10, 1),
              endDate: DateTime(2025, 10, 31),
            ),
          ),
        ),
        expect: () => [const AnalyticsLoading(), isA<AnalyticsLoaded>()],
      );
    });
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:fintrack/presentation/dashboard/bloc/dashboard_bloc.dart';
import 'package:fintrack/presentation/dashboard/bloc/dashboard_event.dart';
import 'package:fintrack/presentation/dashboard/bloc/dashboard_state.dart';
import 'package:fintrack/domain/usecases/get_dashboard_summary.dart';
import 'package:fintrack/domain/usecases/refresh_dashboard.dart';
import 'package:fintrack/domain/entities/dashboard_summary.dart';
import 'package:fintrack/core/errors/failures.dart';
import 'package:fintrack/core/usecases/usecase.dart';

class MockGetDashboardSummary extends Mock implements GetDashboardSummary {}
class MockRefreshDashboard extends Mock implements RefreshDashboard {}

void main() {
  group('DashboardBloc', () {
    late DashboardBloc dashboardBloc;
    late MockGetDashboardSummary mockGetDashboardSummary;
    late MockRefreshDashboard mockRefreshDashboard;

    setUpAll(() {
      registerFallbackValue(NoParams());
    });

    final mockSummary = DashboardSummary(
      totalBalance: 10000.0,
      monthlyIncome: 8000.0,
      monthlyExpense: 3000.0,
      categoryExpenses: const [],
      recentTransactions: const [],
      lastUpdated: DateTime(2025, 10, 9),
    );

    setUp(() {
      mockGetDashboardSummary = MockGetDashboardSummary();
      mockRefreshDashboard = MockRefreshDashboard();
      
      dashboardBloc = DashboardBloc(
        getDashboardSummary: mockGetDashboardSummary,
        refreshDashboard: mockRefreshDashboard,
      );
    });

    tearDown(() {
      dashboardBloc.close();
    });

    test('initial state is DashboardInitial', () {
      expect(dashboardBloc.state, equals(const DashboardInitial()));
    });

    group('LoadDashboard', () {
      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, DashboardLoaded] when dashboard loads successfully',
        build: () => dashboardBloc,
        setUp: () {
          when(() => mockGetDashboardSummary(any()))
              .thenAnswer((_) async => Right(mockSummary));
        },
        act: (bloc) => bloc.add(const LoadDashboard()),
        expect: () => [
          const DashboardLoading(),
          DashboardLoaded(
            summary: mockSummary,
            filteredTransactions: const [],
          ),
        ],
        verify: (_) {
          verify(() => mockGetDashboardSummary(NoParams())).called(1);
        },
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, DashboardError] when dashboard loading fails',
        build: () => dashboardBloc,
        setUp: () {
          when(() => mockGetDashboardSummary(any()))
              .thenAnswer((_) async => const Left(NetworkFailure('Network error')));
        },
        act: (bloc) => bloc.add(const LoadDashboard()),
        expect: () => [
          const DashboardLoading(),
          const DashboardError(
            message: 'Network connection failed. Please check your internet connection.',
            canRetry: true,
          ),
        ],
        verify: (_) {
          verify(() => mockGetDashboardSummary(NoParams())).called(1);
        },
      );
    });

    group('RefreshDashboardData', () {
      blocTest<DashboardBloc, DashboardState>(
        'refreshes dashboard data successfully',
        build: () => dashboardBloc,
        setUp: () {
          when(() => mockRefreshDashboard(any()))
              .thenAnswer((_) async => Right(mockSummary));
        },
        act: (bloc) => bloc.add(const RefreshDashboardData()),
        expect: () => [
          const DashboardLoading(),
          DashboardLoaded(
            summary: mockSummary,
            filteredTransactions: const [],
          ),
        ],
        verify: (_) {
          verify(() => mockRefreshDashboard(NoParams())).called(1);
        },
      );

      blocTest<DashboardBloc, DashboardState>(
        'handles refresh error',
        build: () => dashboardBloc,
        setUp: () {
          when(() => mockRefreshDashboard(any()))
              .thenAnswer((_) async => const Left(CacheFailure('Cache error')));
        },
        act: (bloc) => bloc.add(const RefreshDashboardData()),
        expect: () => [
          const DashboardLoading(),
          const DashboardError(
            message: 'Failed to load data from cache. Please restart the app.',
            canRetry: true,
          ),
        ],
        verify: (_) {
          verify(() => mockRefreshDashboard(NoParams())).called(1);
        },
      );
    });

    group('ToggleBalanceVisibility', () {
      blocTest<DashboardBloc, DashboardState>(
        'toggles balance visibility',
        build: () => dashboardBloc,
        seed: () => DashboardLoaded(
          summary: mockSummary,
          filteredTransactions: const [],
        ),
        act: (bloc) => bloc.add(const ToggleBalanceVisibility()),
        expect: () => [
          DashboardLoaded(
            summary: mockSummary,
            filteredTransactions: const [],
            isBalanceVisible: false,
          ),
        ],
      );
    });

    group('RetryLoadDashboard', () {
      blocTest<DashboardBloc, DashboardState>(
        'retries loading dashboard after error',
        build: () => dashboardBloc,
        setUp: () {
          when(() => mockGetDashboardSummary(any()))
              .thenAnswer((_) async => Right(mockSummary));
        },
        seed: () => const DashboardError(
          message: 'Previous error',
          canRetry: true,
        ),
        act: (bloc) => bloc.add(const RetryLoadDashboard()),
        expect: () => [
          const DashboardLoading(),
          DashboardLoaded(
            summary: mockSummary,
            filteredTransactions: const [],
          ),
        ],
        verify: (_) {
          verify(() => mockGetDashboardSummary(NoParams())).called(1);
        },
      );
    });
  });
}
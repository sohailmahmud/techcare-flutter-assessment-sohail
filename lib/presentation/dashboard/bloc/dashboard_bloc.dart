import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/usecases/get_dashboard_summary.dart';
import '../../../domain/usecases/refresh_dashboard.dart' as refresh_usecase;
import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// Dashboard BLoC for managing dashboard state
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardSummary _getDashboardSummary;
  final refresh_usecase.RefreshDashboard _refreshDashboard;

  DashboardBloc({
    required GetDashboardSummary getDashboardSummary,
    required refresh_usecase.RefreshDashboard refreshDashboard,
  })  : _getDashboardSummary = getDashboardSummary,
        _refreshDashboard = refreshDashboard,
        super(const DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboardData>(_onRefreshDashboard);
    on<RetryLoadDashboard>(_onRetryLoadDashboard);
    on<SelectTransactionFilter>(_onSelectTransactionFilter);
    on<ToggleBalanceVisibility>(_onToggleBalanceVisibility);
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      debugPrint('🔄 DashboardBloc: Starting to load dashboard');
      emit(const DashboardLoading());
      
      debugPrint('🔄 DashboardBloc: Calling getDashboardSummary use case');
      final result = await _getDashboardSummary(NoParams());
      
      debugPrint('🔄 DashboardBloc: Got result from use case');
      result.fold(
        (failure) {
          debugPrint('❌ DashboardBloc: Failure occurred: $failure');
          emit(DashboardError(
            message: _mapFailureToMessage(failure),
            canRetry: true,
          ));
        },
        (summary) {
          debugPrint('✅ DashboardBloc: Success! Loaded summary with ${summary.recentTransactions.length} transactions');
          emit(DashboardLoaded(
            summary: summary,
            filteredTransactions: summary.recentTransactions,
            isBalanceVisible: true,
          ));
        },
      );
    } catch (e, stackTrace) {
      debugPrint('💥 DashboardBloc: Unexpected error in _onLoadDashboard: $e');
      debugPrint('💥 StackTrace: $stackTrace');
      emit(DashboardError(
        message: 'Unexpected error occurred: $e',
        canRetry: true,
      ));
    }
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(currentState.copyWith(isRefreshing: true));
    } else {
      emit(const DashboardLoading());
    }

    final result = await _refreshDashboard(NoParams());

    result.fold(
      (failure) {
        if (state is DashboardLoaded) {
          final currentState = state as DashboardLoaded;
          emit(currentState.copyWith(isRefreshing: false));
          // Could show a snackbar or toast here for refresh error
        } else {
          emit(DashboardError(
            message: _mapFailureToMessage(failure),
            canRetry: true,
          ));
        }
      },
      (summary) {
        final currentState = state is DashboardLoaded ? state as DashboardLoaded : null;
        final filteredTransactions = _applyTransactionFilter(
          summary.recentTransactions,
          currentState?.selectedCategoryFilter,
        );
        
        emit(DashboardLoaded(
          summary: summary,
          filteredTransactions: filteredTransactions,
          selectedCategoryFilter: currentState?.selectedCategoryFilter,
          isBalanceVisible: currentState?.isBalanceVisible ?? true,
          isRefreshing: false,
        ));
      },
    );
  }

  Future<void> _onRetryLoadDashboard(
    RetryLoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    add(const LoadDashboard());
  }

  void _onSelectTransactionFilter(
    SelectTransactionFilter event,
    Emitter<DashboardState> emit,
  ) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      final filteredTransactions = _applyTransactionFilter(
        currentState.summary.recentTransactions,
        event.categoryId,
      );

      debugPrint('🔄 Filter changed to: ${event.categoryId}');
      debugPrint('📊 Filtered transactions count: ${filteredTransactions.length}');
      debugPrint('📈 Total transactions count: ${currentState.summary.recentTransactions.length}');

      emit(currentState.copyWith(
        filteredTransactions: filteredTransactions,
        selectedCategoryFilter: event.categoryId,
      ));
    }
  }

  void _onToggleBalanceVisibility(
    ToggleBalanceVisibility event,
    Emitter<DashboardState> emit,
  ) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(currentState.copyWith(
        isBalanceVisible: !currentState.isBalanceVisible,
      ));
    }
  }

  List<Transaction> _applyTransactionFilter(
    List<Transaction> transactions,
    String? categoryFilter,
  ) {
    if (categoryFilter == null) {
      return transactions;
    }
    
    return transactions
        .where((transaction) => transaction.categoryId == categoryFilter)
        .toList();
  }

  String _mapFailureToMessage(failure) {
    // Map specific failures to user-friendly messages with more details for debugging
    final failureString = failure.toString();
    debugPrint('🔍 DashboardBloc: Mapping failure: $failureString');
    
    if (failureString.contains('network') || failureString.contains('Network')) {
      return 'No internet connection. Please check your network.\n\nDetails: $failureString';
    } else if (failureString.contains('server') || failureString.contains('Server')) {
      return 'Server error. Please try again later.\n\nDetails: $failureString';
    } else {
      return 'Something went wrong. Please try again.\n\nDetails: $failureString';
    }
  }
}
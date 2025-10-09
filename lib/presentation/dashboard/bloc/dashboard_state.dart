import 'package:equatable/equatable.dart';
import '../../../domain/entities/dashboard_summary.dart';
import '../../../domain/entities/transaction.dart';

/// Base dashboard state
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Loading state
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// Loaded state with data
class DashboardLoaded extends DashboardState {
  final DashboardSummary summary;
  final List<Transaction> filteredTransactions;
  final String? selectedCategoryFilter;
  final bool isBalanceVisible;
  final bool isRefreshing;

  const DashboardLoaded({
    required this.summary,
    required this.filteredTransactions,
    this.selectedCategoryFilter,
    this.isBalanceVisible = true,
    this.isRefreshing = false,
  });

  DashboardLoaded copyWith({
    DashboardSummary? summary,
    List<Transaction>? filteredTransactions,
    String? selectedCategoryFilter,
    bool? isBalanceVisible,
    bool? isRefreshing,
  }) {
    return DashboardLoaded(
      summary: summary ?? this.summary,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      selectedCategoryFilter:
          selectedCategoryFilter ?? this.selectedCategoryFilter,
      isBalanceVisible: isBalanceVisible ?? this.isBalanceVisible,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        summary,
        filteredTransactions,
        selectedCategoryFilter,
        isBalanceVisible,
        isRefreshing,
      ];
}

/// Error state
class DashboardError extends DashboardState {
  final String message;
  final bool canRetry;

  const DashboardError({
    required this.message,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, canRetry];
}

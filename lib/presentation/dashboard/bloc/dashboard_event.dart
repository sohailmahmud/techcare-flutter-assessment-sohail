import 'package:equatable/equatable.dart';

/// Base dashboard event
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Load dashboard data
class LoadDashboard extends DashboardEvent {
  const LoadDashboard();
}

/// Refresh dashboard data
class RefreshDashboardData extends DashboardEvent {
  const RefreshDashboardData();
}

/// Retry loading dashboard after error
class RetryLoadDashboard extends DashboardEvent {
  const RetryLoadDashboard();
}

/// Select transaction filter
class SelectTransactionFilter extends DashboardEvent {
  final String? categoryId;

  const SelectTransactionFilter({this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

/// Toggle balance card visibility
class ToggleBalanceVisibility extends DashboardEvent {
  const ToggleBalanceVisibility();
}

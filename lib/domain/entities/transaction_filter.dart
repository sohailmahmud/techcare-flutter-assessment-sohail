import 'package:equatable/equatable.dart';

/// Date range presets for transaction filtering
enum DateRangePreset {
  today,
  thisWeek,
  thisMonth,
  lastThreeMonths,
  custom;

  String get displayName {
    switch (this) {
      case DateRangePreset.today:
        return 'Today';
      case DateRangePreset.thisWeek:
        return 'This Week';
      case DateRangePreset.thisMonth:
        return 'This Month';
      case DateRangePreset.lastThreeMonths:
        return 'Last 3 Months';
      case DateRangePreset.custom:
        return 'Custom Range';
    }
  }

  DateRange getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case DateRangePreset.today:
        return DateRange(
          start: today,
          end: today
              .add(const Duration(days: 1))
              .subtract(const Duration(milliseconds: 1)),
        );
      case DateRangePreset.thisWeek:
        final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
        return DateRange(
          start: startOfWeek,
          end: startOfWeek
              .add(const Duration(days: 7))
              .subtract(const Duration(milliseconds: 1)),
        );
      case DateRangePreset.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(
          now.year,
          now.month + 1,
          1,
        ).subtract(const Duration(milliseconds: 1));
        return DateRange(start: startOfMonth, end: endOfMonth);
      case DateRangePreset.lastThreeMonths:
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        return DateRange(start: threeMonthsAgo, end: now);
      case DateRangePreset.custom:
        // Return a default range, actual range will be set by user
        return DateRange(
          start: today.subtract(const Duration(days: 30)),
          end: today,
        );
    }
  }
}

/// Transaction type filter options
enum TransactionType {
  all,
  income,
  expense;

  String get displayName {
    switch (this) {
      case TransactionType.all:
        return 'All';
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
    }
  }
}

/// Date range model for filtering transactions
class DateRange extends Equatable {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  DateRange copyWith({DateTime? start, DateTime? end}) {
    return DateRange(start: start ?? this.start, end: end ?? this.end);
  }

  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
        date.isBefore(end.add(const Duration(milliseconds: 1)));
  }

  Duration get duration => end.difference(start);

  @override
  List<Object> get props => [start, end];
}

/// Amount range model for filtering transactions
class AmountRange extends Equatable {
  final double min;
  final double max;

  const AmountRange({required this.min, required this.max});

  AmountRange copyWith({double? min, double? max}) {
    return AmountRange(min: min ?? this.min, max: max ?? this.max);
  }

  bool contains(double amount) {
    final absAmount = amount.abs();
    return absAmount >= min && absAmount <= max;
  }

  @override
  List<Object> get props => [min, max];
}

/// Comprehensive transaction filter model
class TransactionFilter extends Equatable {
  final String searchQuery;
  final DateRange? dateRange;
  final DateRangePreset? datePreset;
  final List<String> selectedCategories;
  final AmountRange? amountRange;
  final TransactionType transactionType;

  const TransactionFilter({
    this.searchQuery = '',
    this.dateRange,
    this.datePreset,
    this.selectedCategories = const [],
    this.amountRange,
    this.transactionType = TransactionType.all,
  });

  TransactionFilter copyWith({
    String? searchQuery,
    DateRange? dateRange,
    DateRangePreset? datePreset,
    List<String>? selectedCategories,
    AmountRange? amountRange,
    TransactionType? transactionType,
  }) {
    return TransactionFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: dateRange ?? this.dateRange,
      datePreset: datePreset ?? this.datePreset,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      amountRange: amountRange ?? this.amountRange,
      transactionType: transactionType ?? this.transactionType,
    );
  }

  TransactionFilter clearFilters() {
    return const TransactionFilter();
  }

  bool get hasActiveFilters {
    return searchQuery.isNotEmpty ||
        dateRange != null ||
        selectedCategories.isNotEmpty ||
        amountRange != null ||
        transactionType != TransactionType.all;
  }

  int get activeFilterCount {
    int count = 0;
    if (searchQuery.isNotEmpty) count++;
    if (dateRange != null) count++;
    if (selectedCategories.isNotEmpty) count++;
    if (amountRange != null) count++;
    if (transactionType != TransactionType.all) count++;
    return count;
  }

  @override
  List<Object?> get props => [
    searchQuery,
    dateRange,
    datePreset,
    selectedCategories,
    amountRange,
    transactionType,
  ];
}

/// Pagination information for transactions
class PaginationInfo extends Equatable {
  final int currentPage;
  final int itemsPerPage;
  final int totalItems;
  final bool hasNextPage;
  final bool isLoading;

  const PaginationInfo({
    this.currentPage = 0,
    this.itemsPerPage = 20,
    this.totalItems = 0,
    this.hasNextPage = true,
    this.isLoading = false,
  });

  PaginationInfo copyWith({
    int? currentPage,
    int? itemsPerPage,
    int? totalItems,
    bool? hasNextPage,
    bool? isLoading,
  }) {
    return PaginationInfo(
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int get totalPages => (totalItems / itemsPerPage).ceil();
  bool get isFirstPage => currentPage == 0;
  bool get isLastPage => !hasNextPage;

  @override
  List<Object> get props => [
    currentPage,
    itemsPerPage,
    totalItems,
    hasNextPage,
    isLoading,
  ];
}

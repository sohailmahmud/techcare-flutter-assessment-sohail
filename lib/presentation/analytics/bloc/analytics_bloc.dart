import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/category.dart';
import '../../transactions/bloc/transactions_bloc.dart';
import '../../../data/models/analytics_models.dart';

// Events
abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAnalytics extends AnalyticsEvent {
  const LoadAnalytics();
}

class ChangePeriod extends AnalyticsEvent {
  final TimePeriod period;
  final DateRange? customRange;

  const ChangePeriod(this.period, {this.customRange});

  @override
  List<Object?> get props => [period, customRange];
}

class RefreshAnalytics extends AnalyticsEvent {
  const RefreshAnalytics();
}

class UpdateTransactions extends AnalyticsEvent {
  final List<Transaction> transactions;

  const UpdateTransactions(this.transactions);

  @override
  List<Object> get props => [transactions];
}

// States
abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object> get props => [];
}

class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

class AnalyticsLoading extends AnalyticsState {
  const AnalyticsLoading();
}

class AnalyticsLoaded extends AnalyticsState {
  final AnalyticsData data;

  const AnalyticsLoaded(this.data);

  @override
  List<Object> get props => [data];
}

class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError(this.message);

  @override
  List<Object> get props => [message];
}

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final TransactionsBloc transactionsBloc;
  
  // Default budget amounts per category (in BDT)
  static const Map<String, double> _defaultBudgets = {
    'food': 15000.0,
    'transport': 8000.0,
    'entertainment': 5000.0,
    'healthcare': 10000.0,
    'shopping': 12000.0,
    'utilities': 6000.0,
    'education': 8000.0,
    'other': 5000.0,
  };

  AnalyticsBloc({required this.transactionsBloc}) : super(const AnalyticsInitial()) {
    on<LoadAnalytics>(_onLoadAnalytics);
    on<ChangePeriod>(_onChangePeriod);
    on<RefreshAnalytics>(_onRefreshAnalytics);
    on<UpdateTransactions>(_onUpdateTransactions);
  }

  Future<void> _onLoadAnalytics(LoadAnalytics event, Emitter<AnalyticsState> emit) async {
    emit(const AnalyticsLoading());
    
    try {
      final transactions = _getTransactionsFromBloc();
      final analyticsData = await _calculateAnalytics(
        transactions: transactions,
        period: TimePeriod.thisMonth,
      );
      
      emit(AnalyticsLoaded(analyticsData));
    } catch (e) {
      emit(AnalyticsError('Failed to load analytics: $e'));
    }
  }

  Future<void> _onChangePeriod(ChangePeriod event, Emitter<AnalyticsState> emit) async {
    if (state is AnalyticsLoaded) {
      emit(const AnalyticsLoading());
      
      try {
        final transactions = _getTransactionsFromBloc();
        final analyticsData = await _calculateAnalytics(
          transactions: transactions,
          period: event.period,
          customRange: event.customRange,
        );
        
        emit(AnalyticsLoaded(analyticsData));
      } catch (e) {
        emit(AnalyticsError('Failed to change period: $e'));
      }
    }
  }

  Future<void> _onRefreshAnalytics(RefreshAnalytics event, Emitter<AnalyticsState> emit) async {
    if (state is AnalyticsLoaded) {
      final currentData = (state as AnalyticsLoaded).data;
      
      try {
        final transactions = _getTransactionsFromBloc();
        final analyticsData = await _calculateAnalytics(
          transactions: transactions,
          period: currentData.timePeriod,
          customRange: currentData.timePeriod == TimePeriod.custom ? currentData.dateRange : null,
        );
        
        emit(AnalyticsLoaded(analyticsData));
      } catch (e) {
        emit(AnalyticsError('Failed to refresh analytics: $e'));
      }
    }
  }

  Future<void> _onUpdateTransactions(UpdateTransactions event, Emitter<AnalyticsState> emit) async {
    if (state is AnalyticsLoaded) {
      final currentData = (state as AnalyticsLoaded).data;
      
      try {
        final analyticsData = await _calculateAnalytics(
          transactions: event.transactions,
          period: currentData.timePeriod,
          customRange: currentData.timePeriod == TimePeriod.custom ? currentData.dateRange : null,
        );
        
        emit(AnalyticsLoaded(analyticsData));
      } catch (e) {
        emit(AnalyticsError('Failed to update analytics: $e'));
      }
    }
  }

  List<Transaction> _getTransactionsFromBloc() {
    final transactionsState = transactionsBloc.state;
    if (transactionsState is TransactionsLoaded) {
      return transactionsState.transactions;
    }
    return [];
  }

  Future<AnalyticsData> _calculateAnalytics({
    required List<Transaction> transactions,
    required TimePeriod period,
    DateRange? customRange,
  }) async {
    final dateRange = customRange ?? DateRangeUtils.getDateRangeForPeriod(period);
    final filteredTransactions = _filterTransactionsByDateRange(transactions, dateRange);
    
    // Calculate summary statistics
    final summary = await _calculateSummaryStatistics(
      currentTransactions: filteredTransactions,
      allTransactions: transactions,
      dateRange: dateRange,
    );
    
    // Generate trend data (last 6 months)
    final trendData = await _generateTrendData(transactions, dateRange);
    
    // Calculate category breakdown
    final categoryBreakdown = await _calculateCategoryBreakdown(filteredTransactions);
    
    // Calculate budget progress
    final budgetProgress = await _calculateBudgetProgress(filteredTransactions);
    
    return AnalyticsData(
      timePeriod: period,
      dateRange: dateRange,
      summary: summary,
      trendData: trendData,
      categoryBreakdown: categoryBreakdown,
      budgetProgress: budgetProgress,
      lastUpdated: DateTime.now(),
    );
  }

  List<Transaction> _filterTransactionsByDateRange(List<Transaction> transactions, DateRange dateRange) {
    return transactions.where((transaction) => dateRange.contains(transaction.date)).toList();
  }

  Future<SummaryStatistics> _calculateSummaryStatistics({
    required List<Transaction> currentTransactions,
    required List<Transaction> allTransactions,
    required DateRange dateRange,
  }) async {
    // Current period calculations
    final income = currentTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final expenses = currentTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final netBalance = income - expenses;

    // Previous period calculations for change percentages
    final previousRange = DateRangeUtils.getPreviousPeriod(dateRange);
    final previousTransactions = _filterTransactionsByDateRange(allTransactions, previousRange);
    
    final previousIncome = previousTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final previousExpenses = previousTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final previousBalance = previousIncome - previousExpenses;

    // Calculate percentage changes
    final incomeChange = _calculatePercentageChange(previousIncome, income);
    final expenseChange = _calculatePercentageChange(previousExpenses, expenses);
    final balanceChange = _calculatePercentageChange(previousBalance, netBalance);

    return SummaryStatistics(
      totalIncome: income,
      totalExpenses: expenses,
      netBalance: netBalance,
      incomeChange: incomeChange,
      expenseChange: expenseChange,
      balanceChange: balanceChange,
    );
  }

  double _calculatePercentageChange(double previousValue, double currentValue) {
    if (previousValue == 0) {
      return currentValue > 0 ? 100.0 : 0.0;
    }
    return ((currentValue - previousValue) / previousValue) * 100;
  }

  Future<List<TrendDataPoint>> _generateTrendData(
    List<Transaction> transactions,
    DateRange dateRange,
  ) async {
    // Generate 6 months of data ending with current period
    final endDate = dateRange.endDate;
    final startDate = DateTime(endDate.year, endDate.month - 6, endDate.day);
    
    final List<TrendDataPoint> trendData = [];
    
    // Group transactions by month
    final monthlyData = <String, List<Transaction>>{};
    
    for (final transaction in transactions) {
      if (transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(endDate.add(const Duration(days: 1)))) {
        final monthKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
        monthlyData.putIfAbsent(monthKey, () => []).add(transaction);
      }
    }
    
    // Generate data points for each month
    for (int i = 0; i < 6; i++) {
      final date = DateTime(endDate.year, endDate.month - (5 - i), 1);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final monthTransactions = monthlyData[monthKey] ?? [];
      
      final income = monthTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final expenses = monthTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      trendData.add(TrendDataPoint(
        date: date,
        income: income,
        expenses: expenses,
      ));
    }
    
    return trendData;
  }

  Future<List<CategorySpendingData>> _calculateCategoryBreakdown(
    List<Transaction> transactions,
  ) async {
    final expenseTransactions = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    
    if (expenseTransactions.isEmpty) {
      return [];
    }
    
    final totalExpenses = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);
    
    // Group by category
    final categoryData = <String, List<Transaction>>{};
    for (final transaction in expenseTransactions) {
      categoryData.putIfAbsent(transaction.categoryId, () => []).add(transaction);
    }
    
    final List<CategorySpendingData> breakdown = [];
    
    for (final entry in categoryData.entries) {
      final categoryTransactions = entry.value;
      final amount = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount);
      final percentage = (amount / totalExpenses) * 100;
      
      // Find category by ID
      final category = AppCategories.findById(entry.key);
      if (category != null) {
        breakdown.add(CategorySpendingData(
          category: category,
          amount: amount,
          percentage: percentage,
          transactionCount: categoryTransactions.length,
        ));
      }
    }
    
    // Sort by amount (descending)
    breakdown.sort((a, b) => b.amount.compareTo(a.amount));
    
    return breakdown;
  }

  Future<List<BudgetProgress>> _calculateBudgetProgress(
    List<Transaction> transactions,
  ) async {
    final expenseTransactions = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    
    // Group spending by category
    final categorySpending = <String, double>{};
    for (final transaction in expenseTransactions) {
      categorySpending[transaction.categoryId] = 
          (categorySpending[transaction.categoryId] ?? 0) + transaction.amount;
    }
    
    final List<BudgetProgress> budgetProgress = [];
    
    // Create budget progress for each category with spending
    for (final entry in categorySpending.entries) {
      final category = AppCategories.findById(entry.key);
      if (category != null) {
        final budgetAmount = _defaultBudgets[category.id.toLowerCase()] ?? 5000.0;
        final spentAmount = entry.value;
        
        budgetProgress.add(BudgetProgress.fromCategorySpending(
          category: category,
          budgetAmount: budgetAmount,
          spentAmount: spentAmount,
        ));
      }
    }
    
    // Also add categories with budget but no spending
    for (final budgetEntry in _defaultBudgets.entries) {
      if (!categorySpending.containsKey(budgetEntry.key)) {
        final category = AppCategories.findById(budgetEntry.key);
        if (category != null) {
          budgetProgress.add(BudgetProgress.fromCategorySpending(
            category: category,
            budgetAmount: budgetEntry.value,
            spentAmount: 0.0,
          ));
        }
      }
    }
    
    // Sort by percentage (descending)
    budgetProgress.sort((a, b) => b.percentage.compareTo(a.percentage));
    
    return budgetProgress;
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/transaction_filter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../domain/entities/transaction.dart' as tx;
import '../../../../domain/repositories/category_repository.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/transactions_bloc.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/transactions_list_view.dart';
import '../widgets/transaction_details_modal.dart';
import '../../form/pages/add_edit_transaction_screen.dart';
import '../../form/bloc/transaction_form_bloc.dart';
import 'cache_debug_screen.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load transactions when page is first created
    context.read<TransactionsBloc>().add(const LoadTransactions());
  }

  void _onSearchChanged(String query) {
    context.read<TransactionsBloc>().add(SearchTransactions(query));
  }

  void _onFilterTap() {
    final currentState = context.read<TransactionsBloc>().state;
    TransactionFilter currentFilter = const TransactionFilter();
    
    if (currentState is TransactionLoaded) {
      // Convert the current filters from the state to TransactionFilter
      currentFilter = _convertToTransactionFilter(currentState.currentFilters);
    }
    
    showFilterBottomSheet(
      context: context,
      currentFilter: currentFilter,
      categoryRepository: di.sl<CategoryRepository>(),
      onApplyFilters: (filter) {
        context.read<TransactionsBloc>().add(
          FilterTransactions(_convertToFiltersMap(filter)),
        );
      },
      onClearFilters: () {
        // Clear filters by applying empty filter
        context.read<TransactionsBloc>().add(const FilterTransactions({}));
      },
    );
  }

  TransactionFilter _convertToTransactionFilter(Map<String, dynamic>? filters) {
    if (filters == null) return const TransactionFilter();
    
    return TransactionFilter(
      selectedCategories: List<String>.from(filters['categories'] ?? []),
      transactionType: _parseTransactionType(filters['type']),
      dateRange: filters['dateRange'] as DateRange?,
      amountRange: filters['amountRange'] as AmountRange?,
    );
  }

  TransactionType _parseTransactionType(String? type) {
    switch (type) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      default:
        return TransactionType.all;
    }
  }

  Map<String, dynamic> _convertToFiltersMap(TransactionFilter filter) {
    final Map<String, dynamic> filtersMap = {};
    
    if (filter.selectedCategories.isNotEmpty) {
      filtersMap['categories'] = filter.selectedCategories;
    }
    if (filter.transactionType != TransactionType.all) {
      filtersMap['type'] = filter.transactionType.name;
    }
    if (filter.dateRange != null) {
      filtersMap['dateRange'] = filter.dateRange;
    }
    if (filter.amountRange != null) {
      filtersMap['amountRange'] = filter.amountRange;
    }
    
    return filtersMap;
  }

  void _onLoadMore() {
    final currentState = context.read<TransactionsBloc>().state;
    if (currentState is TransactionLoaded) {
      context.read<TransactionsBloc>().add(LoadTransactions(page: currentState.currentPage + 1));
    }
  }

  void _onRefresh() {
    context.read<TransactionsBloc>().add(const RefreshTransactions());
  }

  void _onTransactionTap(tx.Transaction transaction) {
    _showTransactionDetails(transaction);
  }

  void _onEditTransaction(tx.Transaction transaction) {
    _showEditTransaction(transaction);
  }

  void _onDeleteTransaction(tx.Transaction transaction) {
    context.read<TransactionsBloc>().add(DeleteTransaction(transaction.id));
  }

  void _showTransactionDetails(tx.Transaction transaction) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        pageBuilder: (context, animation, secondaryAnimation) => 
            TransactionDetailsModal(
              transaction: transaction,
              heroTag: 'transaction_amount_${transaction.id}_transactions_page',
            ),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  void _showEditTransaction(tx.Transaction transaction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit "${transaction.title}" - Feature coming soon!'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Transactions',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            // Debug button (only show in debug mode)
            if (const bool.fromEnvironment('dart.vm.product') == false)
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CacheDebugScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bug_report_outlined),
                tooltip: 'Cache Debug',
                color: AppColors.textSecondary,
              ),
            BlocBuilder<TransactionsBloc, TransactionsState>(
              builder: (context, state) {
                if (state is TransactionLoaded) {
                  return IconButton(
                    onPressed: _onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    color: AppColors.textSecondary,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      body: BlocBuilder<TransactionsBloc, TransactionsState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildSearchBar(state),
              Expanded(
                child: _buildContent(state),
              ),
            ],
          );
        },
      ),
        floatingActionButton: FloatingActionButton(
          heroTag: "add_transaction_fab",
          onPressed: _showAddTransaction,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget _buildSearchBar(TransactionsState state) {
    String currentQuery = '';
    int activeFilterCount = 0;
    bool isSearching = false;

    if (state is TransactionLoaded) {
      currentQuery = state.searchQuery ?? '';
      activeFilterCount = state.currentFilters?.length ?? 0;
    }

    return TransactionSearchBar(
      initialQuery: currentQuery,
      onSearchChanged: _onSearchChanged,
      onFilterTap: () => _onFilterTap(),
      activeFilterCount: activeFilterCount,
      isLoading: isSearching,
    );
  }

  Widget _buildContent(TransactionsState state) {
    if (state is TransactionLoading) {
      return const TransactionListSkeleton();
    }

    if (state is TransactionError) {
      return _buildErrorState(state);
    }

    if (state is TransactionLoaded) {
      return RefreshIndicator(
        onRefresh: () async {
          _onRefresh();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: TransactionsListView(
          transactions: state.transactions,
          isLoading: false,
          hasNextPage: state.hasMore,
          onLoadMore: _onLoadMore,
          onTransactionTap: _onTransactionTap,
          onEdit: _onEditTransaction,
          onDelete: _onDeleteTransaction,
        ),
      );
    }

    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(TransactionError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withAlpha(25),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: Spacing.space20),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Spacing.space8),
            Text(
              state.error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.space24),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.space24,
                  vertical: Spacing.space12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTransaction() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            BlocProvider(
              create: (context) => TransactionFormBloc(
                transactionsBloc: context.read<TransactionsBloc>(),
              ),
              child: const AddEditTransactionScreen(),
            ),
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
}



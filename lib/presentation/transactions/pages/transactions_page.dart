import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/transaction.dart' as tx;
import '../../../domain/entities/transaction_filter.dart';
import '../bloc/transactions_bloc.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/transactions_list_view.dart';

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

  void _onFilterTap(TransactionFilter currentFilter) {
    showFilterBottomSheet(
      context: context,
      currentFilter: currentFilter,
      onApplyFilters: (filter) {
        context.read<TransactionsBloc>().add(ApplyFilters(filter));
      },
      onClearFilters: () {
        context.read<TransactionsBloc>().add(const ClearFilters());
      },
    );
  }

  void _onLoadMore() {
    context.read<TransactionsBloc>().add(const LoadMoreTransactions());
  }

  void _onRefresh() {
    context.read<TransactionsBloc>().add(const LoadTransactions(refresh: true));
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TransactionDetailsSheet(transaction: transaction),
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
            BlocBuilder<TransactionsBloc, TransactionsState>(
              builder: (context, state) {
                if (state is TransactionsLoaded) {
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
    TransactionFilter currentFilter = const TransactionFilter();

    if (state is TransactionsLoaded) {
      currentQuery = state.currentFilter.searchQuery;
      activeFilterCount = state.currentFilter.activeFilterCount;
      isSearching = state.isSearching;
      currentFilter = state.currentFilter;
    }

    return TransactionSearchBar(
      initialQuery: currentQuery,
      onSearchChanged: _onSearchChanged,
      onFilterTap: () => _onFilterTap(currentFilter),
      activeFilterCount: activeFilterCount,
      isLoading: isSearching,
    );
  }

  Widget _buildContent(TransactionsState state) {
    if (state is TransactionsLoading) {
      return const TransactionListSkeleton();
    }

    if (state is TransactionsError) {
      return _buildErrorState(state);
    }

    if (state is TransactionsLoaded) {
      return RefreshIndicator(
        onRefresh: () async {
          _onRefresh();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: TransactionsListView(
          transactions: state.transactions,
          isLoading: state.paginationInfo.isLoading,
          hasNextPage: state.paginationInfo.hasNextPage,
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

  Widget _buildErrorState(TransactionsError state) {
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
              state.message,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Add Transaction - Feature coming soon!'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }
}

class _TransactionDetailsSheet extends StatelessWidget {
  final tx.Transaction transaction;

  const _TransactionDetailsSheet({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(Spacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: Spacing.space12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getTransactionColor().withAlpha(25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        transaction.isIncome 
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: _getTransactionColor(),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: Spacing.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormatter.formatDisplay(transaction.date)} • ${DateFormatter.formatTime(transaction.date)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(153),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.space24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Spacing.space20),
                  decoration: BoxDecoration(
                    color: _getTransactionColor().withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getTransactionColor().withAlpha(51),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        transaction.isIncome ? 'Income' : 'Expense',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _getTransactionColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(transaction.amount.abs()),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: _getTransactionColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.space20),
                _buildDetailRow('Category', transaction.categoryName),
                if (transaction.notes != null && transaction.notes!.isNotEmpty)
                  _buildDetailRow('Notes', transaction.notes!),
                _buildDetailRow('Transaction ID', transaction.id),
                const SizedBox(height: Spacing.space24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.space12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTransactionColor() {
    return transaction.isIncome ? Colors.green : Colors.red;
  }
}

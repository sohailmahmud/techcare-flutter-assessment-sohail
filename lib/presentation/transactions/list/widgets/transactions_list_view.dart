import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../domain/entities/transaction.dart' as tx;
import '../bloc/transactions_bloc.dart';

class TransactionsListView extends StatefulWidget {
  final List<tx.Transaction> transactions;
  final bool isLoading;
  final bool hasNextPage;
  final VoidCallback? onLoadMore;
  final Function(tx.Transaction)? onTransactionTap;
  final Function(tx.Transaction)? onEdit;
  final Function(tx.Transaction)? onDelete;
  final String heroTagPrefix;

  const TransactionsListView({
    super.key,
    required this.transactions,
    this.isLoading = false,
    this.hasNextPage = false,
    this.onLoadMore,
    this.onTransactionTap,
    this.onEdit,
    this.onDelete,
    this.heroTagPrefix = 'transactions_page',
  });

  @override
  State<TransactionsListView> createState() => _TransactionsListViewState();
}

class _TransactionsListViewState extends State<TransactionsListView> {
  late ScrollController _scrollController;
  final double _scrollThreshold = 200.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasNextPage || widget.isLoading) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= _scrollThreshold) {
      widget.onLoadMore?.call();
    }
  }

  Map<String, List<tx.Transaction>> _groupTransactionsByDate(
    List<tx.Transaction> transactions,
  ) {
    final Map<String, List<tx.Transaction>> grouped = {};

    for (final transaction in transactions) {
      final dateKey = DateFormatter.formatDateGrouping(transaction.date);
      if (grouped[dateKey] == null) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }

    return grouped;
  }

  int _getTotalItemCount(
    Map<String, List<tx.Transaction>> groupedTransactions,
  ) {
    int count = 0;
    for (final entry in groupedTransactions.entries) {
      count += 1; // Header
      count += entry.value.length; // Transactions
    }
    return count;
  }

  Widget _buildGroupedTransactions(
    Map<String, List<tx.Transaction>> groupedTransactions,
    int globalIndex,
  ) {
    int currentIndex = 0;

    for (final entry in groupedTransactions.entries) {
      final dateKey = entry.key;
      final transactions = entry.value;

      // Check if this is a header
      if (currentIndex == globalIndex) {
        return _buildDateHeader(dateKey, transactions);
      }
      currentIndex++;

      // Check if this is a transaction within this group
      for (int i = 0; i < transactions.length; i++) {
        if (currentIndex == globalIndex) {
          return _buildTransactionItem(transactions[i], i);
        }
        currentIndex++;
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildDateHeader(String dateKey, List<tx.Transaction> transactions) {
    return Container(
      padding: const EdgeInsets.only(
        top: Spacing.space16,
        bottom: Spacing.space8,
        left: Spacing.space0,
        right: Spacing.space16,
      ),
      child: Row(
        children: [
          Text(
            dateKey,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty && !widget.isLoading) {
      return _buildEmptyState();
    }

    final groupedTransactions = _groupTransactionsByDate(widget.transactions);

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(
            top: Spacing.space8,
            left: Spacing.space16,
            right: Spacing.space16,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return _buildGroupedTransactions(groupedTransactions, index);
            }, childCount: _getTotalItemCount(groupedTransactions)),
          ),
        ),
        if (widget.hasNextPage)
          SliverToBoxAdapter(child: _buildLoadingIndicator()),
        const SliverPadding(padding: EdgeInsets.only(bottom: Spacing.space24)),
      ],
    );
  }

  Widget _buildTransactionItem(tx.Transaction transaction, int index) {
    final isIncome = transaction.type == tx.TransactionType.income;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.space8),
      child: Dismissible(
        key: Key(transaction.id),
        background: _buildSwipeBackground(isLeft: true),
        secondaryBackground: _buildSwipeBackground(isLeft: false),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            // Delete action
            return await _showDeleteConfirmation(transaction);
          }
          if (direction == DismissDirection.startToEnd) {
            // Edit action
            widget.onEdit?.call(transaction);
            return false; // Don't dismiss
          }
          return false;
        },
        child: GestureDetector(
          onTap: () => widget.onTransactionTap?.call(transaction),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Spacing.radiusM),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Transaction icon
                _buildTransactionIcon(transaction),
                const SizedBox(width: 16),

                // Transaction details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            transaction.categoryName,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (transaction.notes?.isNotEmpty == true) ...[
                            Text(
                              ' • ',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                transaction.notes!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Hero(
                      tag:
                          'transaction_amount_${transaction.id}_${widget.heroTagPrefix}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                          style: AppTypography.bodyLarge.copyWith(
                            color: isIncome
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.formatTime(transaction.date),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionIcon(tx.Transaction transaction) {
    final category = transaction.category;
    return Container(
      width: Spacing.transactionIconSize,
      height: Spacing.transactionIconSize,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Spacing.radiusM),
      ),
      child: Icon(
        category.icon,
        color: category.color,
        size: Spacing.transactionIconSize / 2,
      ),
    );
  }

  Widget _buildSwipeBackground({required bool isLeft}) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.space8),
      decoration: BoxDecoration(
        color: isLeft ? Colors.blue : Colors.red,
        borderRadius: BorderRadius.circular(Spacing.radiusM),
      ),
      child: Align(
        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.space20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLeft ? Icons.edit_rounded : Icons.delete_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                isLeft ? 'Edit' : 'Delete',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(tx.Transaction transaction) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete "${transaction.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      widget.onDelete?.call(transaction);
    }

    return result ?? false;
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(Spacing.space20),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: Spacing.space12),
          Text(
            'Loading more transactions...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: Spacing.space20),
            Text(
              'No Transactions Found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Spacing.space8),
            Text(
              'Try adjusting your search or filters to find what you\'re looking for.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.space24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<TransactionsBloc>().add(
                  const FilterTransactions({}),
                );
              },
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Clear Filters'),
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
}

// Transaction loading skeleton
class TransactionListSkeleton extends StatelessWidget {
  final int itemCount;

  const TransactionListSkeleton({super.key, this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.space16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.space12),
          child: Container(
            padding: const EdgeInsets.all(Spacing.space16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Spacing.radiusM),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              spacing: Spacing.space12,
              children: [
                // Icon skeleton
                const SkeletonLoader(
                  width: Spacing.transactionIconSize,
                  height: Spacing.transactionIconSize,
                  borderRadius: Spacing.radiusM,
                ),

                // Content skeleton
                Expanded(
                  child: Column(
                    spacing: Spacing.space8,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: 15,
                      ),
                      SkeletonLoader(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: 15,
                      ),
                    ],
                  ),
                ),

                // Amount skeleton
                const Column(
                  spacing: Spacing.space8,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SkeletonLoader(width: 50, height: 15),
                    SkeletonLoader(width: 60, height: 15),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

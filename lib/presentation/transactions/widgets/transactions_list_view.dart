import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../domain/entities/transaction.dart' as tx;
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

  Map<String, List<tx.Transaction>> _groupTransactionsByDate(List<tx.Transaction> transactions) {
    final Map<String, List<tx.Transaction>> grouped = {};
    
    for (final transaction in transactions) {
      final dateKey = _getDateKey(transaction.date);
      if (grouped[dateKey] == null) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }
    
    return grouped;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);
    
    if (transactionDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (transactionDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormatter.formatDisplay(date);
    }
  }

  int _getTotalItemCount(Map<String, List<tx.Transaction>> groupedTransactions) {
    int count = 0;
    for (final entry in groupedTransactions.entries) {
      count += 1; // Header
      count += entry.value.length; // Transactions
    }
    return count;
  }

  Widget _buildGroupedTransactions(Map<String, List<tx.Transaction>> groupedTransactions, int globalIndex) {
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
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.space16,
        vertical: Spacing.space8,
      ),
      child: Row(
        children: [
          Text(
            dateKey,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
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
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildGroupedTransactions(groupedTransactions, index);
              },
              childCount: _getTotalItemCount(groupedTransactions),
            ),
          ),
        ),
        if (widget.hasNextPage)
          SliverToBoxAdapter(
            child: _buildLoadingIndicator(),
          ),
        const SliverPadding(
          padding: EdgeInsets.only(bottom: Spacing.space24),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(tx.Transaction transaction, int index) {
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
          } else if (direction == DismissDirection.startToEnd) {
            // Edit action
            widget.onEdit?.call(transaction);
            return false; // Don't dismiss
          }
          return false;
        },
        child: GestureDetector(
          onTap: () => widget.onTransactionTap?.call(transaction),
          child: Container(
            padding: const EdgeInsets.all(Spacing.space16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Spacing.radiusM),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Transaction icon
                _buildTransactionIcon(transaction),
                const SizedBox(width: Spacing.space12),
                
                // Transaction details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (transaction.notes != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          transaction.notes!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.space8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(transaction.categoryName).withAlpha(51),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              transaction.categoryName,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: _getCategoryColor(transaction.categoryName),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: Spacing.space8),
                          Text(
                            DateFormatter.formatDisplay(transaction.date),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Hero(
                      tag: 'transaction_amount_${transaction.id}_${widget.heroTagPrefix}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          CurrencyFormatter.format(transaction.amount.abs()),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: transaction.isIncome 
                                ? Colors.green[600]
                                : Colors.red[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.space4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: transaction.isIncome 
                            ? Colors.green.withAlpha(51)
                            : Colors.red.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transaction.isIncome ? 'Income' : 'Expense',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: transaction.isIncome 
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
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
    IconData iconData;
    Color iconColor;

    // Map categories to icons
    switch (transaction.categoryName.toLowerCase()) {
      case 'food':
        iconData = Icons.restaurant_rounded;
        iconColor = Colors.orange;
        break;
      case 'transport':
        iconData = Icons.directions_car_rounded;
        iconColor = Colors.blue;
        break;
      case 'shopping':
        iconData = Icons.shopping_bag_rounded;
        iconColor = Colors.purple;
        break;
      case 'bills':
        iconData = Icons.receipt_long_rounded;
        iconColor = Colors.red;
        break;
      case 'entertainment':
        iconData = Icons.movie_rounded;
        iconColor = Colors.pink;
        break;
      case 'health':
        iconData = Icons.local_hospital_rounded;
        iconColor = Colors.green;
        break;
      case 'salary':
        iconData = Icons.work_rounded;
        iconColor = Colors.indigo;
        break;
      case 'freelance':
        iconData = Icons.laptop_rounded;
        iconColor = Colors.teal;
        break;
      case 'investment':
        iconData = Icons.trending_up_rounded;
        iconColor = Colors.amber;
        break;
      case 'education':
        iconData = Icons.school_rounded;
        iconColor = Colors.deepPurple;
        break;
      default:
        iconData = transaction.isIncome 
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;
        iconColor = transaction.isIncome ? Colors.green : Colors.red;
    }

    return Container(
      width: Spacing.transactionIconSize,
      height: Spacing.transactionIconSize,
      decoration: BoxDecoration(
        color: iconColor.withAlpha(25),
        borderRadius: BorderRadius.circular(Spacing.radiusM),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Color _getCategoryColor(String category) {
    // Same color mapping as icon
    switch (category.toLowerCase()) {
      case 'food': return Colors.orange;
      case 'transport': return Colors.blue;
      case 'shopping': return Colors.purple;
      case 'bills': return Colors.red;
      case 'entertainment': return Colors.pink;
      case 'health': return Colors.green;
      case 'salary': return Colors.indigo;
      case 'freelance': return Colors.teal;
      case 'investment': return Colors.amber;
      case 'education': return Colors.deepPurple;
      default: return Theme.of(context).colorScheme.primary;
    }
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
        content: Text('Are you sure you want to delete "${transaction.title}"?'),
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                context.read<TransactionsBloc>().add(const FilterTransactions({}));
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

  const TransactionListSkeleton({
    super.key,
    this.itemCount = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.space16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.space8),
          child: Container(
            padding: const EdgeInsets.all(Spacing.space16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Spacing.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Icon skeleton
                SkeletonLoader(
                  width: Spacing.transactionIconSize,
                  height: Spacing.transactionIconSize,
                  borderRadius: Spacing.radiusM,
                ),
                const SizedBox(width: Spacing.space12),
                
                // Content skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonLoader(
                        width: double.infinity,
                        height: 16,
                      ),
                      const SizedBox(height: 4),
                      SkeletonLoader(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: 12,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SkeletonLoader(
                            width: 60,
                            height: 16,
                          ),
                          const SizedBox(width: Spacing.space8),
                          const SkeletonLoader(
                            width: 80,
                            height: 12,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Amount skeleton
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SkeletonLoader(
                      width: 80,
                      height: 16,
                    ),
                    SizedBox(height: 4),
                    SkeletonLoader(
                      width: 50,
                      height: 16,
                    ),
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
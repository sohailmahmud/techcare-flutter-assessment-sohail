import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/transaction.dart';

/// Enhanced recent transactions list with swipe gestures and grouping
class TransactionsList extends StatefulWidget {
  final List<Transaction> transactions;
  final Function(String)? onEdit;
  final Function(String)? onDelete;
  final VoidCallback? onViewAll;
  final bool isLoading;

  const TransactionsList({
    super.key,
    required this.transactions,
    this.onEdit,
    this.onDelete,
    this.onViewAll,
    this.isLoading = false,
  });

  @override
  State<TransactionsList> createState() => _TransactionsListState();
}

class _TransactionsListState extends State<TransactionsList>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  late Animation<double> _listAnimation;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: AppConstants.listItemAnimation,
      vsync: this,
    );
    _listAnimation = CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.easeOutCubic,
    );
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassMorphicContainer(
      padding: const EdgeInsets.all(Spacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (widget.isLoading)
            _buildLoadingList()
          else if (widget.transactions.isEmpty)
            _buildEmptyState()
          else
            _buildTransactionsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Transactions',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        if (widget.transactions.isNotEmpty)
          GestureDetector(
            onTap: widget.onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingList() {
    return Column(
      children: List.generate(
        5,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index < 4 ? 12.0 : 0),
          child: DashboardSkeletonLoaders.transactionItem(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Transactions Yet',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your recent transactions will appear here',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    final groupedTransactions = _groupTransactionsByDate();
    
    return AnimatedBuilder(
      animation: _listAnimation,
      builder: (context, child) {
        return Column(
          children: groupedTransactions.entries.map((entry) {
            final date = entry.key;
            final transactions = entry.value;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateHeader(date),
                const SizedBox(height: 8),
                ...transactions.asMap().entries.map((transactionEntry) {
                  final index = transactionEntry.key;
                  final transaction = transactionEntry.value;
                  
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _listAnimation,
                      curve: Interval(
                        index * 0.1,
                        1.0,
                        curve: Curves.easeOutCubic,
                      ),
                    )),
                    child: _buildTransactionItem(transaction),
                  );
                }).toList(),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Map<String, List<Transaction>> _groupTransactionsByDate() {
    final Map<String, List<Transaction>> grouped = {};
    
    for (final transaction in widget.transactions.take(Spacing.maxRecentTransactions)) {
      final dateKey = DateFormatter.formatDateGrouping(transaction.date);
      grouped.putIfAbsent(dateKey, () => []).add(transaction);
    }
    
    return grouped;
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        date,
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isIncome = transaction.type == TransactionType.income;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(transaction.id),
        background: _buildSwipeBackground(
          color: AppColors.primary,
          icon: Icons.edit,
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: _buildSwipeBackground(
          color: AppColors.error,
          icon: Icons.delete,
          alignment: Alignment.centerRight,
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            widget.onEdit?.call(transaction.id);
            return false;
          } else if (direction == DismissDirection.endToStart) {
            return await _showDeleteConfirmation(transaction);
          }
          return false;
        },
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
              _buildTransactionIcon(transaction, isIncome),
              const SizedBox(width: 16),
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
                  Text(
                    '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                    style: AppTypography.bodyLarge.copyWith(
                      color: isIncome ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildTransactionIcon(Transaction transaction, bool isIncome) {
    return Container(
      width: Spacing.transactionIconSize,
      height: Spacing.transactionIconSize,
      decoration: BoxDecoration(
        color: isIncome
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Spacing.transactionIconSize / 2),
      ),
      child: Icon(
        _getTransactionIcon(transaction.categoryId),
        color: isIncome ? AppColors.success : AppColors.error,
        size: Spacing.transactionIconSize / 2,
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Spacing.radiusM),
      ),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(Transaction transaction) async {
    return await showDialog<bool>(
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
            onPressed: () {
              Navigator.of(context).pop(true);
              widget.onDelete?.call(transaction.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  IconData _getTransactionIcon(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.electrical_services;
      case 'healthcare':
        return Icons.local_hospital;
      case 'salary':
        return Icons.work;
      case 'freelance':
        return Icons.computer;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/transaction.dart' as tx;

/// Enhanced recent transactions list with lazy loading and swipe gestures
class RecentTransactionsList extends StatefulWidget {
  final List<tx.Transaction> transactions;
  final Function(tx.Transaction)? onEdit;
  final Function(tx.Transaction)? onDelete;
  final Function(tx.Transaction)? onTransactionTap;
  final VoidCallback? onViewAll;
  final bool isLoading;
  final int? maxItems; // Optional limit for dashboard view
  final bool enableLazyLoading; // Enable lazy loading for large datasets

  const RecentTransactionsList({
    super.key,
    required this.transactions,
    this.onEdit,
    this.onDelete,
    this.onTransactionTap,
    this.onViewAll,
    this.isLoading = false,
    this.maxItems,
    this.enableLazyLoading = false,
  });

  @override
  State<RecentTransactionsList> createState() => _RecentTransactionsListState();
}

class _RecentTransactionsListState extends State<RecentTransactionsList>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  late Animation<double> _listAnimation;

  // Lazy loading state
  int _displayedItemsCount = 5;
  final int _itemsPerPage = 10;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

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

    // Set up lazy loading
    if (widget.enableLazyLoading) {
      _displayedItemsCount = _itemsPerPage;
      _scrollController.addListener(_onScroll);
    } else {
      _displayedItemsCount =
          widget.maxItems ?? AppConstants.maxRecentTransactions;
    }
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _displayedItemsCount < widget.transactions.length) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate loading delay for smooth UX
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _displayedItemsCount = (_displayedItemsCount + _itemsPerPage).clamp(
            0,
            widget.transactions.length,
          );
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassMorphicContainer(
      padding: const EdgeInsets.symmetric(vertical: Spacing.space16),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    if (widget.enableLazyLoading) {
      return _buildLazyLoadingList();
    } else {
      return _buildStandardList();
    }
  }

  Widget _buildStandardList() {
    final groupedTransactions = _groupTransactionsByDate();

    return AnimatedBuilder(
      animation: _listAnimation,
      builder: (context, child) {
        return Column(
          children: groupedTransactions.entries
              .map((entry) => _buildTransactionGroup(entry.key, entry.value))
              .toList(),
        );
      },
    );
  }

  Widget _buildTransactionGroup(
    String date,
    List<tx.Transaction> transactions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateHeader(date),
        const SizedBox(height: 8),
        ...transactions.asMap().entries.map((transactionEntry) {
          final index = transactionEntry.key;
          final transaction = transactionEntry.value;
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: _listAnimation,
                    curve: Interval(
                      index * 0.1,
                      1.0,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
            child: _buildTransactionItem(transaction),
          );
        }).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Builds a lazy-loading ListView for large transaction datasets
  Widget _buildLazyLoadingList() {
    final displayedTransactions = widget.transactions
        .take(_displayedItemsCount)
        .toList();
    final groupedTransactions = _groupTransactionsByDate(displayedTransactions);

    // Calculate total items for ListView (groups + transactions + loading indicator)
    int totalItems = 0;
    for (final entry in groupedTransactions.entries) {
      totalItems += 1; // Date header
      totalItems += entry.value.length; // Transactions
    }
    if (_isLoadingMore) totalItems += 1; // Loading indicator

    return SizedBox(
      height: 400, // Fixed height for lazy loading
      child: ListView.builder(
        controller: _scrollController,
        itemCount: totalItems,
        itemBuilder: (context, index) {
          int currentIndex = 0;

          for (final entry in groupedTransactions.entries) {
            final date = entry.key;
            final transactions = entry.value;

            // Date header
            if (index == currentIndex) {
              currentIndex++;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildDateHeader(date),
              );
            }
            currentIndex++;

            // Transaction items
            for (int i = 0; i < transactions.length; i++) {
              if (index == currentIndex) {
                currentIndex++;
                return AnimatedBuilder(
                  animation: _listAnimation,
                  builder: (context, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _listAnimation,
                              curve: Interval(
                                i * 0.05,
                                1.0,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                          ),
                      child: _buildTransactionItem(transactions[i]),
                    );
                  },
                );
              }
              currentIndex++;
            }
          }

          // Loading indicator
          if (_isLoadingMore && index == totalItems - 1) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Map<String, List<tx.Transaction>> _groupTransactionsByDate([
    List<tx.Transaction>? transactions,
  ]) {
    final Map<String, List<tx.Transaction>> grouped = {};
    final List<tx.Transaction> transactionsToGroup =
        transactions ??
        widget.transactions
            .take(widget.maxItems ?? AppConstants.maxRecentTransactions)
            .toList();

    for (final transaction in transactionsToGroup) {
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

  Widget _buildTransactionItem(tx.Transaction transaction) {
    final isIncome = transaction.type == tx.TransactionType.income;

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
                _buildTransactionIcon(transaction),
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
      ),
    );
  }

  Widget _buildTransactionIcon(tx.Transaction transaction) {
    return Container(
      width: Spacing.transactionIconSize,
      height: Spacing.transactionIconSize,
      decoration: BoxDecoration(
        color: transaction.category.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Spacing.radiusM),
      ),
      child: Icon(
        transaction.category.icon,
        color: transaction.category.color,
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
          child: Icon(icon, color: Colors.white, size: 24),
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
}

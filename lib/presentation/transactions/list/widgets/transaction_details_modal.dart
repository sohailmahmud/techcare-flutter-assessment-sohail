import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/transaction.dart' as tx;
import '../../form/pages/add_edit_transaction_screen.dart';
import '../bloc/transactions_bloc.dart';

/// Comprehensive Transaction Details Modal
/// Features:
/// - Large amount display with hero animation
/// - Category badge with icon
/// - Transaction type indicator
/// - Date and time formatting
/// - Full description text
/// - Edit and Delete action buttons
/// - Swipe-to-dismiss gesture
/// - Delete confirmation dialog
class TransactionDetailsModal extends StatefulWidget {
  final tx.Transaction transaction;
  final String? heroTag;

  const TransactionDetailsModal({
    super.key,
    required this.transaction,
    this.heroTag,
  });

  @override
  State<TransactionDetailsModal> createState() => _TransactionDetailsModalState();
}

class _TransactionDetailsModalState extends State<TransactionDetailsModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismissModal() {
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    // Convert drag distance to animation progress
    final screenHeight = MediaQuery.of(context).size.height;
    final dragDistance = details.primaryDelta! / screenHeight;
    
    if (dragDistance > 0) {
      // Only allow downward swipes
      final newValue = (_animationController.value - dragDistance * 2).clamp(0.0, 1.0);
      _animationController.value = newValue;
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    
    if (velocity > 500 || _animationController.value < 0.5) {
      // Dismiss if swiped fast or dragged more than halfway
      _dismissModal();
    } else {
      // Snap back to original position
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissModal,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        body: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, MediaQuery.of(context).size.height * _slideAnimation.value),
                child: GestureDetector(
                  onTap: () {}, // Prevent dismissal when tapping modal content
                  onVerticalDragUpdate: _onVerticalDragUpdate,
                  onVerticalDragEnd: _onVerticalDragEnd,
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.85,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Drag handle
                            Container(
                              margin: const EdgeInsets.only(top: Spacing.space12),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: scrollController,
                                padding: const EdgeInsets.all(Spacing.space24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildHeader(),
                                    const SizedBox(height: Spacing.space32),
                                    _buildAmountDisplay(),
                                    const SizedBox(height: Spacing.space24),
                                    _buildCategoryBadge(),
                                    const SizedBox(height: Spacing.space24),
                                    _buildTransactionDetails(),
                                    const SizedBox(height: Spacing.space32),
                                    _buildActionButtons(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _getTransactionColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            widget.transaction.isIncome 
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
                widget.transaction.title,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormatter.formatDisplay(widget.transaction.date)} • ${DateFormatter.formatTime(widget.transaction.date)}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountDisplay() {
    final heroTag = widget.heroTag ?? 'transaction_amount_${widget.transaction.id}';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.space24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getTransactionColor().withValues(alpha: 0.1),
            _getTransactionColor().withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getTransactionColor().withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.space12,
              vertical: Spacing.space8,
            ),
            decoration: BoxDecoration(
              color: _getTransactionColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.transaction.isIncome ? 'INCOME' : 'EXPENSE',
              style: AppTypography.labelMedium.copyWith(
                color: _getTransactionColor(),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: Spacing.space16),
          Hero(
            tag: heroTag,
            child: Material(
              color: Colors.transparent,
              child: Text(
                CurrencyFormatter.format(widget.transaction.amount.abs()),
                style: AppTypography.displayMedium.copyWith(
                  color: _getTransactionColor(),
                  fontWeight: FontWeight.w800,
                  fontSize: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge() {
    final category = AppCategories.findById(widget.transaction.categoryId);
    
    return Container(
      padding: const EdgeInsets.all(Spacing.space16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          if (category != null) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 24,
              ),
            ),
            const SizedBox(width: Spacing.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category.name,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.category_outlined,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: Spacing.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.transaction.categoryName,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Details',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.space16),
        _buildDetailRow(
          'Date & Time',
          '${DateFormatter.formatDisplay(widget.transaction.date)}\n${DateFormatter.formatTime(widget.transaction.date)}',
          Icons.schedule_outlined,
        ),
        _buildDetailRow(
          'Transaction ID',
          widget.transaction.id,
          Icons.tag_outlined,
        ),
        if (widget.transaction.notes != null && widget.transaction.notes!.isNotEmpty)
          _buildDetailRow(
            'Description',
            widget.transaction.notes!,
            Icons.description_outlined,
            isExpandable: true,
          ),
        _buildDetailRow(
          'Created',
          DateFormatter.formatDisplay(widget.transaction.createdAt ?? widget.transaction.date),
          Icons.access_time_outlined,
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isExpandable = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.space12),
      padding: const EdgeInsets.all(Spacing.space16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: Spacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _editTransaction,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Transaction'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: Spacing.space12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showDeleteConfirmation,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.space12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _dismissModal,
            child: Text(
              'Close',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _editTransaction() {
    Navigator.of(context).pop(); // Close modal first
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            AddEditTransactionScreen(transaction: widget.transaction),
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        transaction: widget.transaction,
        onConfirm: _deleteTransaction,
      ),
    );
  }

  void _deleteTransaction() {
    // Close the confirmation dialog
    Navigator.of(context).pop();
    
    // Dispatch delete event
    context.read<TransactionsBloc>().add(
      DeleteTransaction(widget.transaction.id),
    );
    
    // Close the modal
    _dismissModal();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.transaction.title} deleted successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(Spacing.space16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Color _getTransactionColor() {
    return widget.transaction.isIncome 
        ? AppColors.success 
        : AppColors.error;
  }
}

/// Delete Confirmation Dialog
class DeleteConfirmationDialog extends StatelessWidget {
  final tx.Transaction transaction;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.transaction,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_outlined,
              color: Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: Spacing.space12),
          Expanded(
            child: Text(
              'Delete Transaction',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete this transaction?',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: Spacing.space16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spacing.space16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
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
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(transaction.amount.abs()),
                  style: AppTypography.bodyMedium.copyWith(
                    color: transaction.isIncome 
                        ? AppColors.success 
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.formatDisplay(transaction.date),
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.space16),
          Text(
            'This action cannot be undone.',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.space20,
              vertical: Spacing.space12,
            ),
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
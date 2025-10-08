import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/spacing.dart';
import '../../../domain/entities/transaction.dart';

/// Animated toggle switch for transaction type selection
class TransactionTypeSelector extends StatefulWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onChanged;

  const TransactionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  State<TransactionTypeSelector> createState() => _TransactionTypeSelectorState();
}

class _TransactionTypeSelectorState extends State<TransactionTypeSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Set initial state
    if (widget.selectedType == TransactionType.income) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TransactionTypeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedType != oldWidget.selectedType) {
      if (widget.selectedType == TransactionType.income) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _onTypeSelected(TransactionType type) {
    if (type != widget.selectedType) {
      widget.onChanged(type);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Spacing.radiusL),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return GestureDetector(
                    onTap: () => _onTypeSelected(TransactionType.expense),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: widget.selectedType == TransactionType.expense
                            ? AppColors.expense
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(Spacing.radiusM),
                        boxShadow: widget.selectedType == TransactionType.expense
                            ? [
                                BoxShadow(
                                  color: AppColors.expense.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.selectedType == TransactionType.expense
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : AppColors.expense.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(Spacing.radiusS),
                            ),
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              color: widget.selectedType == TransactionType.expense
                                  ? Colors.white
                                  : AppColors.expense,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: Spacing.space8),
                          Text(
                            'Expense',
                            style: AppTypography.titleMedium.copyWith(
                              color: widget.selectedType == TransactionType.expense
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return GestureDetector(
                    onTap: () => _onTypeSelected(TransactionType.income),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: widget.selectedType == TransactionType.income
                            ? AppColors.income
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(Spacing.radiusM),
                        boxShadow: widget.selectedType == TransactionType.income
                            ? [
                                BoxShadow(
                                  color: AppColors.income.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.selectedType == TransactionType.income
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : AppColors.income.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(Spacing.radiusS),
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              color: widget.selectedType == TransactionType.income
                                  ? Colors.white
                                  : AppColors.income,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: Spacing.space8),
                          Text(
                            'Income',
                            style: AppTypography.titleMedium.copyWith(
                              color: widget.selectedType == TransactionType.income
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
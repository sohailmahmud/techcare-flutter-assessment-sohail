import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/analytics.dart';

enum BudgetStatus { underBudget, approaching, exceeded }

class BudgetProgressIndicators extends StatefulWidget {
  final List<BudgetComparison> budgetData;
  final bool isLoading;

  const BudgetProgressIndicators({
    super.key,
    required this.budgetData,
    this.isLoading = false,
  });

  @override
  State<BudgetProgressIndicators> createState() =>
      _BudgetProgressIndicatorsState();
}

class _BudgetProgressIndicatorsState extends State<BudgetProgressIndicators>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    final itemCount = math.min(widget.budgetData.length,
        12); // Allow up to 12 animations for better performance
    _controllers = List.generate(
      itemCount,
      (index) => AnimationController(
        duration: Duration(
            milliseconds: 1000 + (index * 50)), // Reduced delay for more items
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: controller,
            curve: Curves
                .easeOutCubic), // Changed from easeOutBack to avoid values > 1.0
      );
    }).toList();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        // Reduced delay for smoother animation with more items
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(BudgetProgressIndicators oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.budgetData.length != widget.budgetData.length) {
      _disposeControllers();
      _initializeAnimations();
      _startAnimations();
    }
  }

  void _disposeControllers() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    _animations.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Prevent excessive height
        children: [
          _buildHeader(),
          const SizedBox(height: Spacing.space16),
          // Always show content - don't use Flexible which might collapse
          widget.isLoading
              ? _buildLoadingState()
              : widget.budgetData.isEmpty
                  ? _buildEmptyState()
                  : _buildBudgetGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.track_changes_rounded,
            color: AppColors.warning,
            size: 20,
          ),
        ),
        const SizedBox(width: Spacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Budget Progress',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Monthly spending vs budget',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _buildOverallStatus(),
      ],
    );
  }

  Widget _buildOverallStatus() {
    if (widget.budgetData.isEmpty) return const SizedBox.shrink();

    final overBudgetCount =
        widget.budgetData.where((b) => b.isOverBudget).length;
    final approachingCount = widget.budgetData
        .where((b) => _getBudgetStatus(b) == BudgetStatus.approaching)
        .length;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (overBudgetCount > 0) {
      statusColor = AppColors.error;
      statusText = '$overBudgetCount over budget';
      statusIcon = Icons.warning_rounded;
    } else if (approachingCount > 0) {
      statusColor = AppColors.warning;
      statusText = '$approachingCount approaching limit';
      statusIcon = Icons.info_rounded;
    } else {
      statusColor = AppColors.success;
      statusText = 'All on track';
      statusIcon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.space12,
        vertical: Spacing.space4,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 14),
          const SizedBox(width: Spacing.space4),
          Text(
            statusText,
            style: AppTypography.labelSmall.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
            const SizedBox(height: Spacing.space16),
            Text(
              'Loading budget data...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      width: double.infinity, // Ensure it takes full width
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.track_changes_rounded,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: Spacing.space16),
            Text(
              'No budget data available',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: Spacing.space8),
            Text(
              'Set up budgets for your categories to track progress',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetGrid() {
    final displayData = widget.budgetData; // Show all categories

    if (displayData.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic dimensions based on available space and category count
        final availableWidth =
            constraints.maxWidth > 0 ? constraints.maxWidth : 300.0;
        final screenHeight = MediaQuery.of(context).size.height;

        // Dynamic crossAxisCount based on screen width and category count
        final crossAxisCount =
            availableWidth > 500 && displayData.length > 4 ? 3 : 2;

        // Calculate item dimensions with responsive aspect ratio
        final spacingWidth = (crossAxisCount - 1) * Spacing.space12;
        final itemWidth = (availableWidth - spacingWidth) / crossAxisCount;
        final aspectRatio =
            displayData.length <= 2 ? 1.1 : 1.0; // Taller cards for few items
        final itemHeight = itemWidth / aspectRatio;

        // Calculate optimal height with dynamic scaling
        final constrainedHeight =
            _calculateOptimalHeight(displayData.length, itemHeight);
        final minHeight = itemHeight; // At least one row
        final maxHeight = math.min(
            constrainedHeight, screenHeight * 0.81); // Cap at 60% of screen

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: math.max(maxHeight, minHeight),
            minHeight: minHeight,
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(Spacing.radiusS), // Clip any overflow
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: Spacing.space12,
                mainAxisSpacing: Spacing.space12,
                childAspectRatio: aspectRatio,
              ),
              itemCount: displayData.length,
              itemBuilder: (context, index) {
                if (index < _animations.length) {
                  return _buildBudgetCard(
                      displayData[index], _animations[index]);
                }
                return _buildBudgetCard(displayData[index], null);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetCard(
      BudgetComparison budget, Animation<double>? animation) {
    final statusColor = _getStatusColor(_getBudgetStatus(budget));

    Widget card = Container(
      padding: const EdgeInsets.all(Spacing.space16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Category icon and name
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getCategoryColor(budget.categoryName)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getCategoryIcon(budget.categoryName),
                  color: _getCategoryColor(budget.categoryName),
                  size: 14,
                ),
              ),
              const SizedBox(width: Spacing.space8),
              Expanded(
                child: Text(
                  budget.categoryName,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.space12),
          // Circular progress indicator - smaller for better fit
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: animation != null
                        ? (budget.percentage / 100) * animation.value
                        : budget.percentage / 100,
                    strokeWidth: 5,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${budget.percentage.toInt()}%',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _getBudgetStatus(budget) == BudgetStatus.underBudget
                          ? 'Under'
                          : _getBudgetStatus(budget) == BudgetStatus.approaching
                              ? 'Approaching'
                              : 'Over',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.space8),
          // Amount info
          Column(
            children: [
              Text(
                CurrencyFormatter.formatCompact(budget.actualAmount),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'of ${CurrencyFormatter.formatCompact(budget.budgetAmount)}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (animation != null) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.scale(
            scale: animation.value,
            child: Opacity(
              opacity: animation.value
                  .clamp(0.0, 1.0), // Ensure opacity is within valid range
              child: card,
            ),
          );
        },
      );
    }

    return card;
  }

  /// Calculate optimal height based on number of categories with dynamic scaling
  double _calculateOptimalHeight(int categoryCount, double itemHeight) {
    if (categoryCount == 0) return 200; // Empty state height

    final rowCount = (categoryCount / 2).ceil();
    final gridHeight =
        (rowCount * itemHeight) + ((rowCount - 1) * Spacing.space12);

    // Dynamic scaling based on category count
    if (categoryCount <= 2) {
      // 1 row: Show without scrolling, minimal height
      return gridHeight + 16; // Small padding for 1 row
    } else if (categoryCount <= 4) {
      // 2 rows: Show full height without scrolling
      return gridHeight + 20; // Medium padding for 2 rows
    } else if (categoryCount <= 6) {
      // 3 rows: Show full height without scrolling
      return gridHeight + 24; // More padding for 3 rows
    } else if (categoryCount <= 8) {
      // 4 rows: Show full height without scrolling
      return gridHeight + 28; // Generous padding for 4 rows
    } else if (categoryCount <= 12) {
      // 5-6 rows: Show up to 4 rows, then scroll
      const maxVisibleRows = 4;
      final maxHeightWithoutScroll = (maxVisibleRows * itemHeight) +
          ((maxVisibleRows - 1) * Spacing.space12) +
          32;
      return maxHeightWithoutScroll;
    } else {
      // Many categories: Progressive height increase with upper limit
      const maxVisibleRows = 5;
      final maxHeightWithoutScroll = (maxVisibleRows * itemHeight) +
          ((maxVisibleRows - 1) * Spacing.space12) +
          40;

      // Scale height progressively but cap at reasonable limit
      final progressiveHeight = math.min(gridHeight + 40, 500.0);
      return math.min(maxHeightWithoutScroll, progressiveHeight);
    }
  }

  // Helper method to get BudgetStatus from BudgetComparison
  BudgetStatus _getBudgetStatus(BudgetComparison budget) {
    if (budget.isOverBudget) {
      return BudgetStatus.exceeded;
    } else if (budget.percentage >= 80) {
      return BudgetStatus.approaching;
    } else {
      return BudgetStatus.underBudget;
    }
  }

  // Helper method to get category color from category name based on JSON mock data
  Color _getCategoryColor(String categoryName) {
    // Map category names to colors based on the JSON mock data structure
    final hash = categoryName.hashCode;
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      Colors.deepPurple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
    ];
    return colors[hash.abs() % colors.length];
  }

  // Helper method to get category icon from category name based on JSON mock data
  IconData _getCategoryIcon(String categoryName) {
    // Map category names to icons based on the JSON mock data structure
    final name = categoryName.toLowerCase();

    // Direct mapping from JSON mock data categories
    if (name.contains('food') || name.contains('dining')) {
      return Icons.restaurant;
    }
    if (name.contains('transport')) return Icons.directions_car;
    if (name.contains('shopping')) return Icons.shopping_bag;
    if (name.contains('entertainment')) return Icons.movie;
    if (name.contains('bills') || name.contains('utilities')) {
      return Icons.receipt;
    }
    if (name.contains('health') || name.contains('fitness')) {
      return Icons.fitness_center;
    }
    if (name.contains('education')) return Icons.school;
    if (name.contains('salary')) return Icons.payments;
    if (name.contains('freelance')) return Icons.work;
    if (name.contains('investment')) return Icons.trending_up;

    return Icons.category; // default icon
  }

  Color _getStatusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.underBudget:
        return AppColors.success;
      case BudgetStatus.approaching:
        return AppColors.warning;
      case BudgetStatus.exceeded:
        return AppColors.error;
    }
  }
}

/// Compact budget progress widget for smaller spaces
class CompactBudgetProgress extends StatelessWidget {
  final List<BudgetComparison> budgetData;
  final int maxItems;

  const CompactBudgetProgress({
    super.key,
    required this.budgetData,
    this.maxItems = 3,
  });

  @override
  Widget build(BuildContext context) {
    final displayData = budgetData.take(maxItems).toList();

    return Column(
      children: displayData.map((budget) {
        return Container(
          margin: const EdgeInsets.only(bottom: Spacing.space8),
          padding: const EdgeInsets.all(Spacing.space12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getStatusColor(_getBudgetStatus(budget))
                  .withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getCategoryColor(budget.categoryName)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(budget.categoryName),
                  color: _getCategoryColor(budget.categoryName),
                  size: 16,
                ),
              ),
              const SizedBox(width: Spacing.space12),
              // Category name and progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.categoryName,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: Spacing.space4),
                    LinearProgressIndicator(
                      value: budget.percentage / 100,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(_getBudgetStatus(budget)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.space12),
              // Percentage
              Text(
                '${budget.percentage.toInt()}%',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _getStatusColor(_getBudgetStatus(budget)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Helper method to get BudgetStatus from BudgetComparison
  BudgetStatus _getBudgetStatus(BudgetComparison budget) {
    if (budget.isOverBudget) {
      return BudgetStatus.exceeded;
    } else if (budget.percentage >= 80) {
      return BudgetStatus.approaching;
    } else {
      return BudgetStatus.underBudget;
    }
  }

  // Helper method to get category color from category name based on JSON mock data
  Color _getCategoryColor(String categoryName) {
    // Map category names to colors based on the JSON mock data structure
    final hash = categoryName.hashCode;
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      Colors.deepPurple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
    ];
    return colors[hash.abs() % colors.length];
  }

  // Helper method to get category icon from category name based on JSON mock data
  IconData _getCategoryIcon(String categoryName) {
    // Map category names to icons based on the JSON mock data structure
    final name = categoryName.toLowerCase();

    // Direct mapping from JSON mock data categories
    if (name.contains('food') || name.contains('dining')) {
      return Icons.restaurant;
    }
    if (name.contains('transport')) return Icons.directions_car;
    if (name.contains('shopping')) return Icons.shopping_bag;
    if (name.contains('entertainment')) return Icons.movie;
    if (name.contains('bills') || name.contains('utilities')) {
      return Icons.receipt;
    }
    if (name.contains('health') || name.contains('fitness')) {
      return Icons.fitness_center;
    }
    if (name.contains('education')) return Icons.school;
    if (name.contains('salary')) return Icons.payments;
    if (name.contains('freelance')) return Icons.work;
    if (name.contains('investment')) return Icons.trending_up;

    return Icons.category; // default icon
  }

  Color _getStatusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.underBudget:
        return AppColors.success;
      case BudgetStatus.approaching:
        return AppColors.warning;
      case BudgetStatus.exceeded:
        return AppColors.error;
    }
  }
}

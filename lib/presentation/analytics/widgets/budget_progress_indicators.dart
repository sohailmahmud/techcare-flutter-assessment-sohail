import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/analytics.dart';
import '../../../domain/entities/category.dart';

enum BudgetStatus { underBudget, approaching, exceeded }

class BudgetProgressIndicators extends StatefulWidget {
  final List<BudgetComparison> budgetData;
  final List<Category> categories;
  final bool isLoading;

  const BudgetProgressIndicators({
    super.key,
    required this.budgetData,
    required this.categories,
    this.isLoading = false,
  });

  @override
  State<BudgetProgressIndicators> createState() =>
      _BudgetProgressIndicatorsState();
}

class _BudgetProgressIndicatorsState extends State<BudgetProgressIndicators>
    with TickerProviderStateMixin {
  List<AnimationController> _controllers = [];
  List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _disposeControllers();
      _initializeAnimations();
      _startAnimations();
    });
  }

  void _initializeAnimations() {
    final itemCount = math.min(
      widget.budgetData.length,
      12,
    ); // Allow up to 12 animations for better performance
    _controllers = List.generate(
      itemCount,
      (index) => AnimationController(
        duration: Duration(
          milliseconds: 1000 + (index * 50),
        ), // Reduced delay for more items
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        ), // Changed from easeOutBack to avoid values > 1.0
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
    // Always restart animation if budgetData changes (length or content)
    if (!_listEquals(oldWidget.budgetData, widget.budgetData)) {
      _disposeControllers();
      _initializeAnimations();
      // Reset all controllers to 0 before starting
      for (final controller in _controllers) {
        controller.value = 0.0;
      }
      _startAnimations();
      setState(() {}); // Force rebuild to update progress indicators
    }
  }

  // Helper to compare lists of BudgetComparison by categoryId and percentage
  bool _listEquals(List<BudgetComparison> a, List<BudgetComparison> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].categoryId != b[i].categoryId ||
          a[i].percentage != b[i].percentage) {
        return false;
      }
    }
    return true;
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
                'Spending vs budget',
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

    final overBudgetCount = widget.budgetData
        .where((b) => b.isOverBudget)
        .length;
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
        final availableWidth = constraints.maxWidth > 0
            ? constraints.maxWidth
            : 300.0;
        // Determine cross axis count based on available width and desired min item width
        const minItemWidth = 160.0; // desired minimum card width
        int crossAxisCount = (availableWidth / minItemWidth).floor();
        if (crossAxisCount < 1) crossAxisCount = 1;
        if (crossAxisCount > 3) crossAxisCount = 3; // cap columns

        final itemWidth = availableWidth / crossAxisCount;
        const baseItemHeight = 200.0; // desired base height for card
        final childAspectRatio = itemWidth / baseItemHeight;

        return ClipRRect(
          borderRadius: BorderRadius.circular(Spacing.radiusS),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: Spacing.space12,
              mainAxisSpacing: Spacing.space12,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: displayData.length,
            itemBuilder: (context, index) {
              if (index < _animations.length) {
                return _buildBudgetCard(displayData[index], _animations[index]);
              }
              return _buildBudgetCard(displayData[index], null);
            },
          ),
        );
      },
    );
  }

  Widget _buildBudgetCard(
    BudgetComparison budget,
    Animation<double>? animation,
  ) {
    Widget card = _buildBudgetCardContent(budget, animation);
    if (animation != null) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          // Animate both scale and progress value from 0 to budget.percentage
          return Transform.scale(
            scale: animation.value,
            child: Opacity(
              opacity: animation.value.clamp(0.0, 1.0),
              child: _buildBudgetCardContent(budget, animation),
            ),
          );
        },
        child: card,
      );
    }
    return card;
  }

  Widget _buildBudgetCardContent(
    BudgetComparison budget,
    Animation<double>? animation,
  ) {
    final status = _getBudgetStatus(budget);
    final statusColor = _getStatusColor(status);
    // Improved fallback logic: match by id, then by name (case-insensitive, trimmed)
    Category injectedCategory;
    final byId = widget.categories.where((cat) => cat.id == budget.categoryId);
    if (byId.isNotEmpty) {
      injectedCategory = byId.first;
    } else {
      final byName = widget.categories.where(
        (cat) =>
            cat.name.trim().toLowerCase() ==
            budget.categoryName.trim().toLowerCase(),
      );
      if (byName.isNotEmpty) {
        injectedCategory = byName.first;
      } else {
        injectedCategory = Category(
          id: budget.categoryId,
          name: budget.categoryName,
          icon: Icons.category,
          color: Colors.grey,
        );
      }
    }
    final categoryColor = injectedCategory.color;
    final categoryIcon = injectedCategory.icon;
    final categoryName = injectedCategory.name;
    return Container(
      padding: const EdgeInsets.all(Spacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 14),
              ),
              const SizedBox(width: Spacing.space8),
              Expanded(
                child: Text(
                  categoryName,
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
                      animation != null
                          ? '${(budget.percentage * animation.value).toInt()}%'
                          : '${budget.percentage.toInt()}%',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      status == BudgetStatus.underBudget
                          ? 'Under'
                          : status == BudgetStatus.approaching
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
          // Reserve a fixed area for amounts so they don't overflow when card height is constrained
          SizedBox(
            height: 44,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyFormatter.formatCompact(budget.actualAmount),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'of ${CurrencyFormatter.formatCompact(budget.budgetAmount)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
  final List<Category>? categories;
  final int maxItems;

  const CompactBudgetProgress({
    super.key,
    required this.budgetData,
    this.categories,
    this.maxItems = 3,
  });

  @override
  Widget build(BuildContext context) {
    final displayData = budgetData.take(maxItems).toList();

    return Column(
      children: displayData.map((budget) {
        final status = _getBudgetStatus(budget);
        final statusColor = _getStatusColor(status);

        // Try to resolve category from injected list
        Category? resolved;
        if (categories != null) {
          resolved = categories!.firstWhere(
            (c) =>
                c.id == budget.categoryId ||
                c.name.trim().toLowerCase() ==
                    budget.categoryName.trim().toLowerCase(),
            orElse: () => Category(
              id: '',
              name: budget.categoryName,
              icon: Icons.category,
              color: Colors.grey,
            ),
          );
        }

        final category = resolved;
        final categoryColor = category?.color ?? Colors.grey;
        final categoryIcon = category?.icon ?? Icons.category;
        final categoryName = category?.name ?? budget.categoryName;

        return Container(
          margin: const EdgeInsets.only(bottom: Spacing.space8),
          padding: const EdgeInsets.all(Spacing.space12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 16),
              ),
              const SizedBox(width: Spacing.space12),
              // Category name and progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: Spacing.space4),
                    LinearProgressIndicator(
                      value: budget.percentage / 100,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
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
                  color: statusColor,
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

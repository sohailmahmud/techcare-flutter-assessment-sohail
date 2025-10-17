import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/analytics.dart';
import '../../../domain/entities/category.dart';

class CategoryBreakdownChart extends StatefulWidget {
  final List<CategoryBreakdown> categoryData;
  final List<Category> categories;
  final bool isLoading;
  final VoidCallback? onTap;

  const CategoryBreakdownChart({
    super.key,
    required this.categoryData,
    required this.categories,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<CategoryBreakdownChart> createState() => _CategoryBreakdownChartState();
}

class _CategoryBreakdownChartState extends State<CategoryBreakdownChart> with TickerProviderStateMixin {
  Widget _buildCategoryIcon(IconData icon, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildProgressBar(double percentage, double animationValue, Color color) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: ((percentage / 100) * animationValue).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha:  0.7), color],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _startAnimation();
  }

  void _startAnimation() {
    _animationController.forward();
  }

  @override
  void didUpdateWidget(CategoryBreakdownChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryData != widget.categoryData) {
      _animationController.reset();
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        children: [
          _buildHeader(),
          const SizedBox(height: Spacing.space16),
          widget.isLoading
              ? _buildLoadingState()
              : widget.categoryData.isEmpty
                  ? _buildEmptyState()
                  : _buildChart(),
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
            color: AppColors.expense.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.pie_chart_rounded,
            color: AppColors.expense,
            size: 20,
          ),
        ),
        const SizedBox(width: Spacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category Breakdown',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Spending by category',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (widget.onTap != null)
          IconButton(
            onPressed: widget.onTap,
            icon: const Icon(
              Icons.fullscreen_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 300,
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
              'Loading category data...',
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
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pie_chart_outline_rounded,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: Spacing.space16),
            Text(
              'No category data available',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: Spacing.space8),
            Text(
              'Add some expense transactions to see category breakdown',
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

  Widget _buildChart() {
    final barHeight = 60.0;
    final maxVisibleBars = 5;
    final totalBars = widget.categoryData.length;
    final showAllBars = totalBars <= maxVisibleBars;
    final chartHeight = showAllBars ? totalBars * barHeight : maxVisibleBars * barHeight;

    final ScrollController barScrollController = ScrollController();

    return Column(
      children: [
        // Horizontal Bar Chart
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return SizedBox(
              height: chartHeight,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // If at edge, let parent scroll
                  if (notification is ScrollUpdateNotification || notification is OverscrollNotification) {
                    final atTop = barScrollController.position.pixels <= barScrollController.position.minScrollExtent;
                    final atBottom = barScrollController.position.pixels >= barScrollController.position.maxScrollExtent;
                    if (atTop || atBottom) {
                      // Allow parent scroll
                      return false;
                    }
                  }
                  // Prevent parent scroll when not at edge
                  return true;
                },
                child: ListView.builder(
                  controller: barScrollController,
                  physics: showAllBars
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  itemCount: totalBars,
                  itemBuilder: (context, index) {
                    return _buildCategoryBar(widget.categoryData[index], index);
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: Spacing.space16),
        // Summary
        _buildSummary(),
      ],
    );
  }

  Widget _buildCategoryBar(CategoryBreakdown data, int index) {
    final animationDelay = index * 0.1;
    final barAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(animationDelay, (animationDelay + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOut),
      ),
    );
    return FutureBuilder<Category>(
      future: _findCategory(data),
      builder: (context, snapshot) {
        final cat = snapshot.data ?? Category(
          id: data.categoryId,
          name: data.categoryName,
          color: AppColors.primary,
          icon: Icons.category,
        );
        return AnimatedBuilder(
          animation: barAnimation,
          builder: (context, child) {
            return GestureDetector(
              onTap: () => _onCategoryTap(data),
              child: Container(
                margin: const EdgeInsets.only(bottom: Spacing.space12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildCategoryIcon(cat.icon, cat.color),
                        const SizedBox(width: Spacing.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${data.transactionCount} transactions',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.formatCompact(data.amount),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${data.percentage.toStringAsFixed(1)}%',
                              style: AppTypography.labelSmall.copyWith(
                                color: cat.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.space8),
                    _buildProgressBar(
                        data.percentage, barAnimation.value, cat.color),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummary() {
    final totalAmount = widget.categoryData.fold<double>(
      0,
      (sum, data) => sum + data.amount,
    );

    final topCategory =
        widget.categoryData.isNotEmpty ? widget.categoryData.first : null;

    return Container(
      padding: const EdgeInsets.all(Spacing.space16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Expenses',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                CurrencyFormatter.format(totalAmount),
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (topCategory != null) ...[
            const SizedBox(height: Spacing.space8),
            FutureBuilder<Category>(
              future: _findCategory(topCategory),
              builder: (context, snapshot) {
                final cat = snapshot.data ?? Category(
                  id: topCategory.categoryId,
                  name: topCategory.categoryName,
                  color: AppColors.primary,
                  icon: Icons.category,
                );
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top Category',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          cat.icon,
                          color: cat.color,
                          size: 16,
                        ),
                        const SizedBox(width: Spacing.space4),
                        Text(
                          topCategory.categoryName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cat.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _onCategoryTap(CategoryBreakdown data) {
    // Show detailed breakdown or navigate to category details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCategoryDetailsSheet(data),
    );
  }

  Widget _buildCategoryDetailsSheet(CategoryBreakdown data) {
    return FutureBuilder<Category>(
      future: _findCategory(data),
      builder: (context, snapshot) {
        final cat = snapshot.data ?? Category(
          id: data.categoryId,
          name: data.categoryName,
          color: AppColors.primary,
          icon: Icons.category,
        );
        return Container(
          padding: const EdgeInsets.all(Spacing.space24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: Spacing.space24),
              // Category info
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      cat.icon,
                      color: cat.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: Spacing.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.categoryName,
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Category Details',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.space24),
              // Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Spent',
                      CurrencyFormatter.format(data.amount),
                      AppColors.expense,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Percentage',
                      '${data.percentage.toStringAsFixed(1)}%',
                      cat.color,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Transactions',
                      data.transactionCount.toString(),
                      AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.space24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: Spacing.space4),
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  Future<Category> _findCategory(CategoryBreakdown data) async {
    final category = await AppCategories.findById(data.categoryId);
    // Provide a fallback category if not found
    return category ?? Category(
      id: data.categoryId,
      name: data.categoryName,
      color: AppColors.primary,
      icon: Icons.category,
    );
  }
}

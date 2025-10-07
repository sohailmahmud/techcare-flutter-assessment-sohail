import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../domain/entities/dashboard_summary.dart';

/// Interactive pie chart for spending overview
class SpendingPieChart extends StatefulWidget {
  final List<CategoryExpense> categories;
  final Function(String?)? onCategorySelected;
  final String? selectedCategory;

  const SpendingPieChart({
    super.key,
    required this.categories,
    this.onCategorySelected,
    this.selectedCategory,
  });

  @override
  State<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<SpendingPieChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.refreshDelay,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Reset and replay chart animation
  void _resetChartAnimation() {
    setState(() {
      _touchedIndex = -1;
    });
    
    // Reset animation and replay
    _animationController.reset();
    _animationController.forward();
  }

  @override
  void didUpdateWidget(SpendingPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reset and replay animation when selected category changes
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _resetChartAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassMorphicContainer(
      padding: const EdgeInsets.all(Spacing.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Overview',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (widget.selectedCategory != null)
                GestureDetector(
                  onTap: () {
                    // Reset chart animation and touched index when clearing filter
                    _resetChartAnimation();
                    widget.onCategorySelected?.call(null);
                  },
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
                          'Clear Filter',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.close,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (widget.categories.isEmpty)
            _buildEmptyState()
          else
            _buildChart(),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Row(
      children: [
        // Pie Chart
        Expanded(
          flex: 3,
          child: AspectRatio(
            aspectRatio: 1,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          final touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                          if (touchedIndex != -1) {
                            _touchedIndex = touchedIndex;
                            final category = widget.categories[touchedIndex];
                            widget.onCategorySelected?.call(category.categoryId);
                          }
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: Spacing.pieChartSectionsSpace,
                    centerSpaceRadius: Spacing.pieChartCenterRadius,
                    sections: _buildPieChartSections(),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Legend
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildLegend(),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    return widget.categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final isTouched = index == _touchedIndex;
      final isSelected = widget.selectedCategory == category.categoryId;
      final opacity = widget.selectedCategory == null || isSelected ? 1.0 : 0.3;
      
      return PieChartSectionData(
        color: _getCategoryColor(index).withValues(alpha: opacity),
        value: category.percentage * _animation.value,
        title: isTouched ? '${category.percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched ? Spacing.pieChartTouchedRadius : (isSelected ? Spacing.pieChartSelectedRadius : Spacing.pieChartNormalRadius),
        titleStyle: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  List<Widget> _buildLegend() {
    return widget.categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final isSelected = widget.selectedCategory == category.categoryId;
      final opacity = widget.selectedCategory == null || isSelected ? 1.0 : 0.5;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () {
            final categoryId = isSelected ? null : category.categoryId;
            widget.onCategorySelected?.call(categoryId);
          },
          child: Opacity(
            opacity: opacity,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(index),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.categoryName,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        CurrencyFormatter.format(category.amount),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: Spacing.pieChartEmptyStateHeight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No spending data',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start adding expenses to see your spending breakdown',
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

  Color _getCategoryColor(int index) {
    return AppColors.categoryColors[index % Spacing.maxCategoryColors];
  }
}
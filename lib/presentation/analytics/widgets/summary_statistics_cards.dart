import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/analytics.dart';

class SummaryStatisticsCards extends StatefulWidget {
  final AnalyticsData statistics;

  const SummaryStatisticsCards({
    super.key,
    required this.statistics,
  });

  @override
  State<SummaryStatisticsCards> createState() => _SummaryStatisticsCardsState();
}

class _SummaryStatisticsCardsState extends State<SummaryStatisticsCards>
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
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: Duration(milliseconds: 800 + (index * 200)),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
      );
    }).toList();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(SummaryStatisticsCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statistics != widget.statistics) {
      _resetAndReplayAnimations();
    }
  }

  void _resetAndReplayAnimations() {
    for (final controller in _controllers) {
      controller.reset();
    }
    _startAnimations();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            index: 0,
            title: 'Total Income',
            amount: widget.statistics.totalIncome,
            change: 0.0,
            color: AppColors.income,
            icon: Icons.trending_up_rounded,
          ),
        ),
        const SizedBox(width: Spacing.space12),
        Expanded(
          child: _buildStatCard(
            index: 1,
            title: 'Total Expenses',
            amount: widget.statistics.totalExpenses,
            change: 0.0,
            color: AppColors.expense,
            icon: Icons.trending_down_rounded,
          ),
        ),
        const SizedBox(width: Spacing.space12),
        Expanded(
          child: _buildStatCard(
            index: 2,
            title: 'Net Balance',
            amount: widget.statistics.netAmount,
            change: 0.0,
            color: widget.statistics.netAmount >= 0
                ? AppColors.income
                : AppColors.expense,
            icon: widget.statistics.netAmount >= 0
                ? Icons.account_balance_wallet_rounded
                : Icons.warning_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required int index,
    required String title,
    required double amount,
    required double change,
    required Color color,
    required IconData icon,
  }) {
    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: _animations[index].value,
          child: Container(
            padding: const EdgeInsets.all(Spacing.space16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    _buildChangeIndicator(change, color),
                  ],
                ),
                const SizedBox(height: Spacing.space12),
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: Spacing.space4),
                AnimatedNumberCounter(
                  value: amount,
                  animation: _animations[index],
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChangeIndicator(double change, Color baseColor) {
    final isPositive = change >= 0;
    final displayChange = change.abs();

    if (displayChange < 0.01) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.space8,
          vertical: Spacing.space4,
        ),
        decoration: BoxDecoration(
          color: AppColors.textTertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '0%',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.space8,
        vertical: Spacing.space4,
      ),
      decoration: BoxDecoration(
        color: (isPositive ? AppColors.income : AppColors.expense)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 12,
            color: isPositive ? AppColors.income : AppColors.expense,
          ),
          const SizedBox(width: 2),
          Text(
            '${displayChange.toStringAsFixed(1)}%',
            style: AppTypography.labelSmall.copyWith(
              color: isPositive ? AppColors.income : AppColors.expense,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated number counter widget
class AnimatedNumberCounter extends StatelessWidget {
  final double value;
  final Animation<double> animation;
  final TextStyle style;
  final bool showCurrency;

  const AnimatedNumberCounter({
    super.key,
    required this.value,
    required this.animation,
    required this.style,
    this.showCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animatedValue = value * animation.value;
        return Text(
          showCurrency
              ? CurrencyFormatter.formatCompact(animatedValue)
              : animatedValue.toStringAsFixed(0),
          style: style,
        );
      },
    );
  }
}

/// Responsive summary stats for mobile/desktop
class ResponsiveSummaryStats extends StatelessWidget {
  final AnalyticsData statistics;

  const ResponsiveSummaryStats({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // Desktop layout - horizontal
          return SummaryStatisticsCards(statistics: statistics);
        } else {
          // Mobile layout - vertical stack
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildCompactStatCard(
                      title: 'Income',
                      amount: statistics.totalIncome,
                      change: 0.0,
                      color: AppColors.income,
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                  const SizedBox(width: Spacing.space8),
                  Expanded(
                    child: _buildCompactStatCard(
                      title: 'Expenses',
                      amount: statistics.totalExpenses,
                      change: 0.0,
                      color: AppColors.expense,
                      icon: Icons.trending_down_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.space8),
              _buildCompactStatCard(
                title: 'Net Balance',
                amount: statistics.netAmount,
                change: 0.0,
                color: statistics.netAmount >= 0
                    ? AppColors.income
                    : AppColors.expense,
                icon: statistics.netAmount >= 0
                    ? Icons.account_balance_wallet_rounded
                    : Icons.warning_rounded,
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildCompactStatCard({
    required String title,
    required double amount,
    required double change,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(Spacing.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: Spacing.space8),
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.space8),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Spacing.space4),
          _buildChangeText(change),
        ],
      ),
    );
  }

  Widget _buildChangeText(double change) {
    final isPositive = change >= 0;
    final displayChange = change.abs();

    if (displayChange < 0.01) {
      return Text(
        'No change',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiary,
        ),
      );
    }

    return Text(
      '${isPositive ? '+' : '-'}${displayChange.toStringAsFixed(1)}% from last period',
      style: AppTypography.labelSmall.copyWith(
        color: isPositive ? AppColors.income : AppColors.expense,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

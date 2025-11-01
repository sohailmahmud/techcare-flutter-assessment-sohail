import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';

/// Base skeleton loader widget with shimmer effect
class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final double? borderRadius;
  final Widget? child;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.textDisabled.withValues(alpha: 0.3),
      highlightColor: AppColors.surface,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(borderRadius ?? Spacing.radiusS),
        ),
        child: child,
      ),
    );
  }
}

/// Dashboard skeleton loaders matching exact UI structure
class DashboardSkeletonLoaders {
  /// Balance card skeleton with detailed structure
  static Widget balanceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.space16),
      child: Container(
        height: Spacing.balanceCardHeight,
        padding: const EdgeInsets.all(Spacing.space24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Spacing.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Spacing.space16),
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonLoader(
                  width: 100,
                  height: 20,
                  borderRadius: Spacing.radiusS,
                ),
                SkeletonLoader(
                  width: 30,
                  height: 30,
                  borderRadius: Spacing.radiusFull,
                ),
              ],
            ),
            SizedBox(height: Spacing.space16),

            // Main balance amount
            SkeletonLoader(
              width: 140,
              height: 32,
              borderRadius: Spacing.radiusS,
            ),
            SizedBox(height: Spacing.space48),

            // Income/Expense row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(
                        width: 50,
                        height: 12,
                        borderRadius: Spacing.radiusS,
                      ),
                      SizedBox(height: Spacing.space4),
                      SkeletonLoader(
                        width: 80,
                        height: 18,
                        borderRadius: Spacing.radiusS,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Spacing.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(
                        width: 60,
                        height: 12,
                        borderRadius: Spacing.radiusS,
                      ),
                      SizedBox(height: Spacing.space4),
                      SkeletonLoader(
                        width: 85,
                        height: 18,
                        borderRadius: Spacing.radiusS,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pie chart skeleton with legend
  static Widget spendingChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.space16),
      child: Container(
        height: Spacing.pieChartHeight,
        padding: const EdgeInsets.all(Spacing.space16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Spacing.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Spacing.space16),
            // Header with title and filter
            const SkeletonLoader(
              width: 200,
              height: 20,
              borderRadius: Spacing.radiusS,
            ),
            const SizedBox(height: Spacing.space16),

            // Chart and legend
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: Spacing.space8),
                child: Row(
                  children: [
                    // Pie chart circle
                    const Expanded(
                      flex: 2,
                      child: Center(
                        child: SkeletonLoader(
                          width: 180,
                          height: 180,
                          borderRadius: Spacing.radiusFull,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.space16),

                    // Legend items
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          4,
                          (index) => Padding(
                            padding: EdgeInsets.only(
                              bottom: index < 3 ? Spacing.space12 : 0,
                            ),
                            child: const Row(
                              children: [
                                SkeletonLoader(
                                  width: 12,
                                  height: 12,
                                  borderRadius: 6,
                                ),
                                SizedBox(width: Spacing.space8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SkeletonLoader(
                                        width: double.infinity,
                                        height: 12,
                                        borderRadius: Spacing.radiusS,
                                      ),
                                      SizedBox(height: 2),
                                      SkeletonLoader(
                                        width: 40,
                                        height: 10,
                                        borderRadius: Spacing.radiusS,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Transaction item skeleton
  static Widget transactionItem() {
    return Container(
      padding: const EdgeInsets.all(Spacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Spacing.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Row(
        children: [
          // Transaction icon
          SkeletonLoader(
            width: Spacing.transactionIconSize,
            height: Spacing.transactionIconSize,
            borderRadius: Spacing.radiusM,
          ),
          SizedBox(width: Spacing.space12),

          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 80,
                  height: 16,
                  borderRadius: Spacing.radiusS,
                ),
                SizedBox(height: Spacing.space4),
                SkeletonLoader(
                  width: 140,
                  height: 12,
                  borderRadius: Spacing.radiusS,
                ),
              ],
            ),
          ),

          // Amount and date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonLoader(
                width: 70,
                height: 16,
                borderRadius: Spacing.radiusS,
              ),
              SizedBox(height: Spacing.space4),
              SkeletonLoader(
                width: 50,
                height: 12,
                borderRadius: Spacing.radiusS,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Full transactions section skeleton
  static Widget transactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Spacing.space16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(
                width: 200,
                height: 20,
                borderRadius: Spacing.radiusS,
              ),
              SkeletonLoader(
                width: 60,
                height: 16,
                borderRadius: Spacing.radiusS,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.space16),

        // Transaction items
        ...List.generate(
          5,
          (index) => Padding(
            padding: EdgeInsets.only(
              left: Spacing.space16,
              right: Spacing.space16,
              bottom: index < 4 ? Spacing.space12 : 0,
            ),
            child: transactionItem(),
          ),
        ),
      ],
    );
  }
}

/// List item skeleton loader
class ListItemSkeletonLoader extends StatelessWidget {
  const ListItemSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.space16,
        vertical: Spacing.space8,
      ),
      child: Row(
        children: [
          SkeletonLoader(width: 48, height: 48, borderRadius: Spacing.radiusM),
          SizedBox(width: Spacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 120, height: 16),
                SizedBox(height: Spacing.space4),
                SkeletonLoader(width: 80, height: 14),
              ],
            ),
          ),
          SkeletonLoader(width: 60, height: 20),
        ],
      ),
    );
  }
}

/// Analytics skeleton loader matching analytics page layout
class AnalyticsSkeletonLoader extends StatelessWidget {
  const AnalyticsSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(Spacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector skeleton
          Container(
            padding: const EdgeInsets.all(Spacing.space16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Spacing.radiusL),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    SkeletonLoader(
                      width: 24,
                      height: 24,
                      borderRadius: Spacing.radiusFull,
                    ),
                    SizedBox(width: Spacing.space8),
                    SkeletonLoader(
                      width: 100,
                      height: 20,
                      borderRadius: Spacing.radiusS,
                    ),
                    Spacer(),
                    SkeletonLoader(
                      width: 170,
                      height: 20,
                      borderRadius: Spacing.radiusL,
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.space16),
                Wrap(
                  spacing: Spacing.space12,
                  runSpacing: Spacing.space12,
                  children: List.generate(
                    4,
                    (index) => SkeletonLoader(
                      width: 100 + (index * 5).toDouble(),
                      height: 32,
                      borderRadius: Spacing.radiusL,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.space16),

          // Responsive summary statistics skeleton
          if (isWide)
            const Row(
              children: [
                Expanded(
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 80,
                    borderRadius: Spacing.radiusL,
                  ),
                ),
                SizedBox(width: Spacing.space12),
                Expanded(
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 80,
                    borderRadius: Spacing.radiusL,
                  ),
                ),
                SizedBox(width: Spacing.space12),
                Expanded(
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 80,
                    borderRadius: Spacing.radiusL,
                  ),
                ),
              ],
            )
          else ...[
            const Row(
              children: [
                Expanded(
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 80,
                    borderRadius: Spacing.radiusL,
                  ),
                ),
                SizedBox(width: Spacing.space12),
                Expanded(
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 80,
                    borderRadius: Spacing.radiusL,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.space8),
            const SkeletonLoader(
              width: double.infinity,
              height: 80,
              borderRadius: Spacing.radiusL,
            ),
          ],
          const SizedBox(height: Spacing.space16),

          // Spending trend chart skeleton
          const SkeletonLoader(
            width: double.infinity,
            height: 220,
            borderRadius: Spacing.radiusL,
          ),
          const SizedBox(height: Spacing.space16),

          // Category breakdown and budget progress skeletons
          isWide
              ? const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SkeletonLoader(
                        width: double.infinity,
                        height: 260,
                        borderRadius: Spacing.radiusL,
                      ),
                    ),
                    SizedBox(width: Spacing.space16),
                    Expanded(
                      child: SkeletonLoader(
                        width: double.infinity,
                        height: 260,
                        borderRadius: Spacing.radiusL,
                      ),
                    ),
                  ],
                )
              : const Column(
                  children: [
                    SkeletonLoader(
                      width: double.infinity,
                      height: 260,
                      borderRadius: Spacing.radiusL,
                    ),
                    SizedBox(height: Spacing.space16),
                    SkeletonLoader(
                      width: double.infinity,
                      height: 260,
                      borderRadius: Spacing.radiusL,
                    ),
                  ],
                ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
        ],
      ),
    );
  }
}

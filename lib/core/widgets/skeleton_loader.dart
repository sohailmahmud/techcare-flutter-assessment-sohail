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
      baseColor: AppColors.surfaceVariant.withValues(alpha: 0.3),
      highlightColor: AppColors.surface,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(
            borderRadius ?? Spacing.radiusS,
          ),
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
    return Container(
      height: Spacing.balanceCardHeight,
      padding: const EdgeInsets.all(Spacing.space16),
      decoration: BoxDecoration(
        color: AppColors.textTertiary,
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
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(
                  width: 80, height: 16, borderRadius: Spacing.radiusS),
              SkeletonLoader(
                  width: 24, height: 24, borderRadius: Spacing.radiusM),
            ],
          ),
          SizedBox(height: Spacing.space16),

          // Main balance amount
          SkeletonLoader(width: 140, height: 32, borderRadius: Spacing.radiusS),
          SizedBox(height: Spacing.space8),

          // Balance change indicator
          SkeletonLoader(width: 100, height: 16, borderRadius: Spacing.radiusS),
          Spacer(),

          // Income/Expense row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                        width: 50, height: 12, borderRadius: Spacing.radiusS),
                    SizedBox(height: Spacing.space4),
                    SkeletonLoader(
                        width: 80, height: 18, borderRadius: Spacing.radiusS),
                  ],
                ),
              ),
              SizedBox(width: Spacing.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                        width: 60, height: 12, borderRadius: Spacing.radiusS),
                    SizedBox(height: Spacing.space4),
                    SkeletonLoader(
                        width: 85, height: 18, borderRadius: Spacing.radiusS),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Pie chart skeleton with legend
  static Widget spendingChart() {
    return Container(
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
          // Header with title and filter
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(
                  width: 120, height: 20, borderRadius: Spacing.radiusS),
              SkeletonLoader(width: 20, height: 20, borderRadius: 10),
            ],
          ),
          const SizedBox(height: Spacing.space16),

          // Chart and legend
          Expanded(
            child: Row(
              children: [
                // Pie chart circle
                const Expanded(
                  flex: 2,
                  child: Center(
                    child: SkeletonLoader(
                        width: 140, height: 140, borderRadius: 70),
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
                                      width: 12, height: 12, borderRadius: 6),
                                  SizedBox(width: Spacing.space8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SkeletonLoader(
                                            width: double.infinity,
                                            height: 12,
                                            borderRadius: Spacing.radiusS),
                                        SizedBox(height: 2),
                                        SkeletonLoader(
                                            width: 40,
                                            height: 10,
                                            borderRadius: Spacing.radiusS),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            borderRadius: Spacing.transactionIconSize / 2,
          ),
          SizedBox(width: Spacing.space12),

          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                    width: 120, height: 16, borderRadius: Spacing.radiusS),
                SizedBox(height: Spacing.space4),
                SkeletonLoader(
                    width: 80, height: 12, borderRadius: Spacing.radiusS),
              ],
            ),
          ),

          // Amount and date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonLoader(
                  width: 70, height: 16, borderRadius: Spacing.radiusS),
              SizedBox(height: Spacing.space4),
              SkeletonLoader(
                  width: 50, height: 12, borderRadius: Spacing.radiusS),
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
                  width: 140, height: 20, borderRadius: Spacing.radiusS),
              SkeletonLoader(
                  width: 60, height: 16, borderRadius: Spacing.radiusS),
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
                )),
      ],
    );
  }
}

/// Complete dashboard skeleton loader
class DashboardSkeletonLoader extends StatelessWidget {
  const DashboardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.orange.withValues(alpha: 0.2), // Very visible background
      body: SafeArea(
        child: Container(
          color: Colors.blue.withValues(alpha: 0.2), // Container background
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Simple visible skeleton blocks
                Container(
                  width: double.infinity,
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.8), // Very visible
                    borderRadius: BorderRadius.circular(Spacing.radiusL),
                  ),
                  child: const Center(
                    child: Text(
                      'Loading Header...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                // Balance card skeleton
                Container(
                  width: double.infinity,
                  height: Spacing.balanceCardHeight,
                  margin: const EdgeInsets.only(bottom: 16),
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
                  child: const Padding(
                    padding: EdgeInsets.all(Spacing.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLoader(width: 80, height: 16),
                        SizedBox(height: Spacing.space8),
                        SkeletonLoader(width: 150, height: 28),
                        SizedBox(height: Spacing.space16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SkeletonLoader(width: 50, height: 12),
                                  SizedBox(height: 4),
                                  SkeletonLoader(width: 80, height: 18),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SkeletonLoader(width: 60, height: 12),
                                  SizedBox(height: 4),
                                  SkeletonLoader(width: 85, height: 18),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Chart skeleton
                Container(
                  width: double.infinity,
                  height: Spacing.pieChartHeight,
                  margin: const EdgeInsets.only(bottom: 16),
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
                  child: const Center(
                    child: SkeletonLoader(
                        width: 140, height: 140, borderRadius: 70),
                  ),
                ),

                // Transactions skeleton
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 140, height: 20),
                    SizedBox(height: 16),
                    SkeletonLoader(width: double.infinity, height: 72),
                    SizedBox(height: 12),
                    SkeletonLoader(width: double.infinity, height: 72),
                    SizedBox(height: 12),
                    SkeletonLoader(width: double.infinity, height: 72),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
          SkeletonLoader(
            width: 48,
            height: 48,
            borderRadius: Spacing.radiusM,
          ),
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

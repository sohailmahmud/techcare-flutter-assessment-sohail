import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';

/// Skeleton loader widget matching dashboard UI structure
class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final double? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: Colors.white,
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
      ),
    );
  }
}

/// Dashboard skeleton loader
class DashboardSkeletonLoader extends StatelessWidget {
  const DashboardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(width: 120, height: 24),
              Row(
                children: [
                  SkeletonLoader(
                    width: 40,
                    height: 40,
                    borderRadius: Spacing.radiusFull,
                  ),
                  SizedBox(width: Spacing.space12),
                  SkeletonLoader(
                    width: 40,
                    height: 40,
                    borderRadius: Spacing.radiusFull,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Spacing.space24),

          // Balance card skeleton
          const SkeletonLoader(
            width: double.infinity,
            height: 200,
            borderRadius: Spacing.radiusL,
          ),
          const SizedBox(height: Spacing.space24),

          // Chart skeleton
          const SkeletonLoader(width: 150, height: 20),
          const SizedBox(height: Spacing.space16),
          const Center(
            child: SkeletonLoader(
              width: 200,
              height: 200,
              borderRadius: Spacing.radiusFull,
            ),
          ),
          const SizedBox(height: Spacing.space24),

          // Recent transactions skeleton
          const SkeletonLoader(width: 150, height: 20),
          const SizedBox(height: Spacing.space16),
          ...List.generate(
            5,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: Spacing.space12),
              child: SkeletonLoader(
                width: double.infinity,
                height: 72,
              ),
            ),
          ),
        ],
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

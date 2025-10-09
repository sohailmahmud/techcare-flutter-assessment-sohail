import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/spacing.dart';
import '../../../injection_container.dart' as di;
import '../bloc/analytics_bloc.dart';
import '../../../domain/entities/analytics.dart';
import '../widgets/period_selector.dart';
import '../widgets/summary_statistics_cards.dart';
import '../widgets/spending_trend_chart.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/budget_progress_indicators.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _refreshController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<AnalyticsBloc>()..add(const LoadAnalytics()),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(),
          body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () => _onRefresh(context),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(Spacing.space16),
                  child: _buildContent(context, state),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Analytics',
        style: AppTypography.titleLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        BlocBuilder<AnalyticsBloc, AnalyticsState>(
          builder: (context, state) {
            if (state is AnalyticsLoaded) {
              return IconButton(
                onPressed: () => _onRefresh(context),
                icon: AnimatedBuilder(
                  animation: _refreshController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _refreshController.value * 2 * 3.14159,
                      child: Icon(
                        Icons.refresh_rounded,
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
                tooltip: 'Refresh',
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(width: Spacing.space8),
      ],
    );
  }

  Widget _buildContent(BuildContext context, AnalyticsState state) {
    if (state is AnalyticsLoading) {
      return _buildLoadingState();
    }

    if (state is AnalyticsError) {
      return _buildErrorState(context, state.message);
    }

    if (state is AnalyticsLoaded) {
      return _buildLoadedState(context, state.data);
    }

    return _buildInitialState(context);
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
            const SizedBox(height: Spacing.space24),
            Text(
              'Loading Analytics...',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: Spacing.space8),
            Text(
              'Analyzing your financial data',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: Spacing.space24),
            Text(
              'Something went wrong',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.space8),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.space24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AnalyticsBloc>().add(const LoadAnalytics());
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.space24,
                  vertical: Spacing.space12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: Spacing.space24),
            Text(
              'Welcome to Analytics',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.space8),
            Text(
              'Get insights into your spending patterns',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.space24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AnalyticsBloc>().add(const LoadAnalytics());
              },
              icon: const Icon(Icons.insights_rounded),
              label: const Text('Get Started'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.space24,
                  vertical: Spacing.space12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, AnalyticsData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Prevent excessive height
      children: [
        // Period Selector
        PeriodSelector(
          selectedPeriod: data.period,
          dateRange: data.dateRange,
          onPeriodChanged: (period) {
            context.read<AnalyticsBloc>().add(ChangePeriod(period));
          },
          onCustomRangeChanged: (range) {
            context.read<AnalyticsBloc>().add(
              ChangePeriod(TimePeriod.custom, customRange: range),
            );
          },
        ),
        
        const SizedBox(height: Spacing.space16), // Reduced spacing
        
        // Summary Statistics
        ResponsiveSummaryStats(statistics: data),
        
        const SizedBox(height: Spacing.space16), // Reduced spacing
        
        // Spending Trend Chart with constrained height
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: SpendingTrendChart(
            trendData: data.trendData,
            isLoading: false,
          ),
        ),
        
        const SizedBox(height: Spacing.space16), // Reduced spacing
        
        // Category Breakdown and Budget Progress (side by side on tablets/desktop)
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 768) {
              // Desktop/Tablet layout - side by side
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CategoryBreakdownChart(
                        categoryData: data.categoryBreakdown,
                        isLoading: false,
                      ),
                    ),
                    const SizedBox(width: Spacing.space16),
                    Expanded(
                      child: BudgetProgressIndicators(
                        budgetData: data.budgetComparisons,
                        isLoading: false,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Mobile layout - stacked with constrained heights
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CategoryBreakdownChart(
                      categoryData: data.categoryBreakdown,
                      isLoading: false,
                    ),
                  const SizedBox(height: Spacing.space16),
                  BudgetProgressIndicators(
                      budgetData: data.budgetComparisons,
                      isLoading: false,
                    ),
                ],
              );
            }
          },
        ),
        
        // Bottom spacing for better scroll experience - adjusted for mobile
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.1,
        ),
      ],
    );
  }

  Future<void> _onRefresh(BuildContext context) async {
    _refreshController.forward();
    context.read<AnalyticsBloc>().add(const RefreshAnalytics());
    
    // Wait for the animation to complete
    await _refreshController.forward();
    _refreshController.reset();
  }

}

/// Extension for responsive design breakpoints
extension ResponsiveBreakpoints on BuildContext {
  bool get isTablet => MediaQuery.of(this).size.width >= 768;
  bool get isDesktop => MediaQuery.of(this).size.width >= 1024;
  bool get isMobile => MediaQuery.of(this).size.width < 768;
}
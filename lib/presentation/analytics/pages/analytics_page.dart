import 'package:fintrack/data/datasources/asset_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/category.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/spacing.dart';
import '../../../injection_container.dart' as di;
import '../../../domain/repositories/category_repository.dart';
import '../../transactions/list/bloc/transactions_bloc.dart';
import '../bloc/analytics_bloc.dart';
import '../../../domain/entities/analytics.dart';
import '../widgets/period_selector.dart';
import '../widgets/summary_statistics_cards.dart';
import '../widgets/spending_trend_chart.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/budget_progress_indicators.dart';
import '../../../core/widgets/skeleton_loader.dart';

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
    return FutureBuilder<List<Category>>(
      future: _loadCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildScaffold(
            body: const Center(child: AnalyticsSkeletonLoader()),
          );
        }
        final categories = snapshot.data ?? [];
        return BlocProvider(
          create: (context) => AnalyticsBloc(
            transactionsBloc: di.sl<TransactionsBloc>(),
            categories: categories,
          )..add(const ChangePeriod(TimePeriod.thisWeek)),
          child: BlocListener<TransactionsBloc, TransactionsState>(
            listener: (context, state) {
              // Refresh analytics when transactions are added/updated/deleted
              if (state is TransactionOperationSuccess) {
                context.read<AnalyticsBloc>().add(const RefreshAnalytics());
              }
            },
            child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
              builder: (context, state) {
                if (state is AnalyticsLoading) {
                  return _buildScaffold(
                    body: const Center(child: AnalyticsSkeletonLoader()),
                  );
                }
                return _buildScaffold(
                  body: RefreshIndicator(
                    onRefresh: () => _onRefresh(context),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(Spacing.space16),
                      child: _buildContent(context, state),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<List<Category>> _loadCategories() async {
    // Prefer loading categories from repository (ensures single source of truth)
    try {
      final CategoryRepository categoryRepo = di.sl<CategoryRepository>();
      final result = await categoryRepo.getCategories();

      // If repository returned categories, use them when non-empty
      if (result.isRight()) {
        final cats = result.getOrElse(() => <Category>[]);
        if (cats.isNotEmpty) return cats;
      }

      // If repo returned Left or empty list, try cached categories from repository
      try {
        final cachedRes = await categoryRepo.getCachedCategories();
        if (cachedRes.isRight()) {
          final cached = cachedRes.getOrElse(() => <Category>[]);
          if (cached.isNotEmpty) return cached;
        }
      } catch (_) {
        // ignore and fallback to asset
      }

      // Fallback to asset data if repository didn't provide categories
    } catch (e) {
      // In case of an exception using the repository, fall back to asset below
    }

    final AssetDataSource assetDataSource = AssetDataSource();
    final categoriesResponse = await assetDataSource.getCategories();
    if (categoriesResponse.categories.isNotEmpty) {
      return categoriesResponse.categories
          .map((model) => model.toEntity())
          .toList();
    }

    return <Category>[];
  }

  Widget _buildScaffold({required Widget body}) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
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
        body: body,
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
    );
  }

  Widget _buildContent(BuildContext context, AnalyticsState state) {
    if (state is AnalyticsLoading) {
      return _buildLoadingWidget(
        title: 'Loading Analytics...',
        subtitle: 'Analyzing your financial data',
      );
    }

    if (state is AnalyticsError) {
      return _buildErrorWidget(
        context,
        state.message,
        onRetry: () => context.read<AnalyticsBloc>().add(const LoadAnalytics()),
        title: 'Something went wrong',
      );
    }

    if (state is AnalyticsLoaded) {
      return _buildLoadedState(context, state.data);
    }
    return const SizedBox.shrink();
  }

  Widget _buildLoadingWidget({String? title, String? subtitle}) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
            if (title != null) ...[
              const SizedBox(height: Spacing.space24),
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (subtitle != null) ...[
              const SizedBox(height: Spacing.space8),
              Text(
                subtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
    String? title,
  }) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: Spacing.space24),
            if (title != null)
              Text(
                title,
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (title != null) const SizedBox(height: Spacing.space8),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.space24),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
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

  Widget _buildLoadedState(BuildContext context, AnalyticsData data) {
    // Calculate previous period for percentage change
    final previousData = data.trendData;
    double previousIncome = 0.0;
    double previousExpenses = 0.0;
    double previousNetBalance = 0.0;
    if (previousData.incomePoints.length > 1) {
      previousIncome =
          previousData.incomePoints[previousData.incomePoints.length - 2].value;
    }
    if (previousData.expensePoints.length > 1) {
      previousExpenses = previousData
          .expensePoints[previousData.expensePoints.length - 2]
          .value;
    }
    previousNetBalance = previousIncome - previousExpenses;

    double pctChange(double current, double previous) {
      if (previous == 0) return 0.0;
      return ((current - previous) / previous) * 100;
    }

    final incomeChange = pctChange(data.totalIncome, previousIncome);
    final expenseChange = pctChange(data.totalExpenses, previousExpenses);
    final netBalanceChange = pctChange(data.netBalance, previousNetBalance);

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
        ResponsiveSummaryStats(
          statistics: data,
          incomeChange: incomeChange,
          expenseChange: expenseChange,
          netBalanceChange: netBalanceChange,
        ),

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
                        categories: data.categories,
                        isLoading: false,
                      ),
                    ),
                    const SizedBox(width: Spacing.space16),
                    Expanded(
                      child: BudgetProgressIndicators(
                        budgetData: data.budgetComparisons,
                        categories: data.categories,
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
                    categories: data.categories,
                    isLoading: false,
                  ),
                  const SizedBox(height: Spacing.space16),
                  BudgetProgressIndicators(
                    budgetData: data.budgetComparisons,
                    categories: data.categories,
                    isLoading: false,
                  ),
                ],
              );
            }
          },
        ),

        // Bottom spacing for better scroll experience - adjusted for mobile
        SizedBox(height: MediaQuery.of(context).size.height * 0.1),
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

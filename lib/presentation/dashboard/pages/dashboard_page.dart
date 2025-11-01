import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/speed_dial_fab.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../domain/entities/transaction.dart' as tx;
import '../../../injection_container.dart' as di;
import '../../transactions/list/bloc/transactions_bloc.dart';
import '../../transactions/list/widgets/transaction_details_modal.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/spending_pie_chart.dart';
import '../../../domain/entities/transaction.dart';
import '../widgets/recent_transactions_list.dart';

/// Dashboard page showing user's financial overview with BLoC state management
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<DashboardBloc>()..add(const LoadDashboard()),
      child: BlocListener<TransactionsBloc, TransactionsState>(
        listener: (context, state) {
          // Refresh dashboard when transactions are added/updated/deleted
          if (state is TransactionOperationSuccess) {
            context.read<DashboardBloc>().add(const RefreshDashboardData());
          }
        },
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
            extendBodyBehindAppBar: true,
            body: Stack(
              children: [
                BlocBuilder<DashboardBloc, DashboardState>(
                  builder: (context, state) {
                    // Show full skeleton loader for initial loading
                    if (state is DashboardInitial ||
                        state is DashboardLoading) {
                      //return const DashboardSkeletonLoader();
                      // need to use current buildHeader for better ux in skeleton
                      return CustomScrollView(
                        physics:
                            const AlwaysScrollableScrollPhysics(), // Ensure scroll works even with short content
                        slivers: [
                          _buildHeader(),
                          SliverList(
                            delegate: SliverChildListDelegate([
                              const SizedBox(height: Spacing.space16),
                              DashboardSkeletonLoaders.balanceCard(),
                              const SizedBox(height: Spacing.space16),
                              DashboardSkeletonLoaders.spendingChart(),
                              const SizedBox(height: Spacing.space24),
                              DashboardSkeletonLoaders.transactionsSection(),
                              const SizedBox(height: Spacing.space16),
                            ]),
                          ),
                        ],
                      );
                    }

                    // Show error state
                    if (state is DashboardError) {
                      return Center(
                        child: _buildErrorWidget(
                          state.message,
                          onRetry: () => context.read<DashboardBloc>().add(
                            const RetryLoadDashboard(),
                          ),
                          iconSize: 32,
                          title: 'Oops! Something went wrong',
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        final completer = Completer<void>();
                        context.read<DashboardBloc>().add(
                          const RefreshDashboardData(),
                        );

                        // Listen for state changes to complete refresh
                        final subscription = context
                            .read<DashboardBloc>()
                            .stream
                            .listen((newState) {
                              if (newState is DashboardLoaded ||
                                  newState is DashboardError) {
                                if (!completer.isCompleted) {
                                  completer.complete();
                                }
                              }
                            });

                        // Timeout after reasonable time
                        Timer(AppConstants.refreshDelay * 2, () {
                          if (!completer.isCompleted) {
                            completer.complete();
                          }
                          subscription.cancel();
                        });

                        await completer.future;
                        subscription.cancel();
                      },
                      displacement: 40.0, // Adjust position to work with header
                      strokeWidth: 2.5,
                      backgroundColor: AppColors.surface,
                      color: AppColors.primary,
                      child: CustomScrollView(
                        physics:
                            const AlwaysScrollableScrollPhysics(), // Ensure scroll works even with short content
                        slivers: [
                          _buildHeader(),
                          _buildContent(state, context),
                        ],
                      ),
                    );
                  },
                ),
                // Custom Speed Dial FAB with backdrop
                _buildSpeedDialWithBackdrop(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return SliverPersistentHeader(
      pinned: true,
      floating: false,
      delegate: _ParallaxHeaderDelegate(
        expandedHeight: Spacing.headerExpandedHeight + statusBarHeight,
        collapsedHeight: kToolbarHeight + statusBarHeight,
      ),
    );
  }

  Widget _buildContent(DashboardState state, BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: Spacing.space16),
        _buildBalanceSection(state),
        const SizedBox(height: Spacing.space16),
        _buildSpendingChart(state, context),
        const SizedBox(height: Spacing.space16),
        _buildTransactionsSection(state),
        const SizedBox(height: Spacing.space16),
      ]),
    );
  }

  Widget buildSection({
    required Widget Function(BuildContext, DashboardState) builder,
    EdgeInsetsGeometry? padding,
  }) {
    return Padding(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: Spacing.space16),
      child: BlocBuilder<DashboardBloc, DashboardState>(builder: builder),
    );
  }

  Widget _buildBalanceSection(DashboardState state) {
    return buildSection(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return DashboardSkeletonLoaders.balanceCard();
        } else if (state is DashboardLoaded) {
          return GestureDetector(
            onTap: () {
              context.read<DashboardBloc>().add(
                const ToggleBalanceVisibility(),
              );
            },
            child: BalanceCard(
              balance: state.summary.totalBalance,
              monthlyIncome: state.summary.monthlyIncome,
              monthlyExpense: state.summary.monthlyExpense,
              initiallyVisible: state.isBalanceVisible,
            ),
          );
        } else if (state is DashboardError) {
          return _buildErrorWidget(
            state.message,
            onRetry: () =>
                context.read<DashboardBloc>().add(const RetryLoadDashboard()),
            iconSize: 32,
            title: 'Oops! Something went wrong',
          );
        }
        return const BalanceCard(
          balance: 0,
          monthlyIncome: 0,
          monthlyExpense: 0,
        );
      },
    );
  }

  Widget _buildSpendingChart(DashboardState state, BuildContext context) {
    return buildSection(
      builder: (context, state) {
        if (state is DashboardLoaded) {
          return SpendingPieChart(
            categories: state.summary.categoryExpenses,
            selectedCategory: state.selectedCategoryFilter,
            onCategorySelected: (categoryId) {
              context.read<DashboardBloc>().add(
                SelectTransactionFilter(categoryId: categoryId),
              );
            },
          );
        } else if (state is DashboardLoading) {
          return DashboardSkeletonLoaders.spendingChart();
        } else if (state is DashboardError) {
          return _buildErrorWidget(state.message, iconSize: 32);
        }
        return SizedBox(
          height: Spacing.pieChartHeight,
          child: Center(
            child: Text(
              'No spending data available',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsSection(DashboardState state) {
    return buildSection(
      builder: (context, state) {
        final isLoading = state is DashboardLoading;
        final transactions = state is DashboardLoaded
            ? state.filteredTransactions.cast<Transaction>()
            : <Transaction>[];

        return RecentTransactionsList(
          transactions: transactions,
          isLoading: isLoading,
          maxItems: AppConstants.maxRecentTransactions, // Limit for dashboard
          enableLazyLoading: false, // Disable for dashboard - use on full page
          onEdit: _onEditTransaction,
          onDelete: _onDeleteTransaction,
          onTransactionTap: _onTransactionTap,
          onViewAll: () {
            // Navigate to transactions tab using go_router
            context.goToTransactions();
          },
        );
      },
    );
  }

  Widget _buildErrorWidget(
    String message, {
    VoidCallback? onRetry,
    double iconSize = 48,
    String? title,
  }) {
    return GlassMorphicContainer(
      padding: const EdgeInsets.all(Spacing.space24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: iconSize),
          const SizedBox(height: Spacing.space16),
          if (title != null)
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          if (title != null) const SizedBox(height: Spacing.space8),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: Spacing.space24),
            ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ],
      ),
    );
  }

  Widget _buildSpeedDialWithBackdrop() {
    return Stack(
      children: [
        // Speed Dial FAB positioned at exact bottom right location
        Positioned(
          bottom: 16.0,
          right: 16.0,
          child: GestureDetector(
            child: SpeedDialFAB(
              icon: Icons.add,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              actions: [
                SpeedDialAction(
                  icon: Icons.add,
                  label: 'Add Income',
                  backgroundColor: AppColors.success,
                  onPressed: () =>
                      _navigateToAddTransaction(TransactionType.income),
                ),
                SpeedDialAction(
                  icon: Icons.remove,
                  label: 'Add Expense',
                  backgroundColor: AppColors.error,
                  onPressed: () =>
                      _navigateToAddTransaction(TransactionType.expense),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToAddTransaction(TransactionType type) {
    // Navigate to add transaction screen using go_router with source page info
    context.goToAddTransaction(type: type, sourcePage: 'dashboard');
  }

  void _showEditTransaction(tx.Transaction transaction) {
    // need to route with go_router to keep the back stack correct
    context.goToEditTransaction(
      transaction: transaction,
      transactionId: transaction.id,
      sourcePage: 'transactions',
    );
  }

  void _showTransactionDetails(tx.Transaction transaction) {
    // Navigator.of(context).push(
    //   PageRouteBuilder(
    //     opaque: false,
    //     barrierColor: Colors.black.withValues(alpha: 0.5),
    //     pageBuilder: (context, animation, secondaryAnimation) =>
    //         TransactionDetailsModal(
    //       transaction: transaction,
    //       heroTag: 'transaction_amount_${transaction.id}_transactions_page',
    //       sourcePage: 'transactions',
    //     ),
    //     transitionDuration: const Duration(milliseconds: 300),
    //     reverseTransitionDuration: const Duration(milliseconds: 250),
    //     transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //       return FadeTransition(
    //         opacity: animation,
    //         child: child,
    //       );
    //     },
    //   ),
    // );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailsModal(
        transaction: transaction,
        sourcePage: 'transactions',
      ),
    );
  }

  void _onDeleteTransaction(tx.Transaction transaction) {
    context.read<TransactionsBloc>().add(DeleteTransaction(transaction.id));
  }

  void _onEditTransaction(tx.Transaction transaction) {
    _showEditTransaction(transaction);
  }

  void _onTransactionTap(tx.Transaction transaction) {
    _showTransactionDetails(transaction);
  }
}

/// Custom parallax header delegate for smooth scrolling effects
class _ParallaxHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double collapsedHeight;

  _ParallaxHeaderDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      return 'Good night!';
    } else if (hour < 12) {
      return 'Good morning!';
    } else if (hour < 17) {
      return 'Good afternoon!';
    } else if (hour < 22) {
      return 'Good evening!';
    } else {
      return 'Good night!';
    }
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = shrinkOffset / (expandedHeight - collapsedHeight);
    final clampedProgress = progress.clamp(0.0, 1.0);
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background with parallax effect
        _buildParallaxBackground(shrinkOffset),

        // Content with fade and slide animations
        _buildHeaderContent(context, clampedProgress, statusBarHeight),

        // Collapsed app bar with app name
        _buildCollapsedAppBar(context, clampedProgress, statusBarHeight),

        // Gradient overlay for better text contrast
        _buildGradientOverlay(clampedProgress),
      ],
    );
  }

  Widget _buildParallaxBackground(double shrinkOffset) {
    // Enhanced parallax offset with smoother curve
    final progress = (shrinkOffset / (expandedHeight - collapsedHeight)).clamp(
      0.0,
      1.0,
    );
    final parallaxOffset = shrinkOffset * 0.3; // Reduced for smoother effect
    final scaleProgress = 1.0 - (progress * 0.1); // Subtle scaling effect

    return Positioned(
      top: -parallaxOffset,
      left: 0,
      right: 0,
      height:
          expandedHeight +
          parallaxOffset +
          50, // Extra height for better coverage
      child: Transform.scale(
        scale: scaleProgress,
        alignment: Alignment.topCenter,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(
                  alpha: 0.15 * (1.0 - progress * 0.5),
                ),
                AppColors.secondary.withValues(
                  alpha: 0.08 * (1.0 - progress * 0.3),
                ),
                AppColors.background,
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: _HeaderPatternPainter(opacity: 1.0 - progress * 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent(
    BuildContext context,
    double progress,
    double statusBarHeight,
  ) {
    // Enhanced animation curves for smoother transitions - fade out earlier to prevent overflow
    final titleOpacity = (1.0 - progress * 2.0).clamp(0.0, 1.0);
    final subtitleOpacity = (1.0 - progress * 2.5).clamp(0.0, 1.0);
    final translateY = progress * 10; // Reduced translation
    final scaleTransform = 1.0 - (progress * 0.03); // Subtle scale effect

    // Hide content completely when almost collapsed to prevent overflow
    if (progress > 0.8) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: Spacing.space16,
      right: Spacing.space16,
      top: statusBarHeight + 16, // Fixed position below status bar
      child: Transform.scale(
        scale: scaleTransform,
        child: Transform.translate(
          offset: Offset(0, translateY),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedOpacity(
                      opacity: titleOpacity,
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        'FinTracker',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedOpacity(
                      opacity: subtitleOpacity,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _getGreeting(),
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: subtitleOpacity,
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        'Track your expenses smartly',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BlocBuilder<DashboardBloc, DashboardState>(
                    builder: (context, state) {
                      int notificationCount = 0;
                      if (state is DashboardLoaded) {
                        // Calculate notification count based on recent transactions (last 3 days for better visibility)
                        notificationCount = state.filteredTransactions
                            .where(
                              (t) =>
                                  DateTime.now().difference(t.date).inDays <= 3,
                            )
                            .length;

                        // For demo purposes, ensure there's always at least 1 notification
                        if (notificationCount == 0 &&
                            state.filteredTransactions.isNotEmpty) {
                          notificationCount = state.filteredTransactions.length
                              .clamp(1, 5);
                        }
                      }
                      return _buildNotificationBadge(
                        context: context,
                        count: notificationCount,
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildProfileAvatar(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay(double progress) {
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: progress * 0.4, // Slightly more pronounced for smaller header
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.0),
                AppColors.background.withValues(alpha: 0.6),
                AppColors.background.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedAppBar(
    BuildContext context,
    double progress,
    double statusBarHeight,
  ) {
    final collapsedOpacity =
        (progress - 0.5).clamp(0.0, 1.0) * 2.0; // Start showing at 50% collapse

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: statusBarHeight + kToolbarHeight,
      child: AnimatedOpacity(
        opacity: collapsedOpacity,
        duration: const Duration(milliseconds: 200),
        child: ClipRRect(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: statusBarHeight,
                left: Spacing.space16,
                right: Spacing.space16,
              ),
              child: SizedBox(
                height: kToolbarHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'FinTracker',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: 0.85,
                          child: BlocBuilder<DashboardBloc, DashboardState>(
                            builder: (context, state) {
                              int notificationCount = 0;
                              if (state is DashboardLoaded) {
                                notificationCount = state.filteredTransactions
                                    .where(
                                      (t) =>
                                          DateTime.now()
                                              .difference(t.date)
                                              .inDays <=
                                          3,
                                    )
                                    .length;

                                if (notificationCount == 0 &&
                                    state.filteredTransactions.isNotEmpty) {
                                  notificationCount = state
                                      .filteredTransactions
                                      .length
                                      .clamp(1, 5);
                                }
                              }

                              return _buildNotificationBadge(
                                context: context,
                                count: notificationCount > 0
                                    ? notificationCount
                                    : 3, // fallback for demo parity
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Transform.scale(
                          scale: 0.85,
                          child: _buildProfileAvatar(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBadge({
    required BuildContext context,
    int count = 0,
  }) {
    // Force notification badge for demo (remove this in production)
    int displayCount = count > 0 ? count : 3;

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have $displayCount notifications!'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.primary,
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Spacing.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                if (count > 0)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Icon(
              displayCount > 0
                  ? Icons.notifications_active
                  : Icons.notifications_outlined,
              color: displayCount > 0
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: 24,
            ),
          ),
          if (displayCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    displayCount > 99 ? '99+' : displayCount.toString(),
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile page coming soon!'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Spacing.radiusXL),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Spacing.radiusXL),
          child: Image.asset(
            'assets/images/profile_placeholder.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.secondary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(Spacing.radiusXL),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: Spacing.iconM,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate is! _ParallaxHeaderDelegate ||
        oldDelegate.expandedHeight != expandedHeight ||
        oldDelegate.collapsedHeight != collapsedHeight;
  }
}

/// Custom painter for header background pattern
class _HeaderPatternPainter extends CustomPainter {
  final double opacity;

  const _HeaderPatternPainter({this.opacity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.03 * opacity)
      ..style = PaintingStyle.fill;

    // Draw subtle geometric pattern
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.6;

    // Create curved shapes for subtle background pattern
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * 3.14159) / 3;
      final x = centerX + radius * 0.7 * (i * 0.3) * math.cos(angle);
      final y = centerY + radius * 0.5 * (i * 0.2) * math.sin(angle);

      path.addOval(
        Rect.fromCircle(center: Offset(x, y), radius: 80 - (i * 20)),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

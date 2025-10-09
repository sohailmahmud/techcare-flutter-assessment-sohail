import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/router/app_routes.dart';

/// App navigation shell providing bottom navigation bar
/// Provides navigation between Dashboard, Transactions, and Analytics screens
class AppNavigationPage extends StatefulWidget {
  final Widget child;
  
  const AppNavigationPage({
    super.key,
    required this.child,
  });

  @override
  State<AppNavigationPage> createState() => _AppNavigationPageState();
}

class _AppNavigationPageState extends State<AppNavigationPage> {
  
  int get _calculateSelectedIndex {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location == AppRoutes.transactions) return 1;
    if (location == AppRoutes.analytics) return 2;
    return 0; // dashboard
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _calculateSelectedIndex,
          onDestinationSelected: _onDestinationSelected,
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          elevation: 0,
          height: 80,
          destinations: _buildNavigationDestinations(),
        ),
      ),
    );
  }

  void _onDestinationSelected(int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.transactions);
        break;
      case 2:
        context.go(AppRoutes.analytics);
        break;
    }
  }

  List<NavigationDestination> _buildNavigationDestinations() {
    final selectedIndex = _calculateSelectedIndex;
    return [
      NavigationDestination(
        icon: Icon(
          Icons.dashboard_outlined,
          color: selectedIndex == 0 ? AppColors.primary : AppColors.textSecondary,
        ),
        selectedIcon: const Icon(
          Icons.dashboard,
          color: AppColors.primary,
        ),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(
          Icons.receipt_long_outlined,
          color: selectedIndex == 1 ? AppColors.primary : AppColors.textSecondary,
        ),
        selectedIcon: const Icon(
          Icons.receipt_long,
          color: AppColors.primary,
        ),
        label: 'Transactions',
      ),
      NavigationDestination(
        icon: Icon(
          Icons.analytics_outlined,
          color: selectedIndex == 2 ? AppColors.primary : AppColors.textSecondary,
        ),
        selectedIcon: const Icon(
          Icons.analytics,
          color: AppColors.primary,
        ),
        label: 'Analytics',
      ),
    ];
  }
}

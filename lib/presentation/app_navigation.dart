import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'analytics/pages/analytics_page.dart';
import 'dashboard/pages/dashboard_page.dart';
import 'transactions/pages/transactions_page.dart';

/// App navigation shell providing bottom navigation bar
/// Provides navigation between Dashboard, Transactions, and Analytics screens
class AppNavigationPage extends StatefulWidget {
  const AppNavigationPage({super.key});

  @override
  State<AppNavigationPage> createState() => _AppNavigationPageState();
}

class _AppNavigationPageState extends State<AppNavigationPage> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    DashboardPage(),
    TransactionsPage(),
    AnalyticsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
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
          selectedIndex: _currentIndex,
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
    setState(() {
      _currentIndex = index;
    });
  }

  List<NavigationDestination> _buildNavigationDestinations() {
    return [
      NavigationDestination(
        icon: Icon(
          Icons.dashboard_outlined,
          color: _currentIndex == 0 ? AppColors.primary : AppColors.textSecondary,
        ),
        selectedIcon: Icon(
          Icons.dashboard,
          color: AppColors.primary,
        ),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(
          Icons.receipt_long_outlined,
          color: _currentIndex == 1 ? AppColors.primary : AppColors.textSecondary,
        ),
        selectedIcon: Icon(
          Icons.receipt_long,
          color: AppColors.primary,
        ),
        label: 'Transactions',
      ),
      NavigationDestination(
        icon: Icon(
          Icons.analytics_outlined,
          color: _currentIndex == 2 ? AppColors.primary : AppColors.textSecondary,
        ),
        selectedIcon: Icon(
          Icons.analytics,
          color: AppColors.primary,
        ),
        label: 'Analytics',
      ),
    ];
  }
}

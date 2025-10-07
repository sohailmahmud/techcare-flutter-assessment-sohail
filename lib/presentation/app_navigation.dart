import 'package:flutter/material.dart';
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _buildNavigationDestinations(),
      ),
    );
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<NavigationDestination> _buildNavigationDestinations() {
    return const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.list_alt_outlined),
        selectedIcon: Icon(Icons.list_alt),
        label: 'Transactions',
      ),
      NavigationDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics),
        label: 'Analytics',
      ),
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/app_navigation.dart';
import '../../presentation/dashboard/pages/dashboard_page.dart';
import '../../presentation/transactions/list/pages/transactions_page.dart';
import '../../presentation/transactions/form/pages/add_edit_transaction_screen.dart';
import '../../presentation/transactions/list/widgets/transaction_details_modal.dart';
import '../../presentation/analytics/pages/analytics_page.dart';
import '../../domain/entities/transaction.dart';
import 'app_routes.dart';

/// Global navigator key for programmatic navigation
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

/// App router configuration using go_router
class AppRouter {
  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: true,
    routes: [
      // Shell route for bottom navigation
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return AppNavigationPage(child: child);
        },
        routes: [
          // Dashboard route
          GoRoute(
            path: AppRoutes.dashboard,
            name: AppRoutes.dashboardName,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardPage(),
            ),
          ),

          // Transactions route
          GoRoute(
            path: AppRoutes.transactions,
            name: AppRoutes.transactionsName,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TransactionsPage(),
            ),
          ),

          // Analytics route
          GoRoute(
            path: AppRoutes.analytics,
            name: AppRoutes.analyticsName,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsPage(),
            ),
          ),
        ],
      ),

      // Full screen routes (outside shell)
      GoRoute(
        path: AppRoutes.addTransaction,
        name: AppRoutes.addTransactionName,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final transaction = extra?['transaction'] as Transaction?;
          return MaterialPage(
            child: AddEditTransactionScreen(
              transaction: transaction,
            ),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.editTransaction,
        name: AppRoutes.editTransactionName,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final transaction = extra?['transaction'] as Transaction?;

          return MaterialPage(
            child: AddEditTransactionScreen(
              transaction: transaction,
            ),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.transactionDetails,
        name: AppRoutes.transactionDetailsName,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final transaction = extra?['transaction'] as Transaction;
          final sourcePage = extra?['sourcePage'] as String?;

          return MaterialPage(
            child: TransactionDetailsModal(
              transaction: transaction,
              sourcePage: sourcePage,
            ),
          );
        },
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.matchedLocation}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),

    // Route redirection logic
    redirect: (context, state) {
      // Add any authentication or conditional routing logic here
      return null; // No redirection needed for now
    },
  );
}

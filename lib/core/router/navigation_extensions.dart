import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/transaction.dart';
import 'app_routes.dart';

/// Navigation extensions for easier routing
extension AppNavigation on BuildContext {
  
  // Dashboard navigation
  void goToDashboard() => go(AppRoutes.dashboard);
  
  // Transactions navigation
  void goToTransactions() => go(AppRoutes.transactions);
  
  // Analytics navigation
  void goToAnalytics() => go(AppRoutes.analytics);
  
  // Add transaction
  void goToAddTransaction({
    Transaction? transaction,
    String? sourcePage,
  }) {
    final extra = <String, dynamic>{};
    if (transaction != null) {
      extra['transaction'] = transaction;
    }
    if (sourcePage != null) {
      extra['sourcePage'] = sourcePage;
    }
    
    go(
      AppRoutes.addTransaction,
      extra: extra.isNotEmpty ? extra : null,
    );
  }
  
  // Edit transaction
  void goToEditTransaction({
    required String transactionId,
    Transaction? transaction,
    String? sourcePage,
  }) {
    final extra = <String, dynamic>{};
    if (transaction != null) {
      extra['transaction'] = transaction;
    }
    if (sourcePage != null) {
      extra['sourcePage'] = sourcePage;
    }
    
    go(
      AppRoutes.editTransaction.withId(transactionId),
      extra: extra.isNotEmpty ? extra : null,
    );
  }
  
  // Transaction details
  void goToTransactionDetails({
    required String transactionId,
    required Transaction transaction,
  }) {
    go(
      AppRoutes.transactionDetails.withId(transactionId),
      extra: {'transaction': transaction},
    );
  }
  
  // Debug
  void goToCacheDebug() => go(AppRoutes.cacheDebug);
  
  // Navigation with replacement
  void goAndReplace(String route) => pushReplacement(route);
  
  // Navigation with clear stack
  void goAndClearStack(String route) {
    while (canPop()) {
      pop();
    }
    go(route);
  }
}

/// Route information helper
extension RouteInfo on BuildContext {
  String get currentRoute => GoRouterState.of(this).matchedLocation;
  
  bool get isOnDashboard => currentRoute == AppRoutes.dashboard;
  bool get isOnTransactions => currentRoute == AppRoutes.transactions;
  bool get isOnAnalytics => currentRoute == AppRoutes.analytics;
  
  Map<String, String> get pathParameters => GoRouterState.of(this).pathParameters;
  Map<String, String> get queryParameters => GoRouterState.of(this).uri.queryParameters;
}
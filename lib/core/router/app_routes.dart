/// App route constants for navigation
class AppRoutes {
  // Route paths
  static const String dashboard = '/';
  static const String transactions = '/transactions';
  static const String analytics = '/analytics';
  static const String addTransaction = '/add-transaction';
  static const String editTransaction = '/edit-transaction/:id';
  static const String transactionDetails = '/transaction-details/:id';
  static const String cacheDebug = '/cache-debug';

  // Route names
  static const String dashboardName = 'dashboard';
  static const String transactionsName = 'transactions';
  static const String analyticsName = 'analytics';
  static const String addTransactionName = 'addTransaction';
  static const String editTransactionName = 'editTransaction';
  static const String transactionDetailsName = 'transactionDetails';
  static const String cacheDebugName = 'cacheDebug';
}

/// Route parameters
class RouteParams {
  static const String id = 'id';
}

/// Route extensions for easier navigation
extension AppRouteExtensions on String {
  String withId(String id) {
    return replaceAll(':id', id);
  }
}

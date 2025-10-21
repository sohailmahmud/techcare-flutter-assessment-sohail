/// App-wide constants
class AppConstants {
  // Private constructor to prevent instantiation
  const AppConstants._();

  // Animation Durations
  static const Duration listItemAnimation = Duration(milliseconds: 50);
  static const Duration flipAnimation = Duration(milliseconds: 600);
  static const Duration counterAnimation = Duration(milliseconds: 800);
  static const Duration chartAnimation = Duration(milliseconds: 1000);
  static const Duration speedDialAnimation = Duration(milliseconds: 250);
  static const Duration refreshDelay = Duration(milliseconds: 1000);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration modalTransition = Duration(milliseconds: 250);
  static const Duration debounceDuration = Duration(milliseconds: 300);

  // Cache expiry duration
  static const Duration cacheExpiry = Duration(minutes: 5);

  // Breakpoints for responsive design
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 900;
  static const double breakpointDesktop = 1200;

  // Minimum screen width
  static const double minScreenWidth = 320;

  // Notification constants
  static const int defaultNotificationCount = 3;

  // Transaction display limits
  static const int maxDisplayTransactions = 5;
  static const int maxRecentTransactions = 10;
}
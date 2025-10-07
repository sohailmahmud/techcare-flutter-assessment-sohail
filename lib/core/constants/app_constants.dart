/// App-wide constants
class AppConstants {
   // Private constructor to prevent instantiation
  const AppConstants._();

  // Animation Durations
  static const Duration itemAnimation = Duration(milliseconds: 60);
  static const Duration cardAnimation = Duration(milliseconds: 600);
  static const Duration counterAnimation = Duration(milliseconds: 800);
  static const Duration chartAnimation = Duration(milliseconds: 1000);

  // Cache expiry duration
  static const Duration cacheExpiry = Duration(minutes: 5);

  // Breakpoints for responsive design
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 900;
  static const double breakpointDesktop = 1200;

  // Minimum screen width
  static const double minScreenWidth = 320;
}

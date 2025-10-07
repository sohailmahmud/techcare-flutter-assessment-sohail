/// App-wide constants
class AppConstants {
  // Animation Durations
  static const Duration itemAnimation = Duration(milliseconds: 60);
  static const Duration cardAnimation = Duration(milliseconds: 600);
  static const Duration counterAnimation = Duration(milliseconds: 800);
  static const Duration chartAnimation = Duration(milliseconds: 1000);

  // Cache
  static const Duration cacheExpiry = Duration(minutes: 5);


  // Private constructor to prevent instantiation
  AppConstants._();
}

/// Date and time format constants
class DateFormats {
  static const String displayDate = 'MMM dd, yyyy';
  static const String displayDateTime = 'MMM dd, yyyy hh:mm a';
  static const String apiDate = 'yyyy-MM-dd';
  static const String apiDateTime = 'yyyy-MM-ddTHH:mm:ss';
  
  // Private constructor
  DateFormats._();
}

/// UI constants
class UIConstants {
  // Padding & Spacing
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;

  // Border Radius
  static const double radiusSM = 4.0;
  static const double radiusMD = 8.0;
  static const double radiusLG = 12.0;
  static const double radiusXL = 16.0;

  // Icon Sizes
  static const double iconSM = 16.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;

  // Private constructor
  UIConstants._();
}

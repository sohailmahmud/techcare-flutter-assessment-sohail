import 'package:fintrack/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import '../theme/spacing.dart';

/// Responsive utilities for adaptive layouts
class ResponsiveUtils {
  const ResponsiveUtils._();

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < AppConstants.breakpointMobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppConstants.breakpointMobile &&
        width < AppConstants.breakpointTablet;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppConstants.breakpointTablet;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return Spacing.space16;
    if (isTablet(context)) return Spacing.space24;
    return Spacing.space32;
  }

  static int getCrossAxisCount(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }
}
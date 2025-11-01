import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('animation durations are reasonable', () {
      expect(AppConstants.listItemAnimation.inMilliseconds, lessThan(1000));
      expect(AppConstants.flipAnimation.inMilliseconds, lessThan(1000));
      expect(AppConstants.counterAnimation.inMilliseconds, lessThan(1500));
      expect(AppConstants.chartAnimation.inMilliseconds, lessThan(2000));
      expect(AppConstants.speedDialAnimation.inMilliseconds, lessThan(500));
      expect(AppConstants.pageTransition.inMilliseconds, lessThan(500));
      expect(AppConstants.modalTransition.inMilliseconds, lessThan(500));
      expect(AppConstants.debounceDuration.inMilliseconds, lessThan(1000));
    });

    test('animation durations are positive', () {
      expect(AppConstants.listItemAnimation.inMilliseconds, greaterThan(0));
      expect(AppConstants.flipAnimation.inMilliseconds, greaterThan(0));
      expect(AppConstants.counterAnimation.inMilliseconds, greaterThan(0));
      expect(AppConstants.chartAnimation.inMilliseconds, greaterThan(0));
      expect(AppConstants.refreshDelay.inMilliseconds, greaterThan(0));
    });

    test('cache duration is reasonable', () {
      expect(AppConstants.cacheExpiry.inMinutes, greaterThan(0));
      expect(AppConstants.cacheExpiry.inHours, lessThan(24));
    });

    test('breakpoints are in ascending order', () {
      expect(
        AppConstants.breakpointMobile,
        lessThan(AppConstants.breakpointTablet),
      );
      expect(
        AppConstants.breakpointTablet,
        lessThan(AppConstants.breakpointDesktop),
      );
    });

    test('screen width constraints are valid', () {
      expect(AppConstants.minScreenWidth, greaterThan(0));
      expect(
        AppConstants.minScreenWidth,
        lessThan(AppConstants.breakpointMobile),
      );
    });

    test('transaction limits are reasonable', () {
      expect(AppConstants.maxDisplayTransactions, greaterThan(0));
      expect(AppConstants.maxRecentTransactions, greaterThan(0));
      expect(
        AppConstants.maxRecentTransactions,
        greaterThanOrEqualTo(AppConstants.maxDisplayTransactions),
      );
      expect(AppConstants.defaultNotificationCount, greaterThan(0));
    });

    test('constants are immutable', () {
      // Verify constants are compile-time constants
      const duration = AppConstants.counterAnimation;
      expect(duration, equals(const Duration(milliseconds: 800)));

      const expiry = AppConstants.cacheExpiry;
      expect(expiry, equals(const Duration(minutes: 5)));
    });
  });
}

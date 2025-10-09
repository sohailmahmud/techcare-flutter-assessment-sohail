import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/core/utils/formatters.dart';

void main() {
  group('Formatters Tests', () {
    group('Currency Formatting', () {
      test('should format currency with proper format', () {
        expect(CurrencyFormatter.format(1000), equals('৳1,000'));
        expect(CurrencyFormatter.format(12345), equals('৳12,345'));
        expect(CurrencyFormatter.format(1234567), equals('৳1,234,567'));
      });

      test('should handle zero and negative amounts', () {
        expect(CurrencyFormatter.format(0), equals('৳0'));
        expect(CurrencyFormatter.format(-1000), equals('-৳1,000'));
      });

      test('should handle decimal amounts by rounding', () {
        expect(CurrencyFormatter.format(100.50), equals('৳101'));
        expect(CurrencyFormatter.format(999.99), equals('৳1,000'));
        expect(CurrencyFormatter.format(100.49), equals('৳100'));
      });
    });

    group('Compact Currency Formatting', () {
      test('should format large amounts with compact notation', () {
        expect(CurrencyFormatter.formatCompact(1000), equals('৳1K'));
        expect(CurrencyFormatter.formatCompact(10000), equals('৳10K'));
        expect(CurrencyFormatter.formatCompact(100000), equals('৳100K'));
        expect(CurrencyFormatter.formatCompact(1000000), equals('৳1M'));
      });

      test('should handle small amounts', () {
        expect(CurrencyFormatter.formatCompact(999), equals('৳999'));
        expect(CurrencyFormatter.formatCompact(0), equals('৳0.0'));
      });
    });

    group('Date Formatting', () {
      test('should format date for display', () {
        final date = DateTime(2025, 10, 9);
        expect(DateFormatter.formatDisplay(date), equals('Oct 09, 2025'));
      });

      test('should format date with time', () {
        final date = DateTime(2025, 10, 9, 14, 30);
        expect(DateFormatter.formatDateTime(date),
            equals('Oct 09, 2025 02:30 PM'));
      });

      test('should format time only', () {
        final date = DateTime(2025, 10, 9, 14, 30);
        expect(DateFormatter.formatTime(date), equals('02:30 PM'));
      });

      test('should format API date', () {
        final date = DateTime(2025, 10, 9);
        expect(DateFormatter.formatApi(date), equals('2025-10-09'));
      });

      test('should format date grouping', () {
        final today = DateTime(2025, 10, 9, 10);
        final yesterday = DateTime(2025, 10, 8);
        final thisYear = DateTime(2025, 8, 15);
        final lastYear = DateTime(2024, 8, 15);

        expect(DateFormatter.formatDateGrouping(today), equals('Today'));
        expect(
            DateFormatter.formatDateGrouping(yesterday), equals('Yesterday'));
        expect(DateFormatter.formatDateGrouping(thisYear), equals('Aug 15'));
        expect(
            DateFormatter.formatDateGrouping(lastYear), equals('Aug 15, 2024'));
      });

      test('should format relative time', () {
        // Note: This test may be flaky due to time dependencies
        // In a real project, you'd want to mock DateTime.now()
        final now = DateTime.now();
        final minutesAgo = now.subtract(const Duration(minutes: 5));
        final hoursAgo = now.subtract(const Duration(hours: 2));
        final yesterday = now.subtract(const Duration(days: 1));
        final weekAgo = now.subtract(const Duration(days: 7));

        expect(DateFormatter.formatRelative(minutesAgo), equals('5m ago'));
        expect(DateFormatter.formatRelative(hoursAgo), equals('2h ago'));
        expect(DateFormatter.formatRelative(yesterday), equals('Yesterday'));
        // formatRelative falls back to formatDisplay for older dates
        expect(DateFormatter.formatRelative(weekAgo), contains('2025'));
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/domain/entities/analytics.dart';

void main() {
  group('TimePeriod Enum', () {
    test('should have all expected values', () {
      expect(TimePeriod.values, contains(TimePeriod.thisWeek));
      expect(TimePeriod.values, contains(TimePeriod.thisMonth));
      expect(TimePeriod.values, contains(TimePeriod.lastThreeMonths));
      expect(TimePeriod.values, contains(TimePeriod.custom));
    });

    group('displayName extension', () {
      test('should return correct display names', () {
        expect(TimePeriod.thisWeek.displayName, equals('This Week'));
        expect(TimePeriod.thisMonth.displayName, equals('This Month'));
        expect(TimePeriod.lastThreeMonths.displayName, equals('Last 3 Months'));
        expect(TimePeriod.custom.displayName, equals('Custom'));
      });
    });

    group('shortName extension', () {
      test('should return correct short names', () {
        expect(TimePeriod.thisWeek.shortName, equals('Week'));
        expect(TimePeriod.thisMonth.shortName, equals('Month'));
        expect(TimePeriod.lastThreeMonths.shortName, equals('3M'));
        expect(TimePeriod.custom.shortName, equals('Custom'));
      });
    });
  });

  group('DateRange Entity', () {
    final startDate = DateTime(2024, 1, 15);
    final endDate = DateTime(2024, 1, 20);
    final dateRange = DateRange(startDate: startDate, endDate: endDate);

    test('should create DateRange instance correctly', () {
      expect(dateRange.startDate, equals(startDate));
      expect(dateRange.endDate, equals(endDate));
    });

    group('copyWith method', () {
      test('should create copy with modified start date', () {
        final newStartDate = DateTime(2024, 1, 10);
        final copied = dateRange.copyWith(startDate: newStartDate);
        
        expect(copied.startDate, equals(newStartDate));
        expect(copied.endDate, equals(endDate));
      });

      test('should create copy with modified end date', () {
        final newEndDate = DateTime(2024, 1, 25);
        final copied = dateRange.copyWith(endDate: newEndDate);
        
        expect(copied.startDate, equals(startDate));
        expect(copied.endDate, equals(newEndDate));
      });

      test('should preserve original values when no parameters provided', () {
        final copied = dateRange.copyWith();
        
        expect(copied.startDate, equals(dateRange.startDate));
        expect(copied.endDate, equals(dateRange.endDate));
      });
    });

    group('description property', () {
      test('should return "Today" for same day as today', () {
        final today = DateTime.now();
        final todayRange = DateRange(startDate: today, endDate: today);
        
        expect(todayRange.description, equals('Today'));
      });

      test('should return formatted date for single day range', () {
        final singleDay = DateTime(2024, 3, 15);
        final singleDayRange = DateRange(startDate: singleDay, endDate: singleDay);
        
        expect(singleDayRange.description, equals('15/3/2024'));
      });

      test('should return formatted range for multiple days', () {
        final multiDayRange = DateRange(
          startDate: DateTime(2024, 1, 15),
          endDate: DateTime(2024, 1, 20),
        );
        
        expect(multiDayRange.description, equals('15/1/2024 - 20/1/2024'));
      });
    });

    group('dayCount property', () {
      test('should calculate correct day count for single day', () {
        final singleDay = DateTime(2024, 1, 15);
        final singleDayRange = DateRange(startDate: singleDay, endDate: singleDay);
        
        expect(singleDayRange.dayCount, equals(1));
      });

      test('should calculate correct day count for multiple days', () {
        expect(dateRange.dayCount, equals(6)); // Jan 15-20 inclusive
      });

      test('should handle month boundaries', () {
        final monthBoundaryRange = DateRange(
          startDate: DateTime(2024, 1, 30),
          endDate: DateTime(2024, 2, 2),
        );
        
        expect(monthBoundaryRange.dayCount, equals(4)); // Jan 30, 31, Feb 1, 2
      });
    });

    group('contains method', () {
      test('should return true for dates within range', () {
        expect(dateRange.contains(DateTime(2024, 1, 15)), isTrue); // Start date
        expect(dateRange.contains(DateTime(2024, 1, 17)), isTrue); // Middle date
        expect(dateRange.contains(DateTime(2024, 1, 20)), isTrue); // End date
      });

      test('should return false for dates outside range', () {
        expect(dateRange.contains(DateTime(2024, 1, 14)), isFalse); // Before start
        expect(dateRange.contains(DateTime(2024, 1, 21)), isFalse); // After end
        expect(dateRange.contains(DateTime(2023, 12, 31)), isFalse); // Way before
      });

      test('should ignore time components when checking containment', () {
        final morningTime = DateTime(2024, 1, 17, 9, 30);
        final eveningTime = DateTime(2024, 1, 17, 23, 45);
        
        expect(dateRange.contains(morningTime), isTrue);
        expect(dateRange.contains(eveningTime), isTrue);
      });
    });

    group('Equality and Props', () {
      test('should be equal to another DateRange with same dates', () {
        final anotherRange = DateRange(
          startDate: DateTime(2024, 1, 15),
          endDate: DateTime(2024, 1, 20),
        );
        
        expect(dateRange, equals(anotherRange));
        expect(dateRange.hashCode, equals(anotherRange.hashCode));
      });

      test('should not be equal to DateRange with different dates', () {
        final differentRange = DateRange(
          startDate: DateTime(2024, 1, 16), // Different start date
          endDate: DateTime(2024, 1, 20),
        );
        
        expect(dateRange, isNot(equals(differentRange)));
      });

      test('should include dates in props list', () {
        expect(dateRange.props, contains(dateRange.startDate));
        expect(dateRange.props, contains(dateRange.endDate));
      });
    });

    group('Edge Cases', () {
      test('should handle leap year dates', () {
        final leapYearRange = DateRange(
          startDate: DateTime(2024, 2, 28),
          endDate: DateTime(2024, 3, 1),
        );
        
        expect(leapYearRange.dayCount, equals(3)); // Feb 28, 29, Mar 1
        expect(leapYearRange.contains(DateTime(2024, 2, 29)), isTrue);
      });

      test('should handle year boundaries', () {
        final yearBoundaryRange = DateRange(
          startDate: DateTime(2023, 12, 30),
          endDate: DateTime(2024, 1, 2),
        );
        
        expect(yearBoundaryRange.dayCount, equals(4)); // Dec 30, 31, Jan 1, 2
        expect(yearBoundaryRange.contains(DateTime(2024, 1, 1)), isTrue);
      });

      test('should handle same time but different dates', () {
        final sameTimeRange = DateRange(
          startDate: DateTime(2024, 1, 15, 10, 30),
          endDate: DateTime(2024, 1, 17, 10, 30),
        );
        
        expect(sameTimeRange.dayCount, equals(3)); // Should count days, not time
        expect(sameTimeRange.contains(DateTime(2024, 1, 16, 15, 45)), isTrue);
      });
    });
  });

  group('Analytics Integration', () {
    test('should work together for period selection', () {
      const customPeriod = TimePeriod.custom;
      final dateRange = DateRange(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );
      
      expect(customPeriod.displayName, equals('Custom'));
      expect(dateRange.dayCount, equals(31));
      expect(dateRange.description, equals('1/1/2024 - 31/1/2024'));
    });
  });
}
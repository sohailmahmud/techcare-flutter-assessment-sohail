import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/domain/entities/transaction_filter.dart';

void main() {
  group('DateRangePreset Enum', () {
    test('should have all expected values', () {
      expect(DateRangePreset.values, contains(DateRangePreset.today));
      expect(DateRangePreset.values, contains(DateRangePreset.thisWeek));
      expect(DateRangePreset.values, contains(DateRangePreset.thisMonth));
      expect(DateRangePreset.values, contains(DateRangePreset.lastThreeMonths));
      expect(DateRangePreset.values, contains(DateRangePreset.custom));
    });

    group('displayName extension', () {
      test('should return correct display names', () {
        expect(DateRangePreset.today.displayName, equals('Today'));
        expect(DateRangePreset.thisWeek.displayName, equals('This Week'));
        expect(DateRangePreset.thisMonth.displayName, equals('This Month'));
        expect(
          DateRangePreset.lastThreeMonths.displayName,
          equals('Last 3 Months'),
        );
        expect(DateRangePreset.custom.displayName, equals('Custom Range'));
      });
    });

    group('getDateRange method', () {
      test('should return today range for today preset', () {
        final range = DateRangePreset.today.getDateRange();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        expect(range.start.year, equals(today.year));
        expect(range.start.month, equals(today.month));
        expect(range.start.day, equals(today.day));
      });

      test('should return week range for thisWeek preset', () {
        final range = DateRangePreset.thisWeek.getDateRange();
        final now = DateTime.now();
        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));

        expect(range.start.year, equals(startOfWeek.year));
        expect(range.start.month, equals(startOfWeek.month));
        expect(range.start.day, equals(startOfWeek.day));
      });

      test('should return month range for thisMonth preset', () {
        final range = DateRangePreset.thisMonth.getDateRange();
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);

        expect(range.start, equals(startOfMonth));
        expect(range.end.year, equals(now.year));
        expect(range.end.month, equals(now.month));
      });

      test('should return three months range for lastThreeMonths preset', () {
        final range = DateRangePreset.lastThreeMonths.getDateRange();
        final now = DateTime.now();
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

        expect(range.start.year, equals(threeMonthsAgo.year));
        expect(range.start.month, equals(threeMonthsAgo.month));
        expect(range.start.day, equals(threeMonthsAgo.day));
      });

      test('should return default range for custom preset', () {
        final range = DateRangePreset.custom.getDateRange();

        // Should return some default range
        expect(range.start, isA<DateTime>());
        expect(range.end, isA<DateTime>());
      });
    });
  });

  group('TransactionType Enum', () {
    test('should have all expected values', () {
      expect(TransactionType.values, contains(TransactionType.all));
      expect(TransactionType.values, contains(TransactionType.income));
      expect(TransactionType.values, contains(TransactionType.expense));
    });

    group('displayName extension', () {
      test('should return correct display names', () {
        expect(TransactionType.all.displayName, equals('All'));
        expect(TransactionType.income.displayName, equals('Income'));
        expect(TransactionType.expense.displayName, equals('Expense'));
      });
    });
  });

  group('DateRange Entity', () {
    final startDate = DateTime(2024, 1, 15, 0, 0, 0);
    final endDate = DateTime(2024, 1, 20, 23, 59, 59);
    final dateRange = DateRange(start: startDate, end: endDate);

    test('should create DateRange instance correctly', () {
      expect(dateRange.start, equals(startDate));
      expect(dateRange.end, equals(endDate));
    });

    group('contains method', () {
      test('should return true for dates within range', () {
        expect(dateRange.contains(DateTime(2024, 1, 15, 12, 0)), isTrue);
        expect(dateRange.contains(DateTime(2024, 1, 17, 10, 30)), isTrue);
        expect(dateRange.contains(DateTime(2024, 1, 20, 20, 0)), isTrue);
      });

      test('should return false for dates outside range', () {
        expect(dateRange.contains(DateTime(2024, 1, 14, 23, 59)), isFalse);
        expect(dateRange.contains(DateTime(2024, 1, 21, 0, 1)), isFalse);
      });
    });

    group('duration property', () {
      test('should calculate correct duration', () {
        final duration = dateRange.duration;
        expect(duration.inDays, equals(5));
      });
    });

    test('should be equal to another DateRange with same dates', () {
      final anotherRange = DateRange(
        start: DateTime(2024, 1, 15, 0, 0, 0),
        end: DateTime(2024, 1, 20, 23, 59, 59),
      );

      expect(dateRange, equals(anotherRange));
      expect(dateRange.hashCode, equals(anotherRange.hashCode));
    });
  });

  group('AmountRange Entity', () {
    const amountRange = AmountRange(min: 10.0, max: 100.0);

    test('should create AmountRange instance correctly', () {
      expect(amountRange.min, equals(10.0));
      expect(amountRange.max, equals(100.0));
    });

    group('contains method', () {
      test('should return true for amounts within range', () {
        expect(amountRange.contains(10.0), isTrue);
        expect(amountRange.contains(50.0), isTrue);
        expect(amountRange.contains(100.0), isTrue);
        expect(amountRange.contains(-50.0), isTrue); // Uses absolute value
      });

      test('should return false for amounts outside range', () {
        expect(amountRange.contains(5.0), isFalse);
        expect(amountRange.contains(150.0), isFalse);
        expect(amountRange.contains(-150.0), isFalse);
      });
    });

    group('copyWith method', () {
      test('should create copy with modified values', () {
        final copied = amountRange.copyWith(min: 20.0);
        expect(copied.min, equals(20.0));
        expect(copied.max, equals(100.0));
      });
    });
  });

  group('TransactionFilter Entity', () {
    const baseFilter = TransactionFilter();

    test('should create TransactionFilter instance with defaults', () {
      expect(baseFilter.transactionType, equals(TransactionType.all));
      expect(baseFilter.selectedCategories, isEmpty);
      expect(baseFilter.dateRange, isNull);
      expect(baseFilter.amountRange, isNull);
      expect(baseFilter.searchQuery, equals(''));
    });

    test('should create TransactionFilter with all parameters', () {
      final dateRange = DateRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );

      const amountRange = AmountRange(min: 10.0, max: 100.0);

      final filter = TransactionFilter(
        transactionType: TransactionType.expense,
        selectedCategories: const ['cat1', 'cat2'],
        dateRange: dateRange,
        amountRange: amountRange,
        searchQuery: 'lunch',
      );

      expect(filter.transactionType, equals(TransactionType.expense));
      expect(filter.selectedCategories, containsAll(['cat1', 'cat2']));
      expect(filter.dateRange, equals(dateRange));
      expect(filter.amountRange, equals(amountRange));
      expect(filter.searchQuery, equals('lunch'));
    });

    group('hasActiveFilters property', () {
      test('should return false for default filter', () {
        expect(baseFilter.hasActiveFilters, isFalse);
      });

      test('should return true when filters are active', () {
        final filter = baseFilter.copyWith(
          transactionType: TransactionType.income,
        );
        expect(filter.hasActiveFilters, isTrue);
      });
    });

    group('activeFilterCount property', () {
      test('should return 0 for default filter', () {
        expect(baseFilter.activeFilterCount, equals(0));
      });

      test('should count active filters correctly', () {
        const filter = TransactionFilter(
          transactionType: TransactionType.income,
          selectedCategories: ['cat1'],
          searchQuery: 'test',
        );
        expect(filter.activeFilterCount, equals(3));
      });
    });

    group('copyWith method', () {
      test('should create copy with modified type', () {
        final copied = baseFilter.copyWith(
          transactionType: TransactionType.income,
        );
        expect(copied.transactionType, equals(TransactionType.income));
      });

      test('should create copy with modified categories', () {
        final copied = baseFilter.copyWith(
          selectedCategories: ['cat1', 'cat2'],
        );
        expect(copied.selectedCategories, containsAll(['cat1', 'cat2']));
      });
    });

    group('clearFilters method', () {
      test('should return empty filter', () {
        const filter = TransactionFilter(
          transactionType: TransactionType.income,
          selectedCategories: ['cat1'],
          searchQuery: 'test',
        );

        final cleared = filter.clearFilters();

        expect(cleared.transactionType, equals(TransactionType.all));
        expect(cleared.selectedCategories, isEmpty);
        expect(cleared.searchQuery, equals(''));
        expect(cleared.hasActiveFilters, isFalse);
      });
    });
  });

  group('PaginationInfo Entity', () {
    const basePagination = PaginationInfo();

    test('should create PaginationInfo instance with defaults', () {
      expect(basePagination.currentPage, equals(0));
      expect(basePagination.itemsPerPage, equals(20));
      expect(basePagination.totalItems, equals(0));
      expect(basePagination.hasNextPage, isTrue);
      expect(basePagination.isLoading, isFalse);
    });

    group('computed properties', () {
      test('should calculate totalPages correctly', () {
        const pagination = PaginationInfo(totalItems: 45, itemsPerPage: 20);
        expect(pagination.totalPages, equals(3)); // 45/20 = 2.25 -> 3
      });

      test('should identify first page correctly', () {
        expect(basePagination.isFirstPage, isTrue);

        const nextPage = PaginationInfo(currentPage: 1);
        expect(nextPage.isFirstPage, isFalse);
      });

      test('should identify last page correctly', () {
        const lastPage = PaginationInfo(hasNextPage: false);
        expect(lastPage.isLastPage, isTrue);

        expect(basePagination.isLastPage, isFalse);
      });
    });

    group('copyWith method', () {
      test('should create copy with modified values', () {
        final copied = basePagination.copyWith(
          currentPage: 2,
          totalItems: 100,
          isLoading: true,
        );

        expect(copied.currentPage, equals(2));
        expect(copied.totalItems, equals(100));
        expect(copied.isLoading, isTrue);
        expect(copied.itemsPerPage, equals(20)); // Unchanged
      });
    });
  });
}

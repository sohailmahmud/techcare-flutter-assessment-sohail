import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateRequired', () {
      test('should return null for non-empty values', () {
        expect(Validators.validateRequired('some value'), isNull);
        expect(Validators.validateRequired('123'), isNull);
        expect(Validators.validateRequired('a'), isNull);
        expect(Validators.validateRequired('  valid  '), isNull);
      });

      test('should return error for empty or null values', () {
        expect(Validators.validateRequired(null), equals('Field is required'));
        expect(Validators.validateRequired(''), equals('Field is required'));
        expect(Validators.validateRequired('   '), equals('Field is required'));
      });

      test('should use custom field name in error message', () {
        expect(Validators.validateRequired(null, 'Name'),
            equals('Name is required'));
        expect(Validators.validateRequired('', 'Email'),
            equals('Email is required'));
        expect(Validators.validateRequired('   ', 'Password'),
            equals('Password is required'));
      });
    });

    group('validateAmount', () {
      test('should return null for valid amounts', () {
        expect(Validators.validateAmount('100'), isNull);
        expect(Validators.validateAmount('0.01'), isNull);
        expect(Validators.validateAmount('1000.50'), isNull);
        expect(Validators.validateAmount('999999.99'), isNull);
        expect(Validators.validateAmount('1'), isNull);
      });

      test('should return error for invalid amounts', () {
        expect(Validators.validateAmount('0'),
            equals('Amount must be greater than 0'));
        expect(Validators.validateAmount('-100'),
            equals('Amount must be greater than 0'));
        expect(
            Validators.validateAmount('abc'), equals('Enter a valid amount'));
        expect(Validators.validateAmount(''), equals('Amount is required'));
        expect(Validators.validateAmount(null), equals('Amount is required'));
      });

      test('should handle edge cases', () {
        expect(Validators.validateAmount('0.00'),
            equals('Amount must be greater than 0'));
        expect(Validators.validateAmount('100.123'),
            isNull); // Accepts decimal places
        expect(Validators.validateAmount('1e2'),
            isNull); // Accepts scientific notation
      });
    });

    group('validateMinLength', () {
      test('should return null for valid lengths', () {
        expect(Validators.validateMinLength('12345', 5), isNull);
        expect(Validators.validateMinLength('123456', 5), isNull);
        expect(Validators.validateMinLength('a', 1), isNull);
        expect(Validators.validateMinLength('hello world', 10), isNull);
      });

      test('should return error for short values', () {
        expect(Validators.validateMinLength('123', 5),
            equals('Field must be at least 5 characters'));
        expect(
            Validators.validateMinLength('', 1), equals('Field is required'));
        expect(
            Validators.validateMinLength(null, 5), equals('Field is required'));
      });

      test('should use custom field name in error message', () {
        expect(Validators.validateMinLength('123', 5, 'Password'),
            equals('Password must be at least 5 characters'));
        expect(Validators.validateMinLength('', 1, 'Username'),
            equals('Username is required'));
        expect(Validators.validateMinLength(null, 3, 'Description'),
            equals('Description is required'));
      });

      test('should handle various minimum lengths', () {
        expect(Validators.validateMinLength('a', 0), isNull);
        expect(Validators.validateMinLength('ab', 1), isNull);
        expect(Validators.validateMinLength('abc', 2), isNull);
        expect(Validators.validateMinLength('a', 2),
            equals('Field must be at least 2 characters'));
      });
    });

    group('Edge Cases', () {
      test('should handle whitespace properly', () {
        expect(Validators.validateRequired('   '), equals('Field is required'));
        expect(Validators.validateMinLength('   ', 5),
            equals('Field must be at least 5 characters'));
        expect(
            Validators.validateMinLength('', 5), equals('Field is required'));
        expect(
            Validators.validateAmount('   '), equals('Enter a valid amount'));
      });

      test('should handle special characters in amounts', () {
        expect(
            Validators.validateAmount(r'$100'), equals('Enter a valid amount'));
        expect(Validators.validateAmount(r'100.00$'),
            equals('Enter a valid amount'));
        expect(
            Validators.validateAmount('1,000'), equals('Enter a valid amount'));
      });

      test('should handle very large numbers', () {
        expect(Validators.validateAmount('999999999999999'), isNull);
        expect(Validators.validateAmount('1e10'), isNull);
      });
    });
  });
}

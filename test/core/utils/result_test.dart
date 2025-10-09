import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/core/utils/result.dart';
import 'package:fintrack/core/errors/enhanced_failures.dart';

void main() {
  group('Result Tests', () {
    test('Success result should contain data', () {
      const data = 'test data';
      final result = Result.success(data);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.data, equals(data));
      expect(() => result.failure, throwsA(isA<StateError>()));
    });

    test('Failure result should contain failure', () {
      const failure = ValidationFailure('Test error');
      const result = ResultFailure<String>(failure);

      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.failure, equals(failure));
      expect(() => result.data, throwsA(isA<StateError>()));
    });

    test('fold should execute success callback for success result', () {
      const data = 42;
      final result = Result.success(data);

      final folded = result.fold(
        (error) => 'Error: ${error.message}',
        (value) => 'Success: $value',
      );

      expect(folded, equals('Success: 42'));
    });

    test('fold should execute failure callback for failure result', () {
      const failure = ValidationFailure('Test error');
      const result = ResultFailure<int>(failure);

      final folded = result.fold(
        (error) => 'Error: ${error.message}',
        (value) => 'Success: $value',
      );

      expect(folded, equals('Error: Test error'));
    });

    test('map should transform success data', () {
      final result = Result.success(5);
      final mapped = result.map((value) => value * 2);

      expect(mapped.isSuccess, isTrue);
      expect(mapped.data, equals(10));
    });

    test('map should preserve failure', () {
      const failure = ValidationFailure('Test error');
      const result = ResultFailure<int>(failure);
      final mapped = result.map((value) => value * 2);

      expect(mapped.isFailure, isTrue);
      expect(mapped.failure, equals(failure));
    });

    test('flatMap should chain successful operations', () {
      final result = Result.success(5);
      final flatMapped = result.flatMap((value) => Result.success(value * 2));

      expect(flatMapped.isSuccess, isTrue);
      expect(flatMapped.data, equals(10));
    });

    test('flatMap should propagate failure from first result', () {
      const failure = ValidationFailure('Test error');
      const result = ResultFailure<int>(failure);
      final flatMapped = result.flatMap((value) => Result.success(value * 2));

      expect(flatMapped.isFailure, isTrue);
      expect(flatMapped.failure, equals(failure));
    });

    test('flatMap should propagate failure from second result', () {
      final result = Result.success(5);
      const secondFailure = ValidationFailure('Second error');
      final flatMapped = result.flatMap((value) => const ResultFailure<int>(secondFailure));

      expect(flatMapped.isFailure, isTrue);
      expect(flatMapped.failure, equals(secondFailure));
    });

    test('onSuccess should execute callback for success result', () {
      var successCalled = false;

      final result = Result.success(42);
      result.onSuccess((data) => successCalled = true);

      expect(successCalled, isTrue);
    });

    test('onFailure should execute callback for failure result', () {
      var failureCalled = false;

      const failure = ValidationFailure('Test error');
      const result = ResultFailure<int>(failure);
      result.onFailure((error) => failureCalled = true);

      expect(failureCalled, isTrue);
    });

    test('tryCompute should return success for successful computation', () {
      final result = Result.tryCompute(() => 42);

      expect(result.isSuccess, isTrue);
      expect(result.data, equals(42));
    });

    test('tryCompute should return failure for throwing computation', () {
      final result = Result.tryCompute<int>(() => throw Exception('Test error'));

      expect(result.isFailure, isTrue);
      expect(result.failure, isA<UnknownFailure>());
    });

    test('dataOrNull should return data for success', () {
      final result = Result.success(42);
      expect(result.dataOrNull, equals(42));
    });

    test('dataOrNull should return null for failure', () {
      const result = ResultFailure<int>(ValidationFailure('Test error'));
      expect(result.dataOrNull, isNull);
    });

    test('failureOrNull should return failure for failure result', () {
      const failure = ValidationFailure('Test error');
      const result = ResultFailure<int>(failure);
      expect(result.failureOrNull, equals(failure));
    });

    test('failureOrNull should return null for success result', () {
      final result = Result.success(42);
      expect(result.failureOrNull, isNull);
    });
  });
}
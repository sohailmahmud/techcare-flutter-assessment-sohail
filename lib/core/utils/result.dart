import 'package:equatable/equatable.dart';
import '../errors/enhanced_failures.dart';
import 'logger.dart';

/// A result wrapper that encapsulates either success data or failure
abstract class Result<T> extends Equatable {
  const Result();

  /// Check if the result is successful
  bool get isSuccess => this is Success<T>;

  /// Check if the result is a failure
  bool get isFailure => this is ResultFailure<T>;

  /// Get the success data (throws if result is failure)
  T get data {
    if (this is Success<T>) {
      return (this as Success<T>).data;
    }
    throw StateError('Cannot get data from failure result');
  }

  /// Get the failure (throws if result is success)
  Failure get failure {
    if (this is ResultFailure<T>) {
      return (this as ResultFailure<T>).failure;
    }
    throw StateError('Cannot get failure from success result');
  }

  /// Safe way to get data with null return on failure
  T? get dataOrNull {
    if (this is Success<T>) {
      return (this as Success<T>).data;
    }
    return null;
  }

  /// Safe way to get failure with null return on success
  Failure? get failureOrNull {
    if (this is ResultFailure<T>) {
      return (this as ResultFailure<T>).failure;
    }
    return null;
  }

  /// Transform the success data if present
  Result<R> map<R>(R Function(T data) transform) {
    if (this is Success<T>) {
      try {
        return Success(transform((this as Success<T>).data));
      } catch (e) {
        return ResultFailure(FailureHandler.handleException(e));
      }
    }
    return ResultFailure((this as ResultFailure<T>).failure);
  }

  /// Transform the success data asynchronously if present
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) transform) async {
    if (this is Success<T>) {
      try {
        final result = await transform((this as Success<T>).data);
        return Success(result);
      } catch (e) {
        return ResultFailure(FailureHandler.handleException(e));
      }
    }
    return ResultFailure((this as ResultFailure<T>).failure);
  }

  /// Chain operations that return Results
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    if (this is Success<T>) {
      try {
        return transform((this as Success<T>).data);
      } catch (e) {
        return ResultFailure(FailureHandler.handleException(e));
      }
    }
    return ResultFailure((this as ResultFailure<T>).failure);
  }

  /// Chain async operations that return Results
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T data) transform,
  ) async {
    if (this is Success<T>) {
      try {
        return await transform((this as Success<T>).data);
      } catch (e) {
        return ResultFailure(FailureHandler.handleException(e));
      }
    }
    return ResultFailure((this as ResultFailure<T>).failure);
  }

  /// Execute a function on success and return the same result
  Result<T> onSuccess(void Function(T data) action) {
    if (this is Success<T>) {
      try {
        action((this as Success<T>).data);
      } catch (e) {
        // Log the error but don't change the result
        Logger.e('Error in onSuccess callback', error: e);
      }
    }
    return this;
  }

  /// Execute a function on failure and return the same result
  Result<T> onFailure(void Function(Failure failure) action) {
    if (this is ResultFailure<T>) {
      try {
        action((this as ResultFailure<T>).failure);
      } catch (e) {
        // Log the error but don't change the result
        Logger.e('Error in onFailure callback', error: e);
      }
    }
    return this;
  }

  /// Fold the result into a single value
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T data) onSuccess,
  ) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).data);
    }
    return onFailure((this as ResultFailure<T>).failure);
  }

  /// Create a successful result
  static Result<T> success<T>(T data) => Success(data);

  /// Create a failed result
  static Result<T> error<T>(Failure failure) => ResultFailure(failure);

  /// Wrap a computation that might throw
  static Result<T> tryCompute<T>(T Function() computation) {
    try {
      return Success(computation());
    } catch (e) {
      return ResultFailure(FailureHandler.handleException(e));
    }
  }

  /// Wrap an async computation that might throw
  static Future<Result<T>> tryComputeAsync<T>(
    Future<T> Function() computation,
  ) async {
    try {
      final result = await computation();
      return Success(result);
    } catch (e) {
      return ResultFailure(FailureHandler.handleException(e));
    }
  }
}

/// Represents a successful result
class Success<T> extends Result<T> {
  @override
  final T data;

  const Success(this.data);

  @override
  List<Object?> get props => [data];

  @override
  String toString() => 'Success(data: $data)';
}

/// Represents a failed result
class ResultFailure<T> extends Result<T> {
  @override
  final Failure failure;

  const ResultFailure(this.failure);

  @override
  List<Object?> get props => [failure];

  @override
  String toString() => 'ResultFailure(failure: $failure)';
}

/// Extensions for working with lists of results
extension ListResultExtension<T> on List<Result<T>> {
  /// Collect all successful results
  List<T> get successes {
    return whereType<Success<T>>().map((s) => s.data).toList();
  }

  /// Collect all failures
  List<Failure> get failures {
    return whereType<ResultFailure<T>>().map((f) => f.failure).toList();
  }

  /// Check if all results are successful
  bool get allSuccessful => every((result) => result.isSuccess);

  /// Check if any result is successful
  bool get anySuccessful => any((result) => result.isSuccess);

  /// Check if all results are failures
  bool get allFailed => every((result) => result.isFailure);

  /// Check if any result is a failure
  bool get anyFailed => any((result) => result.isFailure);
}

/// Extensions for working with Future<Result<T>>
extension FutureResultExtension<T> on Future<Result<T>> {
  /// Chain another async operation
  Future<Result<R>> thenResult<R>(
    Future<Result<R>> Function(T data) onSuccess,
  ) async {
    final result = await this;
    return result.flatMapAsync(onSuccess);
  }

  /// Handle errors and convert them to Results
  Future<Result<T>> catchError() async {
    try {
      return await this;
    } catch (e) {
      return ResultFailure(FailureHandler.handleException(e));
    }
  }

  /// Add timeout handling
  Future<Result<T>> withTimeout(Duration timeout) async {
    try {
      return await this.timeout(timeout);
    } catch (e) {
      return const ResultFailure(NetworkFailure(
        'Operation timed out',
        code: 'TIMEOUT',
      ));
    }
  }
}

/// Utility for combining multiple results
class ResultCombiner {
  /// Combine two results into a tuple result
  static Result<(T1, T2)> combine2<T1, T2>(
    Result<T1> result1,
    Result<T2> result2,
  ) {
    if (result1.isFailure) return ResultFailure(result1.failure);
    if (result2.isFailure) return ResultFailure(result2.failure);

    return Success((result1.data, result2.data));
  }

  /// Combine three results into a tuple result
  static Result<(T1, T2, T3)> combine3<T1, T2, T3>(
    Result<T1> result1,
    Result<T2> result2,
    Result<T3> result3,
  ) {
    if (result1.isFailure) return ResultFailure(result1.failure);
    if (result2.isFailure) return ResultFailure(result2.failure);
    if (result3.isFailure) return ResultFailure(result3.failure);

    return Success((result1.data, result2.data, result3.data));
  }

  /// Collect successful results from a list, failing if any fails
  static Result<List<T>> collectAll<T>(List<Result<T>> results) {
    final failures = results.failures;
    if (failures.isNotEmpty) {
      return ResultFailure(failures.first);
    }

    return Success(results.successes);
  }

  /// Collect only successful results, ignoring failures
  static Result<List<T>> collectSuccesses<T>(List<Result<T>> results) {
    return Success(results.successes);
  }
}

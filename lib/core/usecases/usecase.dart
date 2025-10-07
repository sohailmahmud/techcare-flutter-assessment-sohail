import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

/// Base UseCase class that all use cases should extend
/// Implements Single Responsibility Principle
/// Type parameters:
/// - [T]: Return type of the use case
/// - [Params]: Parameters required by the use case
abstract class UseCase<T, Params> {
  /// Execute the use case with given parameters
  /// Returns Either a Failure or the expected T
  Future<Either<Failure, T>> call(Params params);
}

/// Used for use cases that don't require any parameters
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}

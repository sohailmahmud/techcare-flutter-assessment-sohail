import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
/// Following the Either pattern for error handling
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Failure related to network connectivity
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network connection failed'])
      : super(message);
}

/// Failure related to local cache/storage
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred'])
      : super(message);
}

/// Failure related to validation
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Validation error'])
      : super(message);
}

/// Failure related to authentication/authorization
class AuthenticationFailure extends Failure {
  const AuthenticationFailure([String message = 'Authentication failed'])
      : super(message);
}

/// Failure for unexpected errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([String message = 'An unexpected error occurred'])
      : super(message);
}

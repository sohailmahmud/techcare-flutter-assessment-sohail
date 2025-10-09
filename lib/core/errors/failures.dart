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
  final String? field;
  
  const ValidationFailure(
    String message, {
    this.field,
  }) : super(message);

  @override
  List<Object> get props => [message, field ?? ''];
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

/// Failure for unknown errors
class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'An unknown error occurred'])
      : super(message);
}

/// Failure when resource is not found
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Resource not found'])
      : super(message);
}

/// Failure related to server errors
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred'])
      : super(message);
}

/// Failure related to sync operations
class SyncFailure extends Failure {
  const SyncFailure([String message = 'Sync operation failed'])
      : super(message);
}



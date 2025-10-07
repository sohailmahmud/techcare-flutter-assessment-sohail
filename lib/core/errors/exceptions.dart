/// Custom exception for server errors
class ServerException implements Exception {
  final String message;

  const ServerException([this.message = 'Server error occurred']);

  @override
  String toString() => message;
}

/// Custom exception for network errors
class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'Network connection failed']);

  @override
  String toString() => message;
}

/// Custom exception for cache errors
class CacheException implements Exception {
  final String message;

  const CacheException([this.message = 'Cache error occurred']);

  @override
  String toString() => message;
}

/// Custom exception for validation errors
class ValidationException implements Exception {
  final String message;

  const ValidationException([this.message = 'Validation error']);

  @override
  String toString() => message;
}

/// Custom exception for authentication errors
class AuthenticationException implements Exception {
  final String message;

  const AuthenticationException([this.message = 'Authentication failed']);

  @override
  String toString() => message;
}

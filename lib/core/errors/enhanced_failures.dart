import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

/// Base class for all application failures
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final int? statusCode;

  const Failure(this.message, {this.code, this.statusCode});

  @override
  List<Object?> get props => [message, code, statusCode];
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure(String message, {String? code, int? statusCode})
      : super(message, code: code, statusCode: statusCode);
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure(String message, {String? code, int? statusCode})
      : super(message, code: code, statusCode: statusCode);
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure(String message, {String? code})
      : super(message, code: code);
}

/// Validation-related failures
class ValidationFailure extends Failure {
  final Map<String, List<String>>? fieldErrors;

  const ValidationFailure(
    String message, {
    String? code,
    this.fieldErrors,
  }) : super(message, code: code);

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// Authentication-related failures
class AuthFailure extends Failure {
  const AuthFailure(String message, {String? code, int? statusCode})
      : super(message, code: code, statusCode: statusCode);
}

/// Permission-related failures
class PermissionFailure extends Failure {
  const PermissionFailure(String message, {String? code})
      : super(message, code: code);
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message, {String? code})
      : super(message, code: code, statusCode: 404);
}

/// Conflict failures (e.g., duplicate data)
class ConflictFailure extends Failure {
  const ConflictFailure(String message, {String? code})
      : super(message, code: code, statusCode: 409);
}

/// Rate limiting failures
class RateLimitFailure extends Failure {
  final Duration? retryAfter;

  const RateLimitFailure(
    String message, {
    String? code,
    this.retryAfter,
  }) : super(message, code: code, statusCode: 429);

  @override
  List<Object?> get props => [message, code, statusCode, retryAfter];
}

/// Storage-related failures
class StorageFailure extends Failure {
  const StorageFailure(String message, {String? code})
      : super(message, code: code);
}

/// Sync-related failures
class SyncFailure extends Failure {
  const SyncFailure(String message, {String? code})
      : super(message, code: code);
}

/// Unknown or unexpected failures
class UnknownFailure extends Failure {
  final dynamic originalError;

  const UnknownFailure(
    String message, {
    String? code,
    this.originalError,
  }) : super(message, code: code);

  @override
  List<Object?> get props => [message, code, originalError];
}

/// Exception handling utility
class FailureHandler {
  /// Convert various exceptions to appropriate Failure types
  static Failure handleException(dynamic error) {
    if (error is DioException) {
      return _handleDioException(error);
    }

    if (error is FormatException) {
      return ValidationFailure(
        'Invalid data format: ${error.message}',
        code: 'FORMAT_ERROR',
      );
    }

    if (error is TypeError) {
      return const ValidationFailure(
        'Type mismatch error occurred',
        code: 'TYPE_ERROR',
      );
    }

    if (error is NoSuchMethodError) {
      return UnknownFailure(
        'Method not found error',
        code: 'METHOD_ERROR',
        originalError: error,
      );
    }

    // Generic exception handling
    return UnknownFailure(
      error.toString(),
      code: 'UNKNOWN_ERROR',
      originalError: error,
    );
  }

  /// Handle Dio-specific exceptions
  static Failure _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return const NetworkFailure(
          'Connection timeout. Please check your internet connection.',
          code: 'CONNECTION_TIMEOUT',
        );

      case DioExceptionType.sendTimeout:
        return const NetworkFailure(
          'Request timeout. Please try again.',
          code: 'SEND_TIMEOUT',
        );

      case DioExceptionType.receiveTimeout:
        return const NetworkFailure(
          'Server response timeout. Please try again.',
          code: 'RECEIVE_TIMEOUT',
        );

      case DioExceptionType.badResponse:
        return _handleResponseError(error);

      case DioExceptionType.cancel:
        return const NetworkFailure(
          'Request was cancelled.',
          code: 'REQUEST_CANCELLED',
        );

      case DioExceptionType.connectionError:
        return const NetworkFailure(
          'No internet connection. Please check your network.',
          code: 'NO_INTERNET',
        );

      case DioExceptionType.badCertificate:
        return const NetworkFailure(
          'Invalid SSL certificate.',
          code: 'SSL_ERROR',
        );

      case DioExceptionType.unknown:
        return NetworkFailure(
          error.message ?? 'An unknown network error occurred.',
          code: 'UNKNOWN_NETWORK_ERROR',
        );
    }
  }

  /// Handle HTTP response errors
  static Failure _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    // Try to extract error details from response
    String message = 'An error occurred';
    String? code;

    if (data is Map<String, dynamic>) {
      if (data['error'] != null) {
        final errorData = data['error'];
        if (errorData is Map<String, dynamic>) {
          message = errorData['message'] ?? message;
          code = errorData['code'];
        } else if (errorData is String) {
          message = errorData;
        }
      } else if (data['message'] != null) {
        message = data['message'];
      }
    }

    switch (statusCode) {
      case 400:
        return ValidationFailure(
          message.isNotEmpty ? message : 'Invalid request data.',
          code: code ?? 'BAD_REQUEST',
        );

      case 401:
        return AuthFailure(
          message.isNotEmpty ? message : 'Authentication required.',
          code: code ?? 'UNAUTHORIZED',
          statusCode: 401,
        );

      case 403:
        return PermissionFailure(
          message.isNotEmpty ? message : 'Access denied.',
          code: code ?? 'FORBIDDEN',
        );

      case 404:
        return NotFoundFailure(
          message.isNotEmpty ? message : 'Resource not found.',
          code: code ?? 'NOT_FOUND',
        );

      case 409:
        return ConflictFailure(
          message.isNotEmpty ? message : 'Resource conflict.',
          code: code ?? 'CONFLICT',
        );

      case 422:
        return ValidationFailure(
          message.isNotEmpty ? message : 'Validation failed.',
          code: code ?? 'VALIDATION_ERROR',
          fieldErrors: _extractFieldErrors(data),
        );

      case 429:
        return RateLimitFailure(
          message.isNotEmpty ? message : 'Rate limit exceeded.',
          code: code ?? 'RATE_LIMIT',
          retryAfter: _extractRetryAfter(error.response?.headers),
        );

      case 500:
        return ServerFailure(
          message.isNotEmpty ? message : 'Internal server error.',
          code: code ?? 'INTERNAL_SERVER_ERROR',
          statusCode: 500,
        );

      case 502:
        return ServerFailure(
          message.isNotEmpty ? message : 'Bad gateway.',
          code: code ?? 'BAD_GATEWAY',
          statusCode: 502,
        );

      case 503:
        return ServerFailure(
          message.isNotEmpty ? message : 'Service unavailable.',
          code: code ?? 'SERVICE_UNAVAILABLE',
          statusCode: 503,
        );

      default:
        return ServerFailure(
          message.isNotEmpty ? message : 'Server error occurred.',
          code: code ?? 'SERVER_ERROR',
          statusCode: statusCode,
        );
    }
  }

  /// Extract field-specific validation errors
  static Map<String, List<String>>? _extractFieldErrors(dynamic data) {
    if (data is! Map<String, dynamic>) return null;

    final errors = data['errors'] ?? data['field_errors'];
    if (errors is! Map<String, dynamic>) return null;

    final fieldErrors = <String, List<String>>{};
    for (final entry in errors.entries) {
      if (entry.value is List) {
        fieldErrors[entry.key] = (entry.value as List).cast<String>();
      } else if (entry.value is String) {
        fieldErrors[entry.key] = [entry.value as String];
      }
    }

    return fieldErrors.isEmpty ? null : fieldErrors;
  }

  /// Extract retry-after duration from headers
  static Duration? _extractRetryAfter(dynamic headers) {
    if (headers == null) return null;

    final retryAfter = headers['retry-after']?.first;
    if (retryAfter == null) return null;

    final seconds = int.tryParse(retryAfter);
    return seconds != null ? Duration(seconds: seconds) : null;
  }
}

/// User-friendly error messages
class ErrorMessages {
  // Network errors
  static const String noInternet =
      'No internet connection. Please check your network and try again.';
  static const String connectionTimeout =
      'Connection timeout. Please try again.';
  static const String serverUnavailable =
      'Service is currently unavailable. Please try again later.';

  // Authentication errors
  static const String unauthorized = 'You need to sign in to continue.';
  static const String sessionExpired =
      'Your session has expired. Please sign in again.';
  static const String accessDenied =
      'You don\'t have permission to access this resource.';

  // Validation errors
  static const String invalidData = 'Please check your input and try again.';
  static const String requiredField = 'This field is required.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String invalidAmount = 'Please enter a valid amount.';

  // Data errors
  static const String notFound = 'The requested item was not found.';
  static const String duplicateData = 'This item already exists.';
  static const String dataSyncFailed =
      'Failed to sync data. Some changes may not be saved.';

  // Generic errors
  static const String unknownError =
      'An unexpected error occurred. Please try again.';
  static const String tryAgainLater =
      'Something went wrong. Please try again later.';

  /// Get user-friendly message for failure
  static String getMessageForFailure(Failure failure) {
    if (failure is NetworkFailure) {
      switch (failure.code) {
        case 'NO_INTERNET':
        case 'CONNECTION_ERROR':
          return noInternet;
        case 'CONNECTION_TIMEOUT':
        case 'SEND_TIMEOUT':
        case 'RECEIVE_TIMEOUT':
          return connectionTimeout;
        default:
          return failure.message;
      }
    }

    if (failure is ServerFailure) {
      switch (failure.statusCode) {
        case 500:
        case 502:
        case 503:
          return serverUnavailable;
        default:
          return failure.message;
      }
    }

    if (failure is AuthFailure) {
      switch (failure.code) {
        case 'UNAUTHORIZED':
          return unauthorized;
        case 'SESSION_EXPIRED':
          return sessionExpired;
        default:
          return failure.message;
      }
    }

    if (failure is PermissionFailure) {
      return accessDenied;
    }

    if (failure is ValidationFailure) {
      return failure.fieldErrors?.isNotEmpty == true
          ? invalidData
          : failure.message;
    }

    if (failure is NotFoundFailure) {
      return notFound;
    }

    if (failure is ConflictFailure) {
      return duplicateData;
    }

    if (failure is SyncFailure) {
      return dataSyncFailed;
    }

    if (failure is RateLimitFailure) {
      final retryText = failure.retryAfter != null
          ? ' Please try again in ${failure.retryAfter!.inMinutes} minutes.'
          : ' Please try again later.';
      return 'Rate limit exceeded.$retryText';
    }

    // Default to failure message or generic error
    return failure.message.isNotEmpty ? failure.message : unknownError;
  }
}

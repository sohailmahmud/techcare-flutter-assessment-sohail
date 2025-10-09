import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';

/// API response wrapper with comprehensive error handling
class ApiResponseHandler {
  
  /// Handle DioException and convert to appropriate Failure
  static Failure handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(error.message ?? 'Request timeout. Please check your internet connection.');
        
      case DioExceptionType.badResponse:
        return _handleHttpError(error.response);
        
      case DioExceptionType.cancel:
        return NetworkFailure('Request was cancelled');
        
      case DioExceptionType.connectionError:
        return NetworkFailure('No internet connection. Please check your network settings.');
        
      case DioExceptionType.badCertificate:
        return NetworkFailure('SSL certificate error. Please try again.');
        
      case DioExceptionType.unknown:
        return UnknownFailure('An unexpected error occurred: ${error.message ?? 'Unknown error'}');
    }
  }

  /// Handle HTTP response errors
  static Failure _handleHttpError(Response? response) {
    if (response == null) {
      return ServerFailure('No response from server');
    }

    final statusCode = response.statusCode ?? 0;
    final data = response.data;

    // Try to extract error message from response
    String errorMessage = 'Unknown server error';
    String errorCode = 'UNKNOWN_ERROR';

    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        errorMessage = error['message'] ?? errorMessage;
        errorCode = error['code'] ?? errorCode;
      } else if (data['message'] != null) {
        errorMessage = data['message'];
      }
    }

    switch (statusCode) {
      case 400:
        return ValidationFailure(errorMessage, code: errorCode);
      case 401:
        return AuthenticationFailure('Authentication failed. Please log in again.');
      case 403:
        return AuthenticationFailure('Access denied. You don\'t have permission to perform this action.');
      case 404:
        return NotFoundFailure('Resource not found');
      case 422:
        return ValidationFailure(errorMessage, code: errorCode);
      case 429:
        return NetworkFailure('Too many requests. Please try again later.');
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerFailure('Server error. Please try again later.');
      default:
        return ServerFailure('Server error ($statusCode): $errorMessage');
    }
  }

  /// Handle generic exceptions
  static Failure handleGenericException(dynamic error) {
    if (error is DioException) {
      return handleDioException(error);
    }
    
    return UnknownFailure('An unexpected error occurred: ${error.toString()}');
  }

  /// Execute API call with comprehensive error handling
  static Future<Either<Failure, T>> executeApiCall<T>(
    Future<T> Function() apiCall,
  ) async {
    try {
      final result = await apiCall();
      return Right(result);
    } on DioException catch (e) {
      return Left(handleDioException(e));
    } catch (e) {
      return Left(handleGenericException(e));
    }
  }

  /// Execute API call with retry logic
  static Future<Either<Failure, T>> executeApiCallWithRetry<T>(
    Future<T> Function() apiCall, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
  }) async {
    Duration currentDelay = initialDelay;
    
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      final result = await executeApiCall(apiCall);
      
      // If successful or final attempt, return result
      if (result.isRight() || attempt == maxRetries) {
        return result;
      }
      
      // Check if error is retryable
      final failure = result.fold((l) => l, (r) => null);
      if (failure != null && !_isRetryableFailure(failure)) {
        return result;
      }
      
      // Wait before next attempt with exponential backoff
      if (attempt < maxRetries) {
        await Future.delayed(currentDelay);
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }
    
    return Left(UnknownFailure('Max retries exceeded'));
  }

  /// Check if failure is retryable
  static bool _isRetryableFailure(Failure failure) {
    return failure is NetworkFailure || 
           failure is ServerFailure ||
           (failure is UnknownFailure && !failure.message.contains('validation'));
  }

  /// Validate API response structure
  static Either<Failure, Map<String, dynamic>> validateApiResponse(Response response) {
    if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
      return Left(ServerFailure('Invalid response status: ${response.statusCode}'));
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return Left(ServerFailure('Invalid response format'));
    }

    final success = data['success'];
    if (success != true) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        return Left(ServerFailure(error['message'] ?? 'API returned error'));
      }
      return Left(ServerFailure('API request failed'));
    }

    return Right(data);
  }
}

/// Enhanced failure types for better error handling
class ValidationFailure extends Failure {
  final String code;
  final String? field;
  
  const ValidationFailure(String message, {this.code = 'VALIDATION_ERROR', this.field}) 
    : super(message);
    
  @override
  List<Object> get props => [message, code, if (field != null) field!];
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message) : super(message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(String message) : super(message);
}

/// Retry configuration for different types of operations
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final List<Type> retryableFailures;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.retryableFailures = const [NetworkFailure, ServerFailure],
  });

  static const RetryConfig conservative = RetryConfig(
    maxRetries: 2,
    initialDelay: Duration(milliseconds: 500),
    backoffMultiplier: 1.5,
  );

  static const RetryConfig aggressive = RetryConfig(
    maxRetries: 5,
    initialDelay: Duration(milliseconds: 200),
    backoffMultiplier: 2.5,
  );

  static const RetryConfig none = RetryConfig(maxRetries: 0);
}

/// Network state monitoring
enum NetworkState {
  connected,
  disconnected,
  slow,
  unknown,
}

class NetworkStateMonitor {
  static NetworkState _currentState = NetworkState.unknown;
  
  static NetworkState get currentState => _currentState;
  
  static void updateState(NetworkState state) {
    _currentState = state;
  }
  
  static bool get isConnected => _currentState == NetworkState.connected;
  static bool get isDisconnected => _currentState == NetworkState.disconnected;
  static bool get isSlow => _currentState == NetworkState.slow;
}
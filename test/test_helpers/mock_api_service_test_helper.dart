import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/data/datasources/mock_api_service.dart';

/// Test helper wrapper around MockApiService that allows forcing behavior
/// (success, timeout, server error, validation error, offline simulated).
class TestableMockApiService {
  final MockApiService _inner;

  TestableMockApiService({double failureChance = 0.0})
    : _inner = MockApiService(failureChance: failureChance);

  Future<void> initialize() => _inner.initialize();

  /// Force the next call to throw a specific DioException
  void forceNextError(DioException exception) {
    try {
      _inner.setNextError(exception);
    } catch (e) {
      throw StateError('Unable to set forced error on MockApiService: $e');
    }
  }

  // Helpers to create common DioException types
  static DioException connectionError() => DioException(
    requestOptions: RequestOptions(path: ''),
    type: DioExceptionType.connectionError,
    message: 'Simulated connection error',
  );

  static DioException receiveTimeout() => DioException(
    requestOptions: RequestOptions(path: ''),
    type: DioExceptionType.receiveTimeout,
    message: 'Simulated timeout',
  );

  static DioException server500() => DioException(
    requestOptions: RequestOptions(path: ''),
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 500,
      data: {'message': 'Simulated server error'},
    ),
    message: 'Simulated server error',
  );

  static DioException validation400() => DioException(
    requestOptions: RequestOptions(path: ''),
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 400,
      data: {'message': 'Simulated validation error'},
    ),
    message: 'Simulated validation error',
  );

  MockApiService get service => _inner;
}

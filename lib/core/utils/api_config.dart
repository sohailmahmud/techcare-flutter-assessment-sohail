import 'dart:math' as math;

/// API configuration constants and utilities
class ApiConfig {
  // Network configuration
  static const int minDelay = 300;
  static const int maxDelay = 1200;
  static const double errorRate = 0.08; // 8% error rate
  static const int connectTimeout = 10000; // 10 seconds
  static const int receiveTimeout = 15000; // 15 seconds
  static const int sendTimeout = 10000; // 10 seconds

  // Pagination defaults
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache settings
  static const Duration cacheExpiry = Duration(minutes: 15);
  static const Duration shortCacheExpiry = Duration(minutes: 5);
  static const Duration longCacheExpiry = Duration(hours: 1);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  static const double retryBackoffMultiplier = 2.0;

  // Mock data limits
  static const int maxTransactions = 1000;
  static const int maxCategories = 50;

  // Search configuration
  static const int minSearchLength = 2;
  static const int maxSearchResults = 200;

  // Sync configuration
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxSyncRetries = 5;
  static const Duration syncCooldown = Duration(minutes: 2);

  // Private constructor to prevent instantiation
  ApiConfig._();
}

/// Network simulation utilities
class NetworkSimulator {
  static final math.Random _random = math.Random();

  /// Simulate realistic network delay
  static Future<void> simulateDelay({
    int? minMs,
    int? maxMs,
  }) async {
    final min = minMs ?? ApiConfig.minDelay;
    final max = maxMs ?? ApiConfig.maxDelay;
    final delay = min + _random.nextInt(max - min);
    await Future.delayed(Duration(milliseconds: delay));
  }

  /// Check if should simulate error based on error rate
  static bool shouldSimulateError([double? customRate]) {
    final rate = customRate ?? ApiConfig.errorRate;
    return _random.nextDouble() < rate;
  }

  /// Generate random error scenarios
  static Exception generateRandomError() {
    final errorTypes = [
      'CONNECTION_TIMEOUT',
      'SERVER_ERROR',
      'NETWORK_ERROR',
      'RATE_LIMITED',
      'SERVICE_UNAVAILABLE'
    ];

    final errorType = errorTypes[_random.nextInt(errorTypes.length)];
    return Exception('Simulated error: $errorType');
  }

  /// Simulate network quality (good, poor, offline)
  static NetworkQuality simulateNetworkQuality() {
    final value = _random.nextDouble();
    if (value < 0.1) return NetworkQuality.offline;
    if (value < 0.2) return NetworkQuality.poor;
    return NetworkQuality.good;
  }
}

/// Network quality enum
enum NetworkQuality {
  good,
  poor,
  offline,
}

/// Performance monitoring utilities
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<int>> _metrics = {};

  /// Start timing an operation
  static void startTimer(String operation) {
    _startTimes[operation] = DateTime.now();
  }

  /// End timing and record metric
  static int endTimer(String operation) {
    final startTime = _startTimes.remove(operation);
    if (startTime == null) return 0;

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    _metrics.putIfAbsent(operation, () => []).add(duration);

    return duration;
  }

  /// Get average duration for operation
  static double getAverageDuration(String operation) {
    final durations = _metrics[operation];
    if (durations == null || durations.isEmpty) return 0.0;

    final sum = durations.reduce((a, b) => a + b);
    return sum / durations.length;
  }

  /// Clear all metrics
  static void clearMetrics() {
    _startTimes.clear();
    _metrics.clear();
  }
}

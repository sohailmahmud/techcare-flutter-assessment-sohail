import 'dart:math' as math;

/// Utilities for id generation used across the app.
String generateTempId() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final rand = math.Random().nextInt(999999);
  return 'temp_${timestamp}_$rand';
}

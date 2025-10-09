import 'package:hive_ce/hive.dart';

part 'hive_key_value.g.dart';

/// Simple key-value storage model for Hive
@HiveType(typeId: 6)
class HiveKeyValue extends HiveObject {
  @override
  @HiveField(0)
  String key;

  @HiveField(1)
  String value;

  @HiveField(2)
  int? timestamp;

  @HiveField(3)
  String? type; // To distinguish different data types

  HiveKeyValue({
    required this.key,
    required this.value,
    this.timestamp,
    this.type,
  });

  /// Check if the cached data is still valid
  bool isValid({Duration? maxAge}) {
    if (timestamp == null) return false;

    final age = DateTime.now().millisecondsSinceEpoch - timestamp!;
    final maxAgeMs = (maxAge ?? const Duration(minutes: 5)).inMilliseconds;

    return age <= maxAgeMs;
  }

  /// Update the value and timestamp
  void updateValue(String newValue) {
    value = newValue;
    timestamp = DateTime.now().millisecondsSinceEpoch;
    save(); // Save to Hive
  }
}

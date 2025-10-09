import 'package:hive_ce/hive.dart';

part 'cache_metadata.g.dart';

/// Cache metadata for tracking cache state and statistics
@HiveType(typeId: 7)
class CacheMetadata extends HiveObject {
  @HiveField(0)
  String key;

  @HiveField(1)
  DateTime lastUpdated;

  @HiveField(2)
  DateTime? lastSynced;

  @HiveField(3)
  int totalItems;

  @HiveField(4)
  int expiredItems;

  @HiveField(5)
  String version;

  @HiveField(6)
  Map<String, dynamic> filters;

  @HiveField(7)
  bool isDirty; // Needs sync with server

  CacheMetadata({
    required this.key,
    required this.lastUpdated,
    this.lastSynced,
    this.totalItems = 0,
    this.expiredItems = 0,
    this.version = '1.0',
    this.filters = const {},
    this.isDirty = false,
  });

  /// Check if cache is stale and needs refresh
  bool isStale(Duration maxAge) {
    return DateTime.now().difference(lastUpdated) > maxAge;
  }

  /// Update cache metadata
  void updateMetadata({
    int? totalItems,
    int? expiredItems,
    Map<String, dynamic>? filters,
    bool? isDirty,
  }) {
    if (totalItems != null) this.totalItems = totalItems;
    if (expiredItems != null) this.expiredItems = expiredItems;
    if (filters != null) this.filters = filters;
    if (isDirty != null) this.isDirty = isDirty;
    lastUpdated = DateTime.now();
    save();
  }

  /// Mark as synced with server
  void markSynced() {
    lastSynced = DateTime.now();
    isDirty = false;
    save();
  }

  @override
  String toString() {
    return 'CacheMetadata(key: $key, totalItems: $totalItems, lastUpdated: $lastUpdated)';
  }
}
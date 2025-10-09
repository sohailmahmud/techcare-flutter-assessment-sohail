import 'package:hive_ce/hive.dart';

// Note: Run 'flutter packages pub run build_runner build' to generate hive_models.g.dart
part 'hive_models.g.dart';

/// Hive adapter type IDs
class HiveTypeIds {
  static const int transaction = 0;
  static const int category = 1;
  static const int syncQueueItem = 2;
  static const int transactionType = 3;
  static const int syncOperation = 4;
  static const int syncStatus = 5;
}

/// Transaction type enum for Hive
@HiveType(typeId: HiveTypeIds.transactionType)
enum HiveTransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

/// Sync operation enum
@HiveType(typeId: HiveTypeIds.syncOperation)
enum HiveSyncOperation {
  @HiveField(0)
  create,
  @HiveField(1)
  update,
  @HiveField(2)
  delete,
}

/// Sync status enum  
@HiveType(typeId: HiveTypeIds.syncStatus)
enum HiveSyncStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  syncing,
  @HiveField(2)
  synced,
  @HiveField(3)
  failed,
  @HiveField(4)
  conflict,
}

/// Hive model for transactions
@HiveType(typeId: HiveTypeIds.transaction)
class HiveTransaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  HiveTransactionType type;

  @HiveField(4)
  String categoryId;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String? description;

  @HiveField(7)
  String? paymentMethod;

  @HiveField(8)
  List<String> tags;

  @HiveField(9)
  String? location;

  @HiveField(10)
  String? receiptUrl;

  @HiveField(11)
  bool isRecurring;

  @HiveField(12)
  String? recurringInterval;

  @HiveField(13)
  DateTime createdAt;

  @HiveField(14)
  DateTime updatedAt;

  @HiveField(15)
  bool isDeleted;

  @HiveField(16)
  HiveSyncStatus syncStatus;

  @HiveField(17)
  String? localId; // For offline-created items

  @HiveField(18)
  int? version; // For conflict resolution

  @HiveField(19)
  DateTime? lastSyncAt;

  HiveTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.description,
    this.paymentMethod,
    this.tags = const [],
    this.location,
    this.receiptUrl,
    this.isRecurring = false,
    this.recurringInterval,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncStatus = HiveSyncStatus.synced,
    this.localId,
    this.version,
    this.lastSyncAt,
  });

  /// Create a copy with updated fields
  HiveTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    HiveTransactionType? type,
    String? categoryId,
    DateTime? date,
    String? description,
    String? paymentMethod,
    List<String>? tags,
    String? location,
    String? receiptUrl,
    bool? isRecurring,
    String? recurringInterval,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    HiveSyncStatus? syncStatus,
    String? localId,
    int? version,
    DateTime? lastSyncAt,
  }) {
    return HiveTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      localId: localId ?? this.localId,
      version: version ?? this.version,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  /// Convert to JSON for API sync
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type == HiveTransactionType.income ? 'income' : 'expense',
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'description': description,
      'paymentMethod': paymentMethod,
      'tags': tags,
      'location': location,
      'receiptUrl': receiptUrl,
      'isRecurring': isRecurring,
      'recurringInterval': recurringInterval,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'version': version,
    };
  }

  /// Create from JSON
  factory HiveTransaction.fromJson(Map<String, dynamic> json) {
    return HiveTransaction(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] == 'income' 
          ? HiveTransactionType.income 
          : HiveTransactionType.expense,
      categoryId: json['categoryId'] ?? json['category']?['id'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      description: json['description'],
      paymentMethod: json['paymentMethod'],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      location: json['location'],
      receiptUrl: json['receiptUrl'],
      isRecurring: json['isRecurring'] ?? false,
      recurringInterval: json['recurringInterval'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      version: json['version'],
    );
  }

  @override
  String toString() => 'HiveTransaction(id: $id, title: $title, amount: $amount)';
}

/// Hive model for categories
@HiveType(typeId: HiveTypeIds.category)
class HiveCategory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon;

  @HiveField(3)
  String color;

  @HiveField(4)
  double? budget;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  bool isDeleted;

  @HiveField(8)
  HiveSyncStatus syncStatus;

  @HiveField(9)
  String? localId;

  @HiveField(10)
  int? version;

  @HiveField(11)
  DateTime? lastSyncAt;

  HiveCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.budget,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncStatus = HiveSyncStatus.synced,
    this.localId,
    this.version,
    this.lastSyncAt,
  });

  /// Create a copy with updated fields
  HiveCategory copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    double? budget,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    HiveSyncStatus? syncStatus,
    String? localId,
    int? version,
    DateTime? lastSyncAt,
  }) {
    return HiveCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      budget: budget ?? this.budget,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      localId: localId ?? this.localId,
      version: version ?? this.version,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  /// Convert to JSON for API sync
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'budget': budget,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'version': version,
    };
  }

  /// Create from JSON
  factory HiveCategory.fromJson(Map<String, dynamic> json) {
    return HiveCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '#000000',
      budget: (json['budget'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      version: json['version'],
    );
  }

  @override
  String toString() => 'HiveCategory(id: $id, name: $name)';
}

/// Hive model for sync queue items
@HiveType(typeId: HiveTypeIds.syncQueueItem)
class HiveSyncQueueItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String entityType; // 'transaction', 'category', etc.

  @HiveField(2)
  String entityId;

  @HiveField(3)
  HiveSyncOperation operation;

  @HiveField(4)
  Map<String, dynamic> data;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  int retryCount;

  @HiveField(7)
  DateTime? lastAttemptAt;

  @HiveField(8)
  String? lastError;

  @HiveField(9)
  HiveSyncStatus status;

  @HiveField(10)
  int priority; // Higher number = higher priority

  HiveSyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.lastAttemptAt,
    this.lastError,
    this.status = HiveSyncStatus.pending,
    this.priority = 0,
  });

  /// Create a copy with updated fields
  HiveSyncQueueItem copyWith({
    String? id,
    String? entityType,
    String? entityId,
    HiveSyncOperation? operation,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    DateTime? lastAttemptAt,
    String? lastError,
    HiveSyncStatus? status,
    int? priority,
  }) {
    return HiveSyncQueueItem(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
      priority: priority ?? this.priority,
    );
  }

  /// Check if this item should be retried
  bool get shouldRetry {
    if (status != HiveSyncStatus.failed) return false;
    if (retryCount >= 5) return false; // Max 5 retries
    
    final lastAttempt = lastAttemptAt;
    if (lastAttempt == null) return true;
    
    // Exponential backoff: 1min, 2min, 4min, 8min, 16min
    final backoffMinutes = (1 << retryCount);
    final nextRetry = lastAttempt.add(Duration(minutes: backoffMinutes));
    
    return DateTime.now().isAfter(nextRetry);
  }

  @override
  String toString() => 'HiveSyncQueueItem(id: $id, entityType: $entityType, operation: $operation)';
}

/// Hive box names
class HiveBoxNames {
  static const String transactions = 'transactions';
  static const String categories = 'categories';
  static const String syncQueue = 'sync_queue';
  static const String settings = 'settings';
  static const String cache = 'cache';
}

/// Hive settings keys
class HiveSettingsKeys {
  static const String lastSyncAt = 'last_sync_at';
  static const String syncEnabled = 'sync_enabled';
  static const String offlineMode = 'offline_mode';
  static const String autoSync = 'auto_sync';
  static const String syncInterval = 'sync_interval';
  static const String userId = 'user_id';
  static const String deviceId = 'device_id';
}
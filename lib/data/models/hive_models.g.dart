// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveTransactionAdapter extends TypeAdapter<HiveTransaction> {
  @override
  final typeId = 0;

  @override
  HiveTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveTransaction(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
      type: fields[3] as HiveTransactionType,
      categoryId: fields[4] as String,
      date: fields[5] as DateTime,
      description: fields[6] as String?,
      paymentMethod: fields[7] as String?,
      tags: fields[8] == null ? const [] : (fields[8] as List).cast<String>(),
      location: fields[9] as String?,
      receiptUrl: fields[10] as String?,
      isRecurring: fields[11] == null ? false : fields[11] as bool,
      recurringInterval: fields[12] as String?,
      createdAt: fields[13] as DateTime,
      updatedAt: fields[14] as DateTime,
      isDeleted: fields[15] == null ? false : fields[15] as bool,
      syncStatus: fields[16] == null
          ? HiveSyncStatus.synced
          : fields[16] as HiveSyncStatus,
      localId: fields[17] as String?,
      version: (fields[18] as num?)?.toInt(),
      lastSyncAt: fields[19] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveTransaction obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.categoryId)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.paymentMethod)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.location)
      ..writeByte(10)
      ..write(obj.receiptUrl)
      ..writeByte(11)
      ..write(obj.isRecurring)
      ..writeByte(12)
      ..write(obj.recurringInterval)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.isDeleted)
      ..writeByte(16)
      ..write(obj.syncStatus)
      ..writeByte(17)
      ..write(obj.localId)
      ..writeByte(18)
      ..write(obj.version)
      ..writeByte(19)
      ..write(obj.lastSyncAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveCategoryAdapter extends TypeAdapter<HiveCategory> {
  @override
  final typeId = 1;

  @override
  HiveCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      icon: fields[2] as String,
      color: fields[3] as String,
      budget: (fields[4] as num?)?.toDouble(),
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      isDeleted: fields[7] == null ? false : fields[7] as bool,
      syncStatus: fields[8] == null
          ? HiveSyncStatus.synced
          : fields[8] as HiveSyncStatus,
      localId: fields[9] as String?,
      version: (fields[10] as num?)?.toInt(),
      lastSyncAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveCategory obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.budget)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.isDeleted)
      ..writeByte(8)
      ..write(obj.syncStatus)
      ..writeByte(9)
      ..write(obj.localId)
      ..writeByte(10)
      ..write(obj.version)
      ..writeByte(11)
      ..write(obj.lastSyncAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveSyncQueueItemAdapter extends TypeAdapter<HiveSyncQueueItem> {
  @override
  final typeId = 2;

  @override
  HiveSyncQueueItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSyncQueueItem(
      id: fields[0] as String,
      entityType: fields[1] as String,
      entityId: fields[2] as String,
      operation: fields[3] as HiveSyncOperation,
      data: (fields[4] as Map).cast<String, dynamic>(),
      createdAt: fields[5] as DateTime,
      retryCount: fields[6] == null ? 0 : (fields[6] as num).toInt(),
      lastAttemptAt: fields[7] as DateTime?,
      lastError: fields[8] as String?,
      status: fields[9] == null
          ? HiveSyncStatus.pending
          : fields[9] as HiveSyncStatus,
      priority: fields[10] == null ? 0 : (fields[10] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveSyncQueueItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.entityType)
      ..writeByte(2)
      ..write(obj.entityId)
      ..writeByte(3)
      ..write(obj.operation)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.retryCount)
      ..writeByte(7)
      ..write(obj.lastAttemptAt)
      ..writeByte(8)
      ..write(obj.lastError)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.priority);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSyncQueueItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveTransactionTypeAdapter extends TypeAdapter<HiveTransactionType> {
  @override
  final typeId = 3;

  @override
  HiveTransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HiveTransactionType.income;
      case 1:
        return HiveTransactionType.expense;
      default:
        return HiveTransactionType.income;
    }
  }

  @override
  void write(BinaryWriter writer, HiveTransactionType obj) {
    switch (obj) {
      case HiveTransactionType.income:
        writer.writeByte(0);
      case HiveTransactionType.expense:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveTransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveSyncOperationAdapter extends TypeAdapter<HiveSyncOperation> {
  @override
  final typeId = 4;

  @override
  HiveSyncOperation read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HiveSyncOperation.create;
      case 1:
        return HiveSyncOperation.update;
      case 2:
        return HiveSyncOperation.delete;
      default:
        return HiveSyncOperation.create;
    }
  }

  @override
  void write(BinaryWriter writer, HiveSyncOperation obj) {
    switch (obj) {
      case HiveSyncOperation.create:
        writer.writeByte(0);
      case HiveSyncOperation.update:
        writer.writeByte(1);
      case HiveSyncOperation.delete:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSyncOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveSyncStatusAdapter extends TypeAdapter<HiveSyncStatus> {
  @override
  final typeId = 5;

  @override
  HiveSyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HiveSyncStatus.pending;
      case 1:
        return HiveSyncStatus.syncing;
      case 2:
        return HiveSyncStatus.synced;
      case 3:
        return HiveSyncStatus.failed;
      case 4:
        return HiveSyncStatus.conflict;
      default:
        return HiveSyncStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, HiveSyncStatus obj) {
    switch (obj) {
      case HiveSyncStatus.pending:
        writer.writeByte(0);
      case HiveSyncStatus.syncing:
        writer.writeByte(1);
      case HiveSyncStatus.synced:
        writer.writeByte(2);
      case HiveSyncStatus.failed:
        writer.writeByte(3);
      case HiveSyncStatus.conflict:
        writer.writeByte(4);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

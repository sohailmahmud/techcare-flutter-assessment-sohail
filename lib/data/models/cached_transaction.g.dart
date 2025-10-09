// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedTransactionAdapter extends TypeAdapter<CachedTransaction> {
  @override
  final typeId = 8;

  @override
  CachedTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedTransaction(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
      type: (fields[3] as num).toInt(),
      categoryId: fields[4] as String,
      categoryName: fields[5] as String,
      date: fields[6] as DateTime,
      notes: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      cachedAt: fields[9] as DateTime,
      expiresAt: fields[10] as DateTime?,
      isDeleted: fields[11] == null ? false : fields[11] as bool,
      lastModified: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedTransaction obj) {
    writer
      ..writeByte(13)
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
      ..write(obj.categoryName)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.cachedAt)
      ..writeByte(10)
      ..write(obj.expiresAt)
      ..writeByte(11)
      ..write(obj.isDeleted)
      ..writeByte(12)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

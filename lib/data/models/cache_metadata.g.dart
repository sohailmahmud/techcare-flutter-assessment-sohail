// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_metadata.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CacheMetadataAdapter extends TypeAdapter<CacheMetadata> {
  @override
  final typeId = 7;

  @override
  CacheMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheMetadata(
      key: fields[0] as String,
      lastUpdated: fields[1] as DateTime,
      lastSynced: fields[2] as DateTime?,
      totalItems: fields[3] == null ? 0 : (fields[3] as num).toInt(),
      expiredItems: fields[4] == null ? 0 : (fields[4] as num).toInt(),
      version: fields[5] == null ? '1.0' : fields[5] as String,
      filters: fields[6] == null
          ? const {}
          : (fields[6] as Map).cast<String, dynamic>(),
      isDirty: fields[7] == null ? false : fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CacheMetadata obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.lastUpdated)
      ..writeByte(2)
      ..write(obj.lastSynced)
      ..writeByte(3)
      ..write(obj.totalItems)
      ..writeByte(4)
      ..write(obj.expiredItems)
      ..writeByte(5)
      ..write(obj.version)
      ..writeByte(6)
      ..write(obj.filters)
      ..writeByte(7)
      ..write(obj.isDirty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

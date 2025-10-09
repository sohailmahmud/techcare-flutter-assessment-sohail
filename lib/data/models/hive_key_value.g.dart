// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_key_value.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveKeyValueAdapter extends TypeAdapter<HiveKeyValue> {
  @override
  final typeId = 6;

  @override
  HiveKeyValue read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveKeyValue(
      key: fields[0] as String,
      value: fields[1] as String,
      timestamp: (fields[2] as num?)?.toInt(),
      type: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveKeyValue obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveKeyValueAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

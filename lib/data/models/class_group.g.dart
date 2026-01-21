// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_group.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClassGroupAdapter extends TypeAdapter<ClassGroup> {
  @override
  final int typeId = 3;

  @override
  ClassGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClassGroup(
      id: fields[0] as String,
      department: fields[1] as String,
      batch: fields[2] as int,
      section: fields[3] as String,
      createdAtMs: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ClassGroup obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.department)
      ..writeByte(2)
      ..write(obj.batch)
      ..writeByte(3)
      ..write(obj.section)
      ..writeByte(4)
      ..write(obj.createdAtMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

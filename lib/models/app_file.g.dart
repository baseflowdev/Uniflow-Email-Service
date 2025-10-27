// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_file.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppFileAdapter extends TypeAdapter<AppFile> {
  @override
  final int typeId = 1;

  @override
  AppFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppFile(
      id: fields[0] as String,
      name: fields[1] as String,
      path: fields[2] as String,
      type: fields[3] as String,
      size: fields[4] as int,
      dateAdded: fields[5] as DateTime,
      parentFolderId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppFile obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.size)
      ..writeByte(5)
      ..write(obj.dateAdded)
      ..writeByte(6)
      ..write(obj.parentFolderId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

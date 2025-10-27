// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 4;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      isDarkMode: fields[0] as bool,
      language: fields[1] as String,
      autoSync: fields[2] as bool,
      enableNotifications: fields[3] as bool,
      defaultViewMode: fields[4] as String,
      maxRecentFiles: fields[5] as int,
      showFilePreview: fields[6] as bool,
      themeColor: fields[7] as String,
      primaryColor: fields[8] as String,
      secondaryColor: fields[9] as String,
      autoSave: fields[10] as bool,
      autoSaveInterval: fields[11] as int,
      lastBackup: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.isDarkMode)
      ..writeByte(1)
      ..write(obj.language)
      ..writeByte(2)
      ..write(obj.autoSync)
      ..writeByte(3)
      ..write(obj.enableNotifications)
      ..writeByte(4)
      ..write(obj.defaultViewMode)
      ..writeByte(5)
      ..write(obj.maxRecentFiles)
      ..writeByte(6)
      ..write(obj.showFilePreview)
      ..writeByte(7)
      ..write(obj.themeColor)
      ..writeByte(8)
      ..write(obj.primaryColor)
      ..writeByte(9)
      ..write(obj.secondaryColor)
      ..writeByte(10)
      ..write(obj.autoSave)
      ..writeByte(11)
      ..write(obj.autoSaveInterval)
      ..writeByte(12)
      ..write(obj.lastBackup);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

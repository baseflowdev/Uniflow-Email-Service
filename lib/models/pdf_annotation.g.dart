// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_annotation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PdfAnnotationAdapter extends TypeAdapter<PdfAnnotation> {
  @override
  final int typeId = 5;

  @override
  PdfAnnotation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PdfAnnotation(
      id: fields[0] as String,
      fileId: fields[1] as String,
      type: fields[2] as String,
      x: fields[3] as double,
      y: fields[4] as double,
      width: fields[5] as double,
      height: fields[6] as double,
      content: fields[7] as String,
      color: fields[8] as String,
      createdAt: fields[9] as DateTime,
      pageNumber: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PdfAnnotation obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fileId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.x)
      ..writeByte(4)
      ..write(obj.y)
      ..writeByte(5)
      ..write(obj.width)
      ..writeByte(6)
      ..write(obj.height)
      ..writeByte(7)
      ..write(obj.content)
      ..writeByte(8)
      ..write(obj.color)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.pageNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfAnnotationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

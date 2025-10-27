import 'package:hive/hive.dart';

part 'pdf_annotation.g.dart';

@HiveType(typeId: 5)
class PdfAnnotation {
  @HiveField(0)
  String id;

  @HiveField(1)
  String fileId;

  @HiveField(2)
  String type; // 'highlight', 'note', 'drawing', 'text'

  @HiveField(3)
  double x;

  @HiveField(4)
  double y;

  @HiveField(5)
  double width;

  @HiveField(6)
  double height;

  @HiveField(7)
  String content;

  @HiveField(8)
  String color;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  int pageNumber;

  PdfAnnotation({
    required this.id,
    required this.fileId,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.content,
    required this.color,
    required this.createdAt,
    required this.pageNumber,
  });

  PdfAnnotation copyWith({
    String? id,
    String? fileId,
    String? type,
    double? x,
    double? y,
    double? width,
    double? height,
    String? content,
    String? color,
    DateTime? createdAt,
    int? pageNumber,
  }) {
    return PdfAnnotation(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      content: content ?? this.content,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      pageNumber: pageNumber ?? this.pageNumber,
    );
  }

  @override
  String toString() {
    return 'PdfAnnotation(id: $id, type: $type, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PdfAnnotation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

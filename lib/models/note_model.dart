import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 3)
class NoteModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime modifiedAt;

  @HiveField(5)
  bool isPinned;

  @HiveField(6)
  String? folderId;

  @HiveField(7)
  List<String> tags;

  @HiveField(8)
  String? fileId; // Link to associated file

  @HiveField(9)
  String preview; // Preview text for display

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.modifiedAt,
    this.isPinned = false,
    this.folderId,
    this.tags = const [],
    this.fileId,
    this.preview = '',
  });

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isPinned,
    String? folderId,
    List<String>? tags,
    String? fileId,
    String? preview,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isPinned: isPinned ?? this.isPinned,
      folderId: folderId ?? this.folderId,
      tags: tags ?? this.tags,
      fileId: fileId ?? this.fileId,
      preview: preview ?? this.preview,
    );
  }

  @override
  String toString() {
    return 'NoteModel(id: $id, title: $title, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

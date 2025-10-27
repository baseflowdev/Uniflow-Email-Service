import 'package:hive/hive.dart';

part 'app_file.g.dart';

@HiveType(typeId: 10)
class AppFile {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String path;

  @HiveField(3)
  String type;

  @HiveField(4)
  int size;

  @HiveField(5)
  DateTime dateAdded;

  @HiveField(6)
  String? parentFolderId;

  AppFile({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.dateAdded,
    this.parentFolderId,
  });

  // Helper getters
  bool get isPdf => type.toLowerCase() == 'pdf';
  bool get isImage => ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(type.toLowerCase());
  bool get isDocument => ['doc', 'docx', 'txt', 'rtf'].contains(type.toLowerCase());
  bool get isFolder => false; // Files are never folders

  // Format file size
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Get file type icon
  String get iconName {
    if (isPdf) return 'pdf';
    if (isImage) return 'image';
    if (isDocument) return 'document';
    return 'file';
  }

  AppFile copyWith({
    String? id,
    String? name,
    String? path,
    String? type,
    int? size,
    DateTime? dateAdded,
    String? parentFolderId,
    bool clearParentFolderId = false,
  }) {
    return AppFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      size: size ?? this.size,
      dateAdded: dateAdded ?? this.dateAdded,
      parentFolderId: clearParentFolderId ? null : (parentFolderId ?? this.parentFolderId),
    );
  }

  @override
  String toString() {
    return 'AppFile(id: $id, name: $name, type: $type, size: $size)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppFile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

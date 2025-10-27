import 'package:hive/hive.dart';

part 'app_folder.g.dart';

@HiveType(typeId: 11)
class AppFolder {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdAt;

  AppFolder({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  // Helper getters
  bool get isFolder => true; // Folders are always folders
  bool get isPdf => false;
  bool get isImage => false;
  bool get isDocument => false;

  // Format creation date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  // Get folder icon
  String get iconName => 'folder';

  AppFolder copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return AppFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AppFolder(id: $id, name: $name, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppFolder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

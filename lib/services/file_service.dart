import 'package:hive/hive.dart';
import 'package:uniflow/models/file_model.dart';

class FileService {
  late Box<FileModel> _filesBox;

  Future<void> initialize() async {
    _filesBox = Hive.box<FileModel>('files');
  }

  Future<List<FileModel>> getAllFiles() async {
    return _filesBox.values.toList();
  }

  Future<FileModel?> getFileById(String id) async {
    return _filesBox.get(id);
  }

  Future<void> saveFile(FileModel file) async {
    await _filesBox.put(file.id, file);
  }

  Future<void> deleteFile(String id) async {
    await _filesBox.delete(id);
  }

  Future<List<FileModel>> getFilesByFolder(String? folderId) async {
    return _filesBox.values
        .where((file) => file.parentFolderId == folderId)
        .toList();
  }

  Future<List<FileModel>> searchFiles(String query) async {
    return _filesBox.values
        .where((file) => file.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<List<FileModel>> getFilesByType(String type) async {
    return _filesBox.values
        .where((file) => file.type == type)
        .toList();
  }

  Future<List<FileModel>> getRecentFiles({int limit = 10}) async {
    final files = _filesBox.values.toList();
    files.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return files.take(limit).toList();
  }

  Future<int> getTotalFileCount() async {
    return _filesBox.length;
  }

  Future<int> getTotalStorageUsed() async {
    final files = _filesBox.values.where((file) => !file.isFolder).toList();
    int totalSize = 0;
    for (final file in files) {
      totalSize += file.size;
    }
    return totalSize;
  }

  void dispose() {
    // Hive boxes are managed globally, no need to close here
  }
}


import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/app_folder.dart';
import '../models/app_file.dart';

class FolderService {
  static const String _foldersBoxName = 'folders';
  static const String _filesBoxName = 'files';
  late Box<AppFolder> _foldersBox;
  late Box<AppFile> _filesBox;

  /// Initialize the folder service by opening the Hive boxes
  Future<void> initialize() async {
    _foldersBox = Hive.box<AppFolder>(_foldersBoxName);
    _filesBox = Hive.box<AppFile>(_filesBoxName);
  }

  /// Create a new folder
  Future<AppFolder> createFolder(String name) async {
    try {
      // Generate unique ID
      final uuid = const Uuid();
      final folderId = uuid.v4();
      
      // Create AppFolder object
      final folder = AppFolder(
        id: folderId,
        name: name.trim(),
        createdAt: DateTime.now(),
      );

      // Save to Hive
      await _foldersBox.put(folderId, folder);
      
      return folder;
    } catch (e) {
      throw Exception('Failed to create folder: $e');
    }
  }

  /// Rename a folder
  Future<void> renameFolder(String id, String newName) async {
    try {
      final folder = _foldersBox.get(id);
      if (folder != null) {
        final updatedFolder = folder.copyWith(name: newName.trim());
        await _foldersBox.put(id, updatedFolder);
      } else {
        throw Exception('Folder not found');
      }
    } catch (e) {
      throw Exception('Failed to rename folder: $e');
    }
  }

  /// Delete a folder and move its files to root folder
  Future<void> deleteFolder(String id) async {
    try {
      final folder = _foldersBox.get(id);
      if (folder == null) {
        throw Exception('Folder not found');
      }

      // Get all files in this folder
      final filesInFolder = _filesBox.values
          .where((file) => file.parentFolderId == id)
          .toList();

      // Move all files to root folder (parentFolderId = null)
      for (final file in filesInFolder) {
        final updatedFile = file.copyWith(parentFolderId: null);
        await _filesBox.put(file.id, updatedFile);
      }

      // Delete the folder
      await _foldersBox.delete(id);
    } catch (e) {
      throw Exception('Failed to delete folder: $e');
    }
  }

  /// Get all folders
  Future<List<AppFolder>> getFolders() async {
    try {
      final allFolders = _foldersBox.values.toList();
      // Sort by creation date (newest first)
      allFolders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allFolders;
    } catch (e) {
      throw Exception('Failed to get folders: $e');
    }
  }

  /// Get a specific folder by ID
  Future<AppFolder?> getFolder(String id) async {
    try {
      return _foldersBox.get(id);
    } catch (e) {
      throw Exception('Failed to get folder: $e');
    }
  }

  /// Get folder count
  Future<int> getFolderCount() async {
    try {
      return _foldersBox.length;
    } catch (e) {
      throw Exception('Failed to get folder count: $e');
    }
  }

  /// Check if folder name already exists
  Future<bool> folderNameExists(String name, {String? excludeId}) async {
    try {
      final allFolders = _foldersBox.values.toList();
      return allFolders.any((folder) => 
        folder.name.toLowerCase() == name.toLowerCase() && 
        folder.id != excludeId
      );
    } catch (e) {
      throw Exception('Failed to check folder name: $e');
    }
  }

  /// Get files in a specific folder
  Future<List<AppFile>> getFilesInFolder(String folderId) async {
    try {
      final allFiles = _filesBox.values.toList();
      return allFiles.where((file) => file.parentFolderId == folderId).toList();
    } catch (e) {
      throw Exception('Failed to get files in folder: $e');
    }
  }

  /// Get folder statistics
  Future<Map<String, dynamic>> getFolderStats(String folderId) async {
    try {
      final folder = _foldersBox.get(folderId);
      if (folder == null) {
        throw Exception('Folder not found');
      }

      final filesInFolder = await getFilesInFolder(folderId);
      final totalSize = filesInFolder.fold(0, (total, file) => total + file.size);
      
      return {
        'folder': folder,
        'fileCount': filesInFolder.length,
        'totalSize': totalSize,
        'formattedSize': _formatSize(totalSize),
      };
    } catch (e) {
      throw Exception('Failed to get folder stats: $e');
    }
  }

  /// Search folders by name
  Future<List<AppFolder>> searchFolders(String query) async {
    try {
      final allFolders = _foldersBox.values.toList();
      final lowercaseQuery = query.toLowerCase();
      
      return allFolders.where((folder) {
        return folder.name.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search folders: $e');
    }
  }

  /// Get recent folders (last 10)
  Future<List<AppFolder>> getRecentFolders({int limit = 10}) async {
    try {
      final allFolders = _foldersBox.values.toList();
      allFolders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allFolders.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get recent folders: $e');
    }
  }

  /// Helper method to format file size
  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
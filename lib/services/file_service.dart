import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/app_file.dart';

class FileService {
  static const String _filesBoxName = 'files';
  late Box<AppFile> _filesBox;

  /// Initialize the file service by opening the Hive box
  Future<void> initialize() async {
    _filesBox = Hive.box<AppFile>(_filesBoxName);
  }

  /// Import a file using FilePicker and save it to Hive
  /// Returns the created AppFile or null if user cancels
  Future<AppFile?> importFile({String? targetFolderId}) async {
    try {
      // Use FilePicker to select files
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'doc', 'docx', 'txt', 'rtf'],
        allowMultiple: true, // Enable multiple file selection
      );

      if (result != null && result.files.isNotEmpty) {
        // For backward compatibility, return the first file
        return await _processFile(result.files.first, targetFolderId);
      }
      
      return null; // User cancelled
    } catch (e) {
      throw Exception('Failed to import file: $e');
    }
  }

  /// Import multiple files using FilePicker and save them to Hive
  /// Returns a list of created AppFiles or empty list if user cancels
  Future<List<AppFile>> importMultipleFiles({String? targetFolderId}) async {
    try {
      // Use FilePicker to select files
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'doc', 'docx', 'txt', 'rtf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        List<AppFile> importedFiles = [];
        
        for (final pickedFile in result.files) {
          final appFile = await _processFile(pickedFile, targetFolderId);
          if (appFile != null) {
            importedFiles.add(appFile);
          }
        }
        
        return importedFiles;
      }
      
      return []; // User cancelled
    } catch (e) {
      throw Exception('Failed to import files: $e');
    }
  }

  /// Process a single file and save it to Hive
  Future<AppFile?> _processFile(PlatformFile pickedFile, String? targetFolderId) async {
    // Generate unique ID
    final uuid = const Uuid();
    final fileId = uuid.v4();
    
    // Get file extension
    final fileName = pickedFile.name;
    final fileExtension = fileName.split('.').last.toLowerCase();
    
    // Handle web vs mobile file path
    String filePath = '';
    if (kIsWeb) {
      // On web, we can't access the file path, so we'll use a placeholder
      // The actual file content is available via pickedFile.bytes
      filePath = 'web_file_$fileId.$fileExtension';
    } else {
      // On mobile, we can use the actual file path
      filePath = pickedFile.path ?? '';
    }
    
    // Create AppFile object
    final appFile = AppFile(
      id: fileId,
      name: fileName,
      path: filePath,
      type: fileExtension,
      size: pickedFile.size ?? 0,
      dateAdded: DateTime.now(),
      parentFolderId: targetFolderId, // Use target folder if specified
    );

    // Save to Hive
    await _filesBox.put(fileId, appFile);
    
    return appFile;
  }

  /// Delete a file from Hive (does not delete physical file)
  Future<void> deleteFile(String id) async {
    try {
      await _filesBox.delete(id);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get all files, optionally filtered by folder
  Future<List<AppFile>> getFiles({String? folderId}) async {
    try {
      final allFiles = _filesBox.values.toList();
      
      if (folderId == null) {
        // Return files in root folder (no parentFolderId)
        return allFiles.where((file) => file.parentFolderId == null).toList();
      } else {
        // Return ONLY files in the specific folder
        return allFiles.where((file) => 
          file.parentFolderId == folderId
        ).toList();
      }
    } catch (e) {
      throw Exception('Failed to get files: $e');
    }
  }

  /// Rename a file
  Future<void> renameFile(String id, String newName) async {
    try {
      final file = _filesBox.get(id);
      if (file != null) {
        final updatedFile = file.copyWith(name: newName);
        await _filesBox.put(id, updatedFile);
      } else {
        throw Exception('File not found');
      }
    } catch (e) {
      throw Exception('Failed to rename file: $e');
    }
  }

  /// Get a specific file by ID
  Future<AppFile?> getFile(String id) async {
    try {
      return _filesBox.get(id);
    } catch (e) {
      throw Exception('Failed to get file: $e');
    }
  }

  /// Get recent files (last 10)
  Future<List<AppFile>> getRecentFiles({int limit = 10}) async {
    try {
      final allFiles = _filesBox.values.toList();
      allFiles.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      return allFiles.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get recent files: $e');
    }
  }

  /// Search files by name or type
  Future<List<AppFile>> searchFiles(String query) async {
    try {
      final allFiles = _filesBox.values.toList();
      final lowercaseQuery = query.toLowerCase();
      
      return allFiles.where((file) {
        return file.name.toLowerCase().contains(lowercaseQuery) ||
               file.type.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search files: $e');
    }
  }

  /// Move file to a different folder
  Future<void> moveFile(String fileId, String? targetFolderId) async {
    try {
      final file = _filesBox.get(fileId);
      if (file != null) {
        // If targetFolderId is null, we want to move to root (clear parentFolderId)
        final updatedFile = targetFolderId == null
            ? file.copyWith(clearParentFolderId: true)
            : file.copyWith(parentFolderId: targetFolderId);
        await _filesBox.put(fileId, updatedFile);
      } else {
        throw Exception('File not found');
      }
    } catch (e) {
      throw Exception('Failed to move file: $e');
    }
  }

  /// Get file count by type
  Future<Map<String, int>> getFileCountByType() async {
    try {
      final allFiles = _filesBox.values.toList();
      final Map<String, int> countByType = {};
      
      for (final file in allFiles) {
        countByType[file.type] = (countByType[file.type] ?? 0) + 1;
      }
      
      return countByType;
    } catch (e) {
      throw Exception('Failed to get file count by type: $e');
    }
  }

  /// Get total storage used by all files
  Future<int> getTotalStorageUsed() async {
    try {
      final allFiles = _filesBox.values.toList();
      return allFiles.fold<int>(0, (total, file) => total + file.size);
    } catch (e) {
      throw Exception('Failed to get total storage used: $e');
    }
  }
}
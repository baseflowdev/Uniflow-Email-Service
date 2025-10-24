import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:uniflow/models/file_model.dart';
import 'package:uniflow/services/file_service.dart';

class FileProvider extends ChangeNotifier {
  final FileService _fileService = FileService();
  final Uuid _uuid = const Uuid();
  
  List<FileModel> _files = [];
  List<FileModel> _filteredFiles = [];
  String _searchQuery = '';
  String _currentFolderId = '';
  bool _isGridView = false;
  bool _isLoading = false;
  String? _error;

  List<FileModel> get files => _filteredFiles;
  List<FileModel> get allFiles => _files;
  String get searchQuery => _searchQuery;
  String get currentFolderId => _currentFolderId;
  bool get isGridView => _isGridView;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<FileModel> get folders {
    return _files.where((file) => file.isFolder).toList();
  }

  List<FileModel> get recentFiles {
    final sortedFiles = List<FileModel>.from(_files);
    sortedFiles.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return sortedFiles.take(5).toList();
  }

  List<FileModel> get filesInCurrentFolder {
    return _files.where((file) => file.parentFolderId == _currentFolderId).toList();
  }

  @override
  void dispose() {
    _fileService.dispose();
    super.dispose();
  }

  Future<void> loadFiles() async {
    _setLoading(true);
    try {
      _files = await _fileService.getAllFiles();
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = 'Failed to load files: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createFolder(String name) async {
    try {
      final folder = FileModel(
        id: _uuid.v4(),
        name: name,
        path: '',
        type: 'folder',
        size: 0,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        parentFolderId: _currentFolderId,
      );
      
      await _fileService.saveFile(folder);
      _files.add(folder);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create folder: $e';
      notifyListeners();
    }
  }

  Future<void> importFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        for (final file in result.files) {
          await _importSingleFile(file);
        }
        await loadFiles();
      }
    } catch (e) {
      _error = 'Failed to import file: $e';
      notifyListeners();
    }
  }

  Future<void> _importSingleFile(PlatformFile platformFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filesDir = Directory(path.join(appDir.path, 'files'));
      if (!await filesDir.exists()) {
        await filesDir.create(recursive: true);
      }

      final fileName = platformFile.name;
      final fileExtension = path.extension(fileName).toLowerCase();
      final fileType = _getFileType(fileExtension);
      
      final newPath = path.join(filesDir.path, fileName);
      final file = File(newPath);
      await file.writeAsBytes(platformFile.bytes!);

      final fileModel = FileModel(
        id: _uuid.v4(),
        name: fileName,
        path: newPath,
        type: fileType,
        size: platformFile.size,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        parentFolderId: _currentFolderId,
      );

      await _fileService.saveFile(fileModel);
    } catch (e) {
      throw Exception('Failed to import file: $e');
    }
  }

  String _getFileType(String extension) {
    switch (extension) {
      case '.pdf':
        return 'pdf';
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return 'image';
      case '.doc':
      case '.docx':
      case '.txt':
        return 'document';
      default:
        return 'document';
    }
  }

  Future<void> renameFile(String fileId, String newName) async {
    try {
      final fileIndex = _files.indexWhere((file) => file.id == fileId);
      if (fileIndex != -1) {
        final updatedFile = _files[fileIndex].copyWith(
          name: newName,
          modifiedAt: DateTime.now(),
        );
        await _fileService.saveFile(updatedFile);
        _files[fileIndex] = updatedFile;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to rename file: $e';
      notifyListeners();
    }
  }

  Future<void> deleteFile(String fileId) async {
    try {
      final file = _files.firstWhere((f) => f.id == fileId);
      
      // Delete physical file if it exists
      if (file.path.isNotEmpty) {
        final physicalFile = File(file.path);
        if (await physicalFile.exists()) {
          await physicalFile.delete();
        }
      }
      
      // Delete from database
      await _fileService.deleteFile(fileId);
      _files.removeWhere((f) => f.id == fileId);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete file: $e';
      notifyListeners();
    }
  }

  Future<void> moveFile(String fileId, String? newParentFolderId) async {
    try {
      final fileIndex = _files.indexWhere((file) => file.id == fileId);
      if (fileIndex != -1) {
        final updatedFile = _files[fileIndex].copyWith(
          parentFolderId: newParentFolderId,
          modifiedAt: DateTime.now(),
        );
        await _fileService.saveFile(updatedFile);
        _files[fileIndex] = updatedFile;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to move file: $e';
      notifyListeners();
    }
  }

  void navigateToFolder(String? folderId) {
    _currentFolderId = folderId ?? '';
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  void _applyFilters() {
    _filteredFiles = _files.where((file) {
      // Filter by current folder
      if (file.parentFolderId != _currentFolderId) return false;
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        return file.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      
      return true;
    }).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}


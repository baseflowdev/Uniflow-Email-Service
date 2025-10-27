import 'package:flutter/foundation.dart';
import '../models/app_file.dart';
import '../models/app_folder.dart';
import '../services/file_service.dart';
import '../services/folder_service.dart';

class FileProvider with ChangeNotifier {
  final FileService _fileService = FileService();
  final FolderService _folderService = FolderService();
  
  List<AppFile> _files = [];
  List<AppFolder> _folders = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _currentFolderId;
  bool _isGridView = true;
  String _sortBy = 'name'; // 'name', 'date', 'size'
  bool _sortAscending = true;

  // Getters
  List<AppFile> get files => _files;
  List<AppFolder> get folders => _folders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get currentFolderId => _currentFolderId;
  bool get isGridView => _isGridView;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Combined list of files and folders for display
  List<dynamic> get items {
    // Filter files and folders by current location
    List<AppFolder> filteredFolders = _folders;
    List<AppFile> filteredFiles = _files;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      // When searching, search through ALL files and folders with fuzzy matching
      final query = _searchQuery.toLowerCase();
      
      // Search folders with relevance scoring
      final folderScores = _folders.map((folder) {
        final score = _calculateRelevanceScore(folder.name, query);
        return MapEntry(folder, score);
      }).where((entry) => entry.value > 0)
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      filteredFolders = folderScores.map((entry) => entry.key).toList();
      
      // Search files with relevance scoring
      final fileScores = _files.map((file) {
        final nameScore = _calculateRelevanceScore(file.name, query);
        final typeScore = _calculateRelevanceScore(file.type, query);
        final totalScore = (nameScore * 2 + typeScore).round(); // Name is worth more than type
        return MapEntry(file, totalScore);
      }).where((entry) => entry.value > 0)
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      filteredFiles = fileScores.map((entry) => entry.key).toList();
    } else {
      // If we're in a folder, only show files in that folder (folders are shown at root)
      if (_currentFolderId != null) {
        filteredFiles = _files.where((file) => file.parentFolderId == _currentFolderId).toList();
        // Don't show folders when inside a folder to avoid confusion
        filteredFolders = [];
      } else {
        // In root folder, show all files in root
        filteredFiles = _files.where((file) => file.parentFolderId == null).toList();
      }
    }
    
    List<dynamic> combined = [...filteredFolders, ...filteredFiles];
    
    // Apply sorting
    combined.sort((a, b) {
      int comparison = 0;
      
      // When sorting by size, sort files by their actual size
      if (_sortBy == 'size') {
        if (a is AppFile && b is AppFile) {
          // Both are files - compare by size
          comparison = a.size.compareTo(b.size);
        } else if (a is AppFolder && b is AppFolder) {
          // Both are folders - keep their current order (don't sort folders when sorting by size)
          comparison = 0;
        } else if (a is AppFolder && b is AppFile) {
          // Folder vs file - folders first
          comparison = -1;
        } else if (a is AppFile && b is AppFolder) {
          // File vs folder - files after folders
          comparison = 1;
        }
      } else {
        // For other sorts, keep folders first
        if (a is AppFolder && b is AppFile) {
          comparison = -1; // Folders first
        } else if (a is AppFile && b is AppFolder) {
          comparison = 1; // Files after folders
        } else if (a is AppFolder && b is AppFolder) {
          switch (_sortBy) {
            case 'name':
              comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
              break;
            case 'date':
              comparison = a.createdAt.compareTo(b.createdAt);
              break;
            default:
              comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
        } else if (a is AppFile && b is AppFile) {
          switch (_sortBy) {
            case 'name':
              comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
              break;
            case 'date':
              comparison = a.dateAdded.compareTo(b.dateAdded);
              break;
            default:
              comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
        }
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return combined;
  }

  // Recent files for dashboard
  List<AppFile> get recentFiles {
    final allFiles = _files.toList();
    allFiles.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return allFiles.take(5).toList();
  }

  // Initialize the provider
  Future<void> initialize() async {
    try {
      // Initialize services without loading data to avoid blocking
      await _fileService.initialize();
      await _folderService.initialize();
      
      // Load data asynchronously without blocking
      loadFiles().catchError((e) {
        _setError('Failed to load files: $e');
      });
      
      loadFolders().catchError((e) {
        _setError('Failed to load folders: $e');
      });
    } catch (e) {
      _setError('Failed to initialize: $e');
    }
  }

  // Load files from storage
  Future<void> loadFiles() async {
    try {
      _files = await _fileService.getFiles(folderId: _currentFolderId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load files: $e');
    }
  }

  // Load folders from storage
  Future<void> loadFolders() async {
    try {
      _folders = await _folderService.getFolders();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load folders: $e');
    }
  }

  // Get folders (for external access)
  Future<List<AppFolder>> getFolders() async {
    try {
      return await _folderService.getFolders();
    } catch (e) {
      _setError('Failed to get folders: $e');
      return [];
    }
  }

  // Import a file
  Future<void> importFile() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Pass currentFolderId so files are added to the current folder
      final file = await _fileService.importFile(targetFolderId: _currentFolderId);
      if (file != null) {
        await loadFiles();
      }
    } catch (e) {
      _setError('Failed to import file: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Import multiple files
  Future<void> importMultipleFiles() async {
    _setLoading(true);
    _clearError();
    
    try {
      final importedFiles = await _fileService.importMultipleFiles(targetFolderId: _currentFolderId);
      if (importedFiles.isNotEmpty) {
        await loadFiles(); // Refresh the file list
      }
    } catch (e) {
      _setError('Failed to import files: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Move file to a specific folder
  Future<void> moveFileToFolder(String fileId, String? targetFolderId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _fileService.moveFile(fileId, targetFolderId);
      await loadFiles(); // Refresh the file list
    } catch (e) {
      _setError('Failed to move file: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a folder
  Future<void> createFolder(String name) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Check if folder name already exists
      final exists = await _folderService.folderNameExists(name);
      if (exists) {
        _setError('A folder with this name already exists');
        return;
      }
      
      await _folderService.createFolder(name);
      await loadFolders();
    } catch (e) {
      _setError('Failed to create folder: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete a file
  Future<void> deleteFile(String id) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _fileService.deleteFile(id);
      await loadFiles();
    } catch (e) {
      _setError('Failed to delete file: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete a folder
  Future<void> deleteFolder(String id) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _folderService.deleteFolder(id);
      await loadFolders();
      await loadFiles(); // Reload files in case some were moved to root
    } catch (e) {
      _setError('Failed to delete folder: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Rename a file
  Future<void> renameFile(String id, String newName) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _fileService.renameFile(id, newName);
      await loadFiles();
    } catch (e) {
      _setError('Failed to rename file: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Rename a folder
  Future<void> renameFolder(String id, String newName) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Check if folder name already exists (excluding current folder)
      final exists = await _folderService.folderNameExists(newName, excludeId: id);
      if (exists) {
        _setError('A folder with this name already exists');
        return;
      }
      
      await _folderService.renameFolder(id, newName);
      await loadFolders();
    } catch (e) {
      _setError('Failed to rename folder: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Navigate to a folder
  Future<void> navigateToFolder(String folderId) async {
    _currentFolderId = folderId;
    await loadFiles();
    notifyListeners();
  }

  // Navigate back to parent folder
  Future<void> navigateBack() async {
    _currentFolderId = null;
    await loadFiles();
    notifyListeners();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Toggle view mode (list/grid)
  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  // Set sort option
  void setSortBy(String sortBy) {
    if (_sortBy == sortBy) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = sortBy;
      _sortAscending = true;
    }
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get all files (for storage summary)
  List<AppFile> get allFiles => _files;

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Calculate relevance score for fuzzy search
  double _calculateRelevanceScore(String text, String query) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    // Exact match gets the highest score
    if (lowerText == lowerQuery) {
      return 1000.0;
    }
    
    // Starts with query gets high score
    if (lowerText.startsWith(lowerQuery)) {
      return 500.0 + (lowerText.length - lowerQuery.length) / 10.0;
    }
    
    // Contains query gets medium score
    if (lowerText.contains(lowerQuery)) {
      final index = lowerText.indexOf(lowerQuery);
      final distanceFromStart = index / lowerText.length;
      return 100.0 * (1.0 - distanceFromStart);
    }
    
    // Fuzzy matching: calculate similarity based on common characters
    int commonChars = 0;
    int queryIndex = 0;
    
    for (int i = 0; i < lowerText.length && queryIndex < lowerQuery.length; i++) {
      if (lowerText[i] == lowerQuery[queryIndex]) {
        commonChars++;
        queryIndex++;
      }
    }
    
    if (commonChars > 0 && queryIndex == lowerQuery.length) {
      // All query characters found in order
      final matchRatio = commonChars / lowerQuery.length;
      final textRatio = lowerQuery.length / lowerText.length;
      return 50.0 * matchRatio * textRatio;
    }
    
    // Check if all characters of query exist in text (any order)
    bool allCharsExist = true;
    for (int i = 0; i < lowerQuery.length; i++) {
      if (!lowerText.contains(lowerQuery[i])) {
        allCharsExist = false;
        break;
      }
    }
    
    if (allCharsExist) {
      return 10.0;
    }
    
    return 0.0;
  }
}
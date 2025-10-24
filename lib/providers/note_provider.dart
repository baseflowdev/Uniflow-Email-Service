import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:uniflow/models/note_model.dart';
import 'package:uniflow/services/note_service.dart';

class NoteProvider extends ChangeNotifier {
  final NoteService _noteService = NoteService();
  final Uuid _uuid = const Uuid();
  
  List<NoteModel> _notes = [];
  List<NoteModel> _filteredNotes = [];
  String _searchQuery = '';
  String _currentFolderId = '';
  bool _isLoading = false;
  String? _error;

  List<NoteModel> get notes => _filteredNotes;
  List<NoteModel> get allNotes => _notes;
  String get searchQuery => _searchQuery;
  String get currentFolderId => _currentFolderId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<NoteModel> get recentNotes {
    final sortedNotes = List<NoteModel>.from(_notes);
    sortedNotes.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return sortedNotes.take(5).toList();
  }

  List<NoteModel> get pinnedNotes {
    return _notes.where((note) => note.isPinned).toList();
  }

  List<NoteModel> get notesInCurrentFolder {
    return _notes.where((note) => note.folderId == _currentFolderId).toList();
  }

  @override
  void dispose() {
    _noteService.dispose();
    super.dispose();
  }

  Future<void> loadNotes() async {
    _setLoading(true);
    try {
      _notes = await _noteService.getAllNotes();
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = 'Failed to load notes: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createNote({String? title, String? content}) async {
    try {
      final note = NoteModel(
        id: _uuid.v4(),
        title: title ?? 'Untitled Note',
        content: content ?? '',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        folderId: _currentFolderId.isEmpty ? null : _currentFolderId,
      );
      
      await _noteService.saveNote(note);
      _notes.add(note);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create note: $e';
      notifyListeners();
    }
  }

  Future<void> updateNote(NoteModel note) async {
    try {
      final updatedNote = note.copyWith(modifiedAt: DateTime.now());
      await _noteService.saveNote(updatedNote);
      
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = updatedNote;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update note: $e';
      notifyListeners();
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _noteService.deleteNote(noteId);
      _notes.removeWhere((note) => note.id == noteId);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete note: $e';
      notifyListeners();
    }
  }

  Future<void> togglePin(String noteId) async {
    try {
      final noteIndex = _notes.indexWhere((note) => note.id == noteId);
      if (noteIndex != -1) {
        final updatedNote = _notes[noteIndex].copyWith(
          isPinned: !_notes[noteIndex].isPinned,
          modifiedAt: DateTime.now(),
        );
        await _noteService.saveNote(updatedNote);
        _notes[noteIndex] = updatedNote;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to toggle pin: $e';
      notifyListeners();
    }
  }

  Future<void> addTag(String noteId, String tag) async {
    try {
      final noteIndex = _notes.indexWhere((note) => note.id == noteId);
      if (noteIndex != -1) {
        final currentTags = List<String>.from(_notes[noteIndex].tags);
        if (!currentTags.contains(tag)) {
          currentTags.add(tag);
          final updatedNote = _notes[noteIndex].copyWith(
            tags: currentTags,
            modifiedAt: DateTime.now(),
          );
          await _noteService.saveNote(updatedNote);
          _notes[noteIndex] = updatedNote;
          _applyFilters();
          notifyListeners();
        }
      }
    } catch (e) {
      _error = 'Failed to add tag: $e';
      notifyListeners();
    }
  }

  Future<void> removeTag(String noteId, String tag) async {
    try {
      final noteIndex = _notes.indexWhere((note) => note.id == noteId);
      if (noteIndex != -1) {
        final currentTags = List<String>.from(_notes[noteIndex].tags);
        currentTags.remove(tag);
        final updatedNote = _notes[noteIndex].copyWith(
          tags: currentTags,
          modifiedAt: DateTime.now(),
        );
        await _noteService.saveNote(updatedNote);
        _notes[noteIndex] = updatedNote;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to remove tag: $e';
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

  void _applyFilters() {
    _filteredNotes = _notes.where((note) {
      // Filter by current folder
      if (note.folderId != _currentFolderId) return false;
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               note.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               note.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      }
      
      return true;
    }).toList();
    
    // Sort by pinned first, then by modified date
    _filteredNotes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.modifiedAt.compareTo(a.modifiedAt);
    });
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


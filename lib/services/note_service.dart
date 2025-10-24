import 'package:hive/hive.dart';
import 'package:uniflow/models/note_model.dart';

class NoteService {
  late Box<NoteModel> _notesBox;

  Future<void> initialize() async {
    _notesBox = Hive.box<NoteModel>('notes');
  }

  Future<List<NoteModel>> getAllNotes() async {
    return _notesBox.values.toList();
  }

  Future<NoteModel?> getNoteById(String id) async {
    return _notesBox.get(id);
  }

  Future<void> saveNote(NoteModel note) async {
    await _notesBox.put(note.id, note);
  }

  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  Future<List<NoteModel>> getNotesByFolder(String? folderId) async {
    return _notesBox.values
        .where((note) => note.folderId == folderId)
        .toList();
  }

  Future<List<NoteModel>> searchNotes(String query) async {
    return _notesBox.values
        .where((note) => 
            note.title.toLowerCase().contains(query.toLowerCase()) ||
            note.content.toLowerCase().contains(query.toLowerCase()) ||
            note.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }

  Future<List<NoteModel>> getPinnedNotes() async {
    return _notesBox.values
        .where((note) => note.isPinned)
        .toList();
  }

  Future<List<NoteModel>> getRecentNotes({int limit = 10}) async {
    final notes = _notesBox.values.toList();
    notes.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return notes.take(limit).toList();
  }

  Future<List<NoteModel>> getNotesByTag(String tag) async {
    return _notesBox.values
        .where((note) => note.tags.contains(tag))
        .toList();
  }

  Future<List<String>> getAllTags() async {
    final allTags = <String>{};
    for (final note in _notesBox.values) {
      allTags.addAll(note.tags);
    }
    return allTags.toList()..sort();
  }

  Future<int> getTotalNoteCount() async {
    return _notesBox.length;
  }

  void dispose() {
    // Hive boxes are managed globally, no need to close here
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uniflow/models/note_model.dart';
import 'package:uniflow/providers/note_provider.dart';
import 'package:uniflow/utils/app_colors.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;

  const NoteEditorScreen({
    super.key,
    this.note,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final noteProvider = context.read<NoteProvider>();
      
      if (widget.note == null) {
        // Create new note
        await noteProvider.createNote(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        );
      } else {
        // Update existing note
        final updatedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          modifiedAt: DateTime.now(),
        );
        await noteProvider.updateNote(updatedNote);
      }

      setState(() {
        _hasUnsavedChanges = false;
        _isSaving = false;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.note == null ? 'Note created' : 'Note updated')),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text('You have unsaved changes. Do you want to save them?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Discard'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
          
          if (result == true) {
            await _saveNote();
          }
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
          actions: [
            if (_hasUnsavedChanges)
              IconButton(
                onPressed: _isSaving ? null : _saveNote,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Title field
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Note title',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              // Content field
              Expanded(
                child: TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: 'Start writing your note...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _isSaving ? null : _saveNote,
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.save),
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:uniflow/models/note_model.dart';
import 'package:uniflow/providers/note_provider.dart';

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
  late QuillController _controller;
  late TextEditingController _titleController;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    
    if (widget.note != null) {
      _controller = QuillController.basic();
      try {
        // Parse content as JSON if it's a string representation of JSON
        final contentData = widget.note!.content;
        if (contentData is String) {
          try {
            // Try to parse as JSON first
            final jsonData = jsonDecode(contentData);
            _controller.document = Document.fromJson(jsonData);
          } catch (e) {
            // If JSON parsing fails, treat as plain text
            _controller.document = Document()..insert(0, contentData);
          }
        } else {
          _controller.document = Document.fromJson(contentData as List<dynamic>);
        }
      } catch (e) {
        // If fromJson fails, create a new document with the content as text
        _controller.document = Document()..insert(0, widget.note!.content.toString());
      }
    } else {
      _controller = QuillController.basic();
    }
    
    _controller.addListener(_onTextChanged);
    _titleController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _titleController.removeListener(_onTextChanged);
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Note title',
              border: InputBorder.none,
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          actions: [
            if (_hasUnsavedChanges)
              IconButton(
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                onPressed: _isSaving ? null : _saveNote,
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'pin':
                    _togglePin();
                    break;
                  case 'delete':
                    _deleteNote();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'pin',
                  child: ListTile(
                    leading: Icon(
                      widget.note?.isPinned == true
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                    ),
                    title: Text(
                      widget.note?.isPinned == true ? 'Unpin' : 'Pin',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (widget.note != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Toolbar - Temporarily disabled for compatibility
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.format_bold),
                    onPressed: () {
                      // TODO: Implement bold formatting
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_italic),
                    onPressed: () {
                      // TODO: Implement italic formatting
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_underlined),
                    onPressed: () {
                      // TODO: Implement underline formatting
                    },
                  ),
                  const Spacer(),
                  Text(
                    'Rich text editor - Toolbar coming soon',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            
            // Editor
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: QuillEditor.basic(
                  controller: _controller,
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _hasUnsavedChanges
            ? FloatingActionButton(
                onPressed: _isSaving ? null : _saveNote,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.save),
              )
            : null,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to save before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveNote();
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final content = _controller.document.toDelta().toJson();
      final title = _titleController.text.trim().isEmpty 
          ? 'Untitled Note' 
          : _titleController.text.trim();
      
      if (widget.note != null) {
        // Update existing note
        final updatedNote = widget.note!.copyWith(
          title: title,
          content: content.toString(),
          modifiedAt: DateTime.now(),
        );
        await context.read<NoteProvider>().updateNote(updatedNote);
      } else {
        // Create new note
        await context.read<NoteProvider>().createNote(
          title: title,
          content: content.toString(),
        );
      }
      
      setState(() {
        _hasUnsavedChanges = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _togglePin() {
    if (widget.note != null) {
      context.read<NoteProvider>().togglePin(widget.note!.id);
    }
  }

  void _deleteNote() {
    if (widget.note == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<NoteProvider>().deleteNote(widget.note!.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import 'package:uniflow/models/file_model.dart';
import 'package:uniflow/models/pdf_annotation.dart';
import 'package:uniflow/providers/file_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final FileModel file;

  const PdfViewerScreen({
    super.key,
    required this.file,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PDFViewController? _pdfViewController;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _error;
  bool _isAnnotationMode = false;
  List<PdfAnnotation> _annotations = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        actions: [
          IconButton(
            icon: Icon(_isAnnotationMode ? Icons.edit_off : Icons.edit),
            onPressed: () {
              setState(() {
                _isAnnotationMode = !_isAnnotationMode;
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'bookmark':
                  _addBookmark();
                  break;
                case 'share':
                  _sharePdf();
                  break;
                case 'info':
                  _showPdfInfo();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'bookmark',
                child: ListTile(
                  leading: Icon(Icons.bookmark_add),
                  title: Text('Add Bookmark'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'info',
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text('File Info'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Page indicator
          if (_totalPages > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Page $_currentPage of $_totalPages'),
                  Row(
                    children: [
                      // TODO: Re-enable zoom controls once supported in latest flutter_pdfview version.
                      IconButton(
                        icon: const Icon(Icons.zoom_out),
                        onPressed: () {
                          // _pdfViewController?.setZoom(_pdfViewController!.getZoom() - 0.5);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.zoom_in),
                        onPressed: () {
                          // _pdfViewController?.setZoom(_pdfViewController!.getZoom() + 0.5);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          // PDF Viewer
          Expanded(
            child: _buildPdfViewer(),
          ),
          
          // Annotation toolbar
          if (_isAnnotationMode)
            _buildAnnotationToolbar(),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading PDF',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return PDFView(
      filePath: widget.file.path,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: false,
      pageFling: true,
      pageSnap: true,
      onRender: (pages) {
        setState(() {
          _totalPages = pages!;
          _isLoading = false;
        });
      },
      onViewCreated: (PDFViewController controller) {
        _pdfViewController = controller;
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          _currentPage = page! + 1;
        });
      },
      onError: (error) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      },
      onPageError: (page, error) {
        setState(() {
          _error = 'Error loading page $page: $error';
        });
      },
    );
  }

  Widget _buildAnnotationToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAnnotationButton(
            icon: Icons.highlight,
            label: 'Highlight',
            onTap: () => _setAnnotationMode('highlight'),
          ),
          _buildAnnotationButton(
            icon: Icons.edit_note,
            label: 'Note',
            onTap: () => _setAnnotationMode('note'),
          ),
          _buildAnnotationButton(
            icon: Icons.format_underlined,
            label: 'Underline',
            onTap: () => _setAnnotationMode('underline'),
          ),
          _buildAnnotationButton(
            icon: Icons.strikethrough_s,
            label: 'Strikethrough',
            onTap: () => _setAnnotationMode('strikethrough'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotationButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _setAnnotationMode(String mode) {
    // TODO: Implement annotation mode
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Annotation mode: $mode')),
    );
  }

  void _addBookmark() {
    // TODO: Implement bookmark functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmark added')),
    );
  }

  void _sharePdf() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _showPdfInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${widget.file.name}'),
            Text('Size: ${widget.file.displaySize}'),
            Text('Type: ${widget.file.type.toUpperCase()}'),
            Text('Created: ${_formatDate(widget.file.createdAt)}'),
            Text('Modified: ${_formatDate(widget.file.modifiedAt)}'),
            Text('Pages: $_totalPages'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}


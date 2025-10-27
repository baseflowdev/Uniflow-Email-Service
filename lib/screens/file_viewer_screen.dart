import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart';
import '../models/app_file.dart';
import '../utils/app_colors.dart';

class FileViewerScreen extends StatelessWidget {
  final AppFile file;

  const FileViewerScreen({
    super.key,
    required this.file,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          file.name,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareFile(context),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: _buildFileContent(context),
    );
  }

  Widget _buildFileContent(BuildContext context) {
    if (file.isPdf) {
      return _buildPdfViewer(context);
    } else if (file.isImage) {
      return _buildImageViewer(context);
    } else {
      return _buildGenericFileViewer(context);
    }
  }

  Widget _buildPdfViewer(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'PDF Viewer',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'This PDF will open in your default PDF viewer',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openFile(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Image Viewer',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'This image will open in your default image viewer',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openFile(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Image'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericFileViewer(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'File Viewer',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'This file will open in your default application',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openFile(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open File'),
          ),
        ],
      ),
    );
  }

  void _openFile(BuildContext context) async {
    try {
      if (kIsWeb) {
        // On web, we can download the file
        _downloadFileOnWeb(context);
      } else {
        final result = await OpenFilex.open(file.path);
        if (result.type != ResultType.done) {
          _showErrorSnackBar(context, 'Failed to open file: ${result.message}');
        }
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to open file: $e');
    }
  }

  void _downloadFileOnWeb(BuildContext context) {
    // For web, we'll show a message about downloading
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download File'),
        content: Text('To view "${file.name}", please download it to your device. The file is stored locally in the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _shareFile(BuildContext context) {
    // TODO: Implement file sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('File Information'),
              onTap: () {
                Navigator.pop(context);
                _showFileInfo(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFileInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', file.name),
            _buildInfoRow('Type', file.type.toUpperCase()),
            _buildInfoRow('Size', file.formattedSize),
            _buildInfoRow('Date Added', _formatDate(file.dateAdded)),
            _buildInfoRow('Path', file.path),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: file.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'New name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement rename functionality
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rename functionality coming soon')),
              );
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement delete functionality
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete functionality coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:uniflow/models/file_model.dart';

class FileCard extends StatelessWidget {
  final FileModel file;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isCompact;

  const FileCard({
    super.key,
    required this.file,
    this.onTap,
    this.onLongPress,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        child: isCompact ? _buildCompactCard(context) : _buildFullCard(context),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(),
            size: 32,
            color: _getFileColor(context),
          ),
          const SizedBox(height: 8),
          Text(
            file.name,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFullCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // File icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getFileColor(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getFileIcon(),
              color: _getFileColor(context),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      file.displaySize,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(file.modifiedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action button
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: onLongPress,
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon() {
    if (file.isFolder) return Icons.folder;
    if (file.isPdf) return Icons.picture_as_pdf;
    if (file.isImage) return Icons.image;
    if (file.isDocument) return Icons.description;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(BuildContext context) {
    if (file.isFolder) return Colors.orange;
    if (file.isPdf) return Colors.red;
    if (file.isImage) return Colors.green;
    if (file.isDocument) return Colors.blue;
    return Theme.of(context).disabledColor;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}


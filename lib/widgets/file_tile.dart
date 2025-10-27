import 'package:flutter/material.dart';
import '../models/app_file.dart';
import '../utils/app_colors.dart';

class FileTile extends StatelessWidget {
  final AppFile file;
  final bool isGridView;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRename;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;

  const FileTile({
    super.key,
    required this.file,
    this.isGridView = true,
    this.onTap,
    this.onLongPress,
    this.onRename,
    this.onMove,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return _buildGridTile(context);
    } else {
      return _buildListTile(context);
    }
  }

  Widget _buildGridTile(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // File icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getFileColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileIcon(),
                  color: _getFileColor(),
                  size: 24,
                ),
              ),
              
              const SizedBox(height: 6),
              
              // File name
              Flexible(
                child: Text(
                  file.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 3),
              
              // File size and type
              Flexible(
                child: Text(
                  '${file.formattedSize} • ${file.type.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).disabledColor,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getFileColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileIcon(),
            color: _getFileColor(),
            size: 20,
          ),
        ),
        title: Text(
          file.name,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${file.formattedSize} • ${file.type.toUpperCase()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
            Text(
              _formatDate(file.dateAdded),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'rename':
                onRename?.call();
                break;
              case 'move':
                onMove?.call();
                break;
              case 'delete':
                onDelete?.call();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'rename',
              enabled: onRename != null,
              child: const ListTile(
                leading: Icon(Icons.edit),
                title: Text('Rename'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'move',
              enabled: onMove != null,
              child: const ListTile(
                leading: Icon(Icons.move_to_inbox),
                title: Text('Move'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              enabled: onDelete != null,
              child: const ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    if (file.isPdf) return Icons.picture_as_pdf;
    if (file.isImage) return Icons.image;
    if (file.isDocument) return Icons.description;
    return Icons.insert_drive_file;
  }

  Color _getFileColor() {
    if (file.isPdf) return Colors.red;
    if (file.isImage) return Colors.green;
    if (file.isDocument) return Colors.blue;
    return AppColors.grey600;
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
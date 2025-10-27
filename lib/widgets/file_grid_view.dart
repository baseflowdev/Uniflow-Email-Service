import 'package:flutter/material.dart';
import '../models/app_file.dart';
import '../models/app_folder.dart';
import 'file_tile.dart';
import 'folder_tile.dart';

class FileGridView extends StatelessWidget {
  final List<dynamic> items; // Can contain both AppFile and AppFolder
  final Function(dynamic)? onItemTap;
  final Function(dynamic)? onItemLongPress;

  const FileGridView({
    super.key,
    required this.items,
    this.onItemTap,
    this.onItemLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items found'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        
        if (item is AppFolder) {
          return _buildFolderCard(context, item);
        } else if (item is AppFile) {
          return _buildFileCard(context, item);
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFolderCard(BuildContext context, AppFolder folder) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onItemTap?.call(folder),
        onLongPress: () => onItemLongPress?.call(folder),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                folder.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                folder.formattedDate,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileCard(BuildContext context, AppFile file) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onItemTap?.call(file),
        onLongPress: () => onItemLongPress?.call(file),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getFileTypeColor(file).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileTypeIcon(file),
                  color: _getFileTypeColor(file),
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                file.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                file.formattedSize,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileTypeIcon(AppFile file) {
    if (file.isPdf) return Icons.picture_as_pdf_rounded;
    if (file.isImage) return Icons.image_rounded;
    if (file.isDocument) return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getFileTypeColor(AppFile file) {
    if (file.isPdf) return Colors.red;
    if (file.isImage) return Colors.green;
    if (file.isDocument) return Colors.blue;
    return Colors.grey;
  }
}
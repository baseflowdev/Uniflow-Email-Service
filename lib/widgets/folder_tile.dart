import 'package:flutter/material.dart';
import '../models/app_folder.dart';
import '../utils/app_colors.dart';

class FolderTile extends StatelessWidget {
  final AppFolder folder;
  final bool isGridView;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const FolderTile({
    super.key,
    required this.folder,
    this.isGridView = true,
    this.onTap,
    this.onLongPress,
    this.onRename,
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
              // Folder icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.folder,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              
              const SizedBox(height: 6),
              
              // Folder name
              Flexible(
                child: Text(
                  folder.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 3),
              
              // Creation date
              Flexible(
                child: Text(
                  folder.formattedDate,
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
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.folder,
            color: AppColors.accent,
            size: 20,
          ),
        ),
        title: Text(
          folder.name,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          folder.formattedDate,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).disabledColor,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'rename':
                onRename?.call();
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
}
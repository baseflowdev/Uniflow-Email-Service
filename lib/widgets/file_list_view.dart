import 'package:flutter/material.dart';
import '../models/app_file.dart';
import '../models/app_folder.dart';
import 'file_tile.dart';
import 'folder_tile.dart';

class FileListView extends StatelessWidget {
  final List<dynamic> items; // Can contain both AppFile and AppFolder
  final Function(dynamic)? onItemTap;
  final Function(dynamic)? onItemLongPress;

  const FileListView({
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        
        if (item is AppFolder) {
          return FolderTile(
            folder: item,
            onTap: () => onItemTap?.call(item),
            onLongPress: () => onItemLongPress?.call(item),
          );
        } else if (item is AppFile) {
          return FileTile(
            file: item,
            onTap: () => onItemTap?.call(item),
            onLongPress: () => onItemLongPress?.call(item),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }
}
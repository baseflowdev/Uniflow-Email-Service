import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uniflow/providers/file_provider.dart';
import 'package:uniflow/widgets/file_grid_view.dart';
import 'package:uniflow/widgets/file_list_view.dart';
import 'package:uniflow/widgets/add_file_bottom_sheet.dart';
import 'package:uniflow/screens/file_viewer_screen.dart';
import 'package:uniflow/models/app_file.dart';
import 'package:uniflow/models/app_folder.dart';
import 'package:uniflow/utils/app_colors.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<FileProvider>(
          builder: (context, fileProvider, child) {
            if (fileProvider.currentFolderId != null) {
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => fileProvider.navigateBack(),
                  ),
                  const Text('Files'),
                ],
              );
            }
            return const Text('My Files');
          },
        ),
        actions: [
          Consumer<FileProvider>(
            builder: (context, fileProvider, child) {
              return IconButton(
                icon: Icon(
                  fileProvider.isGridView ? Icons.view_list : Icons.grid_view,
                ),
                onPressed: fileProvider.toggleViewMode,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search files...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<FileProvider>().setSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                context.read<FileProvider>().setSearchQuery(value);
              },
            ),
          ),
          
          // Files List
          Expanded(
            child: Consumer<FileProvider>(
              builder: (context, fileProvider, child) {
                if (fileProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (fileProvider.files.isEmpty) {
                  return _buildEmptyState();
                }
                
                return RefreshIndicator(
                  onRefresh: fileProvider.loadFiles,
                  child: fileProvider.isGridView
                      ? FileGridView(
                          items: fileProvider.items,
                          onItemTap: _onItemTap,
                          onItemLongPress: _onItemLongPress,
                        )
                      : FileListView(
                          items: fileProvider.items,
                          onItemTap: _onItemTap,
                          onItemLongPress: _onItemLongPress,
                        ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddFileBottomSheet();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _onItemTap(dynamic item) {
    if (item is AppFolder) {
      context.read<FileProvider>().navigateToFolder(item.id);
    } else if (item is AppFile) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FileViewerScreen(file: item),
        ),
      );
    }
  }

  void _onItemLongPress(dynamic item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildItemActionSheet(item),
    );
  }

  void _showAddFileBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => AddFileBottomSheet(
        onImportFile: () => context.read<FileProvider>().importFile(),
        onCreateFolder: () => _showCreateFolderDialog(),
      ),
    );
  }

  Widget _buildItemActionSheet(dynamic item) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(item);
            },
          ),
          if (item is AppFile) ...[
            ListTile(
              leading: const Icon(Icons.move_to_inbox),
              title: const Text('Move'),
              onTap: () {
                Navigator.pop(context);
                _showMoveDialog(item);
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteDialog(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No files yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Import some files or create a folder to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Folder name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<FileProvider>().createFolder(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(dynamic item) {
    final controller = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'New name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                if (item is AppFile) {
                  context.read<FileProvider>().renameFile(item.id, controller.text);
                } else if (item is AppFolder) {
                  context.read<FileProvider>().renameFolder(item.id, controller.text);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(AppFile file) {
    // TODO: Implement move dialog with folder selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Move functionality coming soon')),
    );
  }

  void _showDeleteDialog(dynamic item) {
    final isFolder = item is AppFolder;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${isFolder ? 'Folder' : 'File'}'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (item is AppFile) {
                context.read<FileProvider>().deleteFile(item.id);
              } else if (item is AppFolder) {
                context.read<FileProvider>().deleteFolder(item.id);
              }
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


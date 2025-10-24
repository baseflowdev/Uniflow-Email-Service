import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uniflow/providers/file_provider.dart';
import 'package:uniflow/widgets/file_card.dart';
import 'package:uniflow/widgets/file_grid_view.dart';
import 'package:uniflow/widgets/file_list_view.dart';
import 'package:uniflow/screens/pdf_viewer_screen.dart';

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
      context.read<FileProvider>().loadFiles();
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
        title: const Text('Files'),
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
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'create_folder':
                  _showCreateFolderDialog();
                  break;
                case 'import_file':
                  context.read<FileProvider>().importFile();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create_folder',
                child: ListTile(
                  leading: Icon(Icons.create_new_folder),
                  title: Text('Create Folder'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import_file',
                child: ListTile(
                  leading: Icon(Icons.file_upload),
                  title: Text('Import File'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
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
                          files: fileProvider.files,
                          onFileTap: _onFileTap,
                          onFileLongPress: _onFileLongPress,
                        )
                      : FileListView(
                          files: fileProvider.files,
                          onFileTap: _onFileTap,
                          onFileLongPress: _onFileLongPress,
                        ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<FileProvider>().importFile();
        },
        child: const Icon(Icons.file_upload),
      ),
    );
  }

  void _onFileTap(file) {
    if (file.isFolder) {
      context.read<FileProvider>().navigateToFolder(file.id);
    } else if (file.isPdf) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(file: file),
        ),
      );
    } else {
      // Handle other file types
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening ${file.name}...'),
        ),
      );
    }
  }

  void _onFileLongPress(file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFileActionSheet(file),
    );
  }

  Widget _buildFileActionSheet(file) {
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
              _showRenameDialog(file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.move_to_inbox),
            title: const Text('Move'),
            onTap: () {
              Navigator.pop(context);
              _showMoveDialog(file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteDialog(file);
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

  void _showRenameDialog(file) {
    final controller = TextEditingController(text: file.name);
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
                context.read<FileProvider>().renameFile(file.id, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(file) {
    // TODO: Implement move dialog with folder selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Move functionality coming soon')),
    );
  }

  void _showDeleteDialog(file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<FileProvider>().deleteFile(file.id);
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


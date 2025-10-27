import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/file_provider.dart';
import '../../widgets/file_tile.dart';
import '../../widgets/folder_tile.dart';
import '../../widgets/add_file_bottom_sheet.dart';
import '../../screens/file_viewer_screen.dart';
import '../../models/app_file.dart';
import '../../models/app_folder.dart';
import '../../utils/app_colors.dart';

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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final fileProvider = context.read<FileProvider>();
        if (fileProvider.currentFolderId != null) {
          // Inside a folder, navigate back to parent folder
          fileProvider.navigateBack();
        }
        // At root level, don't do anything (let MainScreen handle it)
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Consumer<FileProvider>(
            builder: (context, fileProvider, child) {
              if (fileProvider.currentFolderId != null) {
                return IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    fileProvider.navigateBack();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        title: Consumer<FileProvider>(
          builder: (context, fileProvider, child) {
            // Get current folder name if inside a folder
            if (fileProvider.currentFolderId != null) {
              final currentFolder = fileProvider.folders.firstWhere(
                (folder) => folder.id == fileProvider.currentFolderId,
                orElse: () => fileProvider.folders.first,
              );
              
              return _buildBreadcrumb(context, currentFolder.name);
            }
            
            return const Text('My Files');
          },
        ),
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          // View toggle button
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
          // Sort button
          PopupMenuButton<String>(
            onSelected: (value) {
              context.read<FileProvider>().setSortBy(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'name',
                child: ListTile(
                  leading: Icon(Icons.sort_by_alpha),
                  title: Text('Sort by Name'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'date',
                child: ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text('Sort by Date'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'size',
                child: ListTile(
                  leading: Icon(Icons.storage),
                  title: Text('Sort by Size'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar (if search is active)
          Consumer<FileProvider>(
            builder: (context, fileProvider, child) {
              if (fileProvider.searchQuery.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search files...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          fileProvider.clearSearch();
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      fileProvider.setSearchQuery(value);
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Files List
          Expanded(
            child: Consumer<FileProvider>(
              builder: (context, fileProvider, child) {
                if (fileProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (fileProvider.error != null) {
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
                          'Error: ${fileProvider.error}',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => fileProvider.initialize(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (fileProvider.items.isEmpty) {
                  return _buildEmptyState();
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    await fileProvider.loadFiles();
                    await fileProvider.loadFolders();
                  },
                  child: Column(
                    children: [
                      // Location Header
                      _buildLocationHeader(fileProvider),
                      
                      // Files List
                      Expanded(
                        child: fileProvider.isGridView
                            ? _buildGridView(fileProvider)
                            : _buildListView(fileProvider),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'files_fab',
        onPressed: () {
          _showAddFileBottomSheet();
        },
        child: const Icon(Icons.add),
      ),
      ),
    );
  }

  Widget _buildGridView(FileProvider fileProvider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: fileProvider.items.length,
      itemBuilder: (context, index) {
        final item = fileProvider.items[index];
        return _buildItem(item, fileProvider);
      },
    );
  }

  Widget _buildListView(FileProvider fileProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fileProvider.items.length,
      itemBuilder: (context, index) {
        final item = fileProvider.items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildItem(item, fileProvider),
        );
      },
    );
  }

  Widget _buildItem(dynamic item, FileProvider fileProvider) {
    if (item is AppFolder) {
      return FolderTile(
        folder: item,
        isGridView: fileProvider.isGridView,
        onTap: () => fileProvider.navigateToFolder(item.id),
        onLongPress: () => _showFolderActionSheet(item),
        onRename: () => _showRenameFolderDialog(item),
        onDelete: () => _showDeleteFolderDialog(item),
      );
    } else if (item is AppFile) {
      return FileTile(
        file: item,
        isGridView: fileProvider.isGridView,
        onTap: () => _openFile(item),
        onLongPress: () => _showFileActionSheet(item),
        onRename: () => _showRenameFileDialog(item),
        onMove: () => _showMoveFileDialog(item),
        onDelete: () => _showDeleteFileDialog(item),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return Consumer<FileProvider>(
      builder: (context, fileProvider, child) {
        final isEmptyFolder = fileProvider.currentFolderId != null;
        
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isEmptyFolder ? Icons.folder_open : Icons.folder_outlined,
                  size: 80,
                  color: Theme.of(context).disabledColor.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  isEmptyFolder ? 'Empty Folder' : 'No files yet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).disabledColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isEmptyFolder 
                    ? 'This folder is empty.\nAdd files to it by importing them.'
                    : 'Import some files or create a folder to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).disabledColor.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Files'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onChanged: (value) {
            context.read<FileProvider>().setSearchQuery(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              context.read<FileProvider>().clearSearch();
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showAddFileBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => AddFileBottomSheet(
        onImportFiles: () {
          Navigator.of(context).pop();
          context.read<FileProvider>().importMultipleFiles();
        },
        onCreateFolder: () {
          Navigator.of(context).pop();
          _showCreateFolderDialog();
        },
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
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<FileProvider>().createFolder(controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openFile(AppFile file) async {
    final fileProvider = context.read<FileProvider>();
    
    // If searching and the file is in a folder, navigate to that folder first
    if (file.parentFolderId != null && fileProvider.searchQuery.isNotEmpty) {
      // Try to close search dialog if it's open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Clear search query
      fileProvider.clearSearch();
      
      // Navigate to the file's folder
      await fileProvider.navigateToFolder(file.parentFolderId!);
    }
    
    // Open the file viewer
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FileViewerScreen(file: file),
        ),
      );
    }
  }

  void _showFileActionSheet(AppFile file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFileActionSheet(file),
    );
  }

  void _showFolderActionSheet(AppFolder folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFolderActionSheet(folder),
    );
  }

  Widget _buildFileActionSheet(AppFile file) {
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
              _showRenameFileDialog(file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.move_to_inbox),
            title: const Text('Move'),
            onTap: () {
              Navigator.pop(context);
              _showMoveFileDialog(file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteFileDialog(file);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFolderActionSheet(AppFolder folder) {
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
              _showRenameFolderDialog(folder);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteFolderDialog(folder);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameFileDialog(AppFile file) {
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
              if (controller.text.trim().isNotEmpty) {
                context.read<FileProvider>().renameFile(file.id, controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showRenameFolderDialog(AppFolder folder) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
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
              if (controller.text.trim().isNotEmpty) {
                context.read<FileProvider>().renameFolder(folder.id, controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showMoveFileDialog(AppFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move "${file.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select destination folder:'),
            const SizedBox(height: 16),
            Consumer<FileProvider>(
              builder: (context, fileProvider, child) {
                return FutureBuilder<List<AppFolder>>(
                  future: fileProvider.getFolders(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    
                    final folders = snapshot.data ?? [];
                    
                    return Column(
                      children: [
                        // Root folder option
                        ListTile(
                          leading: const Icon(Icons.folder),
                          title: const Text('Root Folder'),
                          onTap: () {
                            Navigator.of(context).pop();
                            context.read<FileProvider>().moveFileToFolder(file.id, null);
                          },
                        ),
                        // Other folders
                        ...folders.map((folder) => ListTile(
                          leading: const Icon(Icons.folder),
                          title: Text(folder.name),
                          onTap: () {
                            Navigator.of(context).pop();
                            context.read<FileProvider>().moveFileToFolder(file.id, folder.id);
                          },
                        )),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFileDialog(AppFile file) {
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
              context.read<FileProvider>().deleteFile(file.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderDialog(AppFolder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Are you sure you want to delete "${folder.name}"? Files in this folder will be moved to the root folder.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<FileProvider>().deleteFolder(folder.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context, String folderName) {
    return Row(
      children: [
        const Icon(Icons.folder, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            folderName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationHeader(FileProvider fileProvider) {
    // Count folders (in root folder)
    final folderCount = fileProvider.folders.length;
    
    // Count files based on current location
    final fileCount = fileProvider.files.where((f) =>
      fileProvider.currentFolderId == null ?
      f.parentFolderId == null :
      f.parentFolderId == fileProvider.currentFolderId
    ).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileProvider.currentFolderId == null 
                ? 'Root Folder' 
                : 'Inside Folder',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Text(
            '$folderCount folders • $fileCount files',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}



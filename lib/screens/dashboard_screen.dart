import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uniflow/providers/app_provider.dart';
import 'package:uniflow/providers/file_provider.dart';
import 'package:uniflow/providers/note_provider.dart';
import 'package:uniflow/widgets/file_card.dart';
import 'package:uniflow/widgets/note_card.dart';
import 'package:uniflow/widgets/storage_summary_card.dart';
import 'package:uniflow/widgets/motivational_quote_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileProvider>().loadFiles();
      context.read<NoteProvider>().loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<FileProvider>().loadFiles();
              context.read<NoteProvider>().loadNotes();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<FileProvider>().loadFiles();
          await context.read<NoteProvider>().loadNotes();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Motivational Quote
              const MotivationalQuoteCard(),
              const SizedBox(height: 24),
              
              // Storage Summary
              const StorageSummaryCard(),
              const SizedBox(height: 24),
              
              // Recent Files
              _buildSectionHeader('Recent Files', Icons.folder_outlined),
              const SizedBox(height: 12),
              Consumer<FileProvider>(
                builder: (context, fileProvider, child) {
                  if (fileProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final recentFiles = fileProvider.recentFiles;
                  if (recentFiles.isEmpty) {
                    return _buildEmptyState(
                      'No files yet',
                      'Import some files to get started',
                      Icons.folder_open,
                    );
                  }
                  
                  return SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recentFiles.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: FileCard(
                            file: recentFiles[index],
                            isCompact: true,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Recent Notes
              _buildSectionHeader('Recent Notes', Icons.note_outlined),
              const SizedBox(height: 12),
              Consumer<NoteProvider>(
                builder: (context, noteProvider, child) {
                  if (noteProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final recentNotes = noteProvider.recentNotes;
                  if (recentNotes.isEmpty) {
                    return _buildEmptyState(
                      'No notes yet',
                      'Create your first note to get started',
                      Icons.note_add,
                    );
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentNotes.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NoteCard(
                          note: recentNotes[index],
                          isCompact: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'new_note',
            onPressed: () {
              context.read<NoteProvider>().createNote();
              context.read<AppProvider>().setCurrentIndex(2); // Switch to Notes tab
            },
            child: const Icon(Icons.note_add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'new_file',
            onPressed: () {
              context.read<FileProvider>().importFile();
            },
            child: const Icon(Icons.file_upload),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


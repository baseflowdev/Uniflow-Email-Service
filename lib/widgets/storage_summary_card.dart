import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uniflow/providers/file_provider.dart';

class StorageSummaryCard extends StatelessWidget {
  const StorageSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FileProvider>(
      builder: (context, fileProvider, child) {
        final totalFiles = fileProvider.allFiles.length;
        final totalSize = fileProvider.allFiles
            .fold<int>(0, (sum, file) => sum + file.size);
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.storage,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Storage Summary',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Files',
                        totalFiles.toString(),
                        Icons.folder,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Size',
                        _formatBytes(totalSize),
                        Icons.data_usage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _getStorageUsage(totalSize),
                  backgroundColor: Theme.of(context).dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_getStorageUsage(totalSize) * 100}% of storage used',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  double _getStorageUsage(int bytes) {
    // Assuming 1GB total storage for demo purposes
    const maxStorage = 1024 * 1024 * 1024; // 1GB
    return (bytes / maxStorage).clamp(0.0, 1.0);
  }
}


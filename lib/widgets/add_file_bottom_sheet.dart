import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AddFileBottomSheet extends StatelessWidget {
  final VoidCallback onImportFiles;
  final VoidCallback onCreateFolder;

  const AddFileBottomSheet({
    super.key,
    required this.onImportFiles,
    required this.onCreateFolder,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Add New Item',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Import Files option
            _buildOption(
              context: context,
              icon: Icons.upload_file,
              title: 'Import Files',
              subtitle: 'Import one or more files',
              color: AppColors.primary,
              onTap: onImportFiles,
            ),
            
            const SizedBox(height: 12),
            
            // Create Folder option
            _buildOption(
              context: context,
              icon: Icons.create_new_folder,
              title: 'Create Folder',
              subtitle: 'Organize your files in folders',
              color: AppColors.accent,
              onTap: onCreateFolder,
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
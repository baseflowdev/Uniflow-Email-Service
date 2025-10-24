import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uniflow/providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final settings = settingsProvider.settings;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Theme Section
              _buildSectionHeader('Appearance'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Switch between light and dark theme'),
                      value: settings.isDarkMode,
                      onChanged: (value) {
                        settingsProvider.toggleDarkMode();
                      },
                    ),
                    ListTile(
                      title: const Text('Primary Color'),
                      subtitle: Text(settings.primaryColor),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showColorPicker(settings.primaryColor, (color) {
                          settingsProvider.updatePrimaryColor(color);
                        });
                      },
                    ),
                    ListTile(
                      title: const Text('Secondary Color'),
                      subtitle: Text(settings.secondaryColor),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showColorPicker(settings.secondaryColor, (color) {
                          settingsProvider.updateSecondaryColor(color);
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // File Management Section
              _buildSectionHeader('File Management'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Show File Preview'),
                      subtitle: const Text('Show file previews in the file list'),
                      value: settings.showFilePreview,
                      onChanged: (value) {
                        settingsProvider.toggleFilePreview();
                      },
                    ),
                    ListTile(
                      title: const Text('Default View Mode'),
                      subtitle: Text(settings.defaultViewMode == 'list' ? 'List View' : 'Grid View'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showViewModeDialog(settings.defaultViewMode, (mode) {
                          settingsProvider.updateDefaultViewMode(mode);
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Auto-save Section
              _buildSectionHeader('Auto-save'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Auto-save'),
                      subtitle: const Text('Automatically save changes'),
                      value: settings.autoSave,
                      onChanged: (value) {
                        settingsProvider.toggleAutoSave();
                      },
                    ),
                    if (settings.autoSave)
                      ListTile(
                        title: const Text('Auto-save Interval'),
                        subtitle: Text('${settings.autoSaveInterval} seconds'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _showIntervalDialog(settings.autoSaveInterval, (interval) {
                            settingsProvider.updateAutoSaveInterval(interval);
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Notifications Section
              _buildSectionHeader('Notifications'),
              Card(
                child: SwitchListTile(
                  title: const Text('Enable Notifications'),
                  subtitle: const Text('Receive notifications for important updates'),
                  value: settings.enableNotifications,
                  onChanged: (value) {
                    settingsProvider.toggleNotifications();
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // Data Management Section
              _buildSectionHeader('Data Management'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Storage Usage'),
                      subtitle: const Text('View storage usage and manage files'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showStorageDialog();
                      },
                    ),
                    ListTile(
                      title: const Text('Clear All Data'),
                      subtitle: const Text('Delete all files and notes'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showClearDataDialog();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // App Info Section
              _buildSectionHeader('App Information'),
              Card(
                child: Column(
                  children: [
                    const ListTile(
                      title: Text('Version'),
                      subtitle: Text('1.0.0'),
                    ),
                    const ListTile(
                      title: Text('Build Number'),
                      subtitle: Text('1'),
                    ),
                    ListTile(
                      title: const Text('Last Backup'),
                      subtitle: Text(_formatDate(settings.lastBackup)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showColorPicker(String currentColor, Function(String) onColorChanged) {
    final colors = [
      '#3D5AFE', '#00BFA5', '#FF6B6B', '#4ECDC4', '#45B7D1',
      '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F'
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Color'),
        content: SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              final isSelected = color == currentColor;
              return GestureDetector(
                onTap: () {
                  onColorChanged(color);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.substring(1), radix: 16) + 0xFF000000),
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showViewModeDialog(String currentMode, Function(String) onModeChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default View Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('List View'),
              value: 'list',
              groupValue: currentMode,
              onChanged: (value) {
                onModeChanged(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Grid View'),
              value: 'grid',
              groupValue: currentMode,
              onChanged: (value) {
                onModeChanged(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showIntervalDialog(int currentInterval, Function(int) onIntervalChanged) {
    final intervals = [10, 30, 60, 120, 300]; // seconds
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-save Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((interval) {
            return RadioListTile<int>(
              title: Text('${interval} seconds'),
              value: interval,
              groupValue: currentInterval,
              onChanged: (value) {
                onIntervalChanged(value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showStorageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Usage'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Files'),
              trailing: Text('0 MB'),
            ),
            ListTile(
              title: Text('Notes'),
              trailing: Text('0 MB'),
            ),
            ListTile(
              title: Text('Total'),
              trailing: Text('0 MB'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all files and notes. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<SettingsProvider>().clearAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}


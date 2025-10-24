import 'package:flutter/material.dart';
import 'package:uniflow/models/file_model.dart';
import 'package:uniflow/widgets/file_card.dart';

class FileListView extends StatelessWidget {
  final List<FileModel> files;
  final Function(FileModel) onFileTap;
  final Function(FileModel) onFileLongPress;

  const FileListView({
    super.key,
    required this.files,
    required this.onFileTap,
    required this.onFileLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FileCard(
            file: file,
            onTap: () => onFileTap(file),
            onLongPress: () => onFileLongPress(file),
          ),
        );
      },
    );
  }
}


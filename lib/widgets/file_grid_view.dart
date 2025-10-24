import 'package:flutter/material.dart';
import 'package:uniflow/models/file_model.dart';
import 'package:uniflow/widgets/file_card.dart';

class FileGridView extends StatelessWidget {
  final List<FileModel> files;
  final Function(FileModel) onFileTap;
  final Function(FileModel) onFileLongPress;

  const FileGridView({
    super.key,
    required this.files,
    required this.onFileTap,
    required this.onFileLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return FileCard(
          file: file,
          onTap: () => onFileTap(file),
          onLongPress: () => onFileLongPress(file),
        );
      },
    );
  }
}


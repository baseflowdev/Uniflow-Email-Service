import 'package:flutter_test/flutter_test.dart';
import 'package:uniflow/models/app_file.dart';
import 'package:uniflow/models/app_folder.dart';

void main() {
  group('File Management Models', () {
    test('AppFile model should work correctly', () {
      final file = AppFile(
        id: 'test-id',
        name: 'test.pdf',
        path: '/test/path/test.pdf',
        type: 'pdf',
        size: 1024,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      expect(file.id, 'test-id');
      expect(file.name, 'test.pdf');
      expect(file.isPdf, true);
      expect(file.isImage, false);
      expect(file.isDocument, false);
      expect(file.isFolder, false);
      expect(file.formattedSize, '1.0 KB');
    });

    test('AppFolder model should work correctly', () {
      final folder = AppFolder(
        id: 'folder-id',
        name: 'Test Folder',
        createdAt: DateTime.now(),
      );

      expect(folder.id, 'folder-id');
      expect(folder.name, 'Test Folder');
      expect(folder.isFolder, true);
      expect(folder.isPdf, false);
      expect(folder.isImage, false);
      expect(folder.isDocument, false);
    });

    test('AppFile copyWith should work correctly', () {
      final originalFile = AppFile(
        id: 'test-id',
        name: 'test.pdf',
        path: '/test/path/test.pdf',
        type: 'pdf',
        size: 1024,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      final updatedFile = originalFile.copyWith(name: 'updated.pdf');

      expect(updatedFile.id, originalFile.id);
      expect(updatedFile.name, 'updated.pdf');
      expect(updatedFile.path, originalFile.path);
      expect(updatedFile.type, originalFile.type);
      expect(updatedFile.size, originalFile.size);
    });

    test('AppFolder copyWith should work correctly', () {
      final originalFolder = AppFolder(
        id: 'folder-id',
        name: 'Test Folder',
        createdAt: DateTime.now(),
      );

      final updatedFolder = originalFolder.copyWith(name: 'Updated Folder');

      expect(updatedFolder.id, originalFolder.id);
      expect(updatedFolder.name, 'Updated Folder');
      expect(updatedFolder.createdAt, originalFolder.createdAt);
    });
  });
}

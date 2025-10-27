import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uniflow/models/app_file.dart';
import 'package:uniflow/models/app_folder.dart';
import 'dart:io';

void main() {
  group('Hive Models Tests', () {
    late Directory tempDir;

    setUpAll(() async {
      // Initialize Hive in test environment
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
      
      // Register adapters
      Hive.registerAdapter(AppFileAdapter());
      Hive.registerAdapter(AppFolderAdapter());
    });

    tearDownAll(() async {
      // Clean up
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('AppFile persistence test', () async {
      // Open files box
      final filesBox = await Hive.openBox<AppFile>('files');
      
      // Create a sample AppFile
      final testFile = AppFile(
        id: 'test_file_1',
        name: 'test_document.pdf',
        path: '/test/path/test_document.pdf',
        type: 'pdf',
        size: 1024,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      // Write to Hive
      await filesBox.put(testFile.id, testFile);
      
      // Read back from Hive
      final retrievedFile = filesBox.get(testFile.id);
      
      // Assert equality
      expect(retrievedFile, isNotNull);
      expect(retrievedFile!.id, equals(testFile.id));
      expect(retrievedFile.name, equals(testFile.name));
      expect(retrievedFile.path, equals(testFile.path));
      expect(retrievedFile.type, equals(testFile.type));
      expect(retrievedFile.size, equals(testFile.size));
      expect(retrievedFile.parentFolderId, equals(testFile.parentFolderId));
      
      // Test helper methods
      expect(retrievedFile.isPdf, isTrue);
      expect(retrievedFile.isImage, isFalse);
      expect(retrievedFile.isDocument, isFalse);
      expect(retrievedFile.isFolder, isFalse);
      expect(retrievedFile.formattedSize, equals('1.0 KB'));
      expect(retrievedFile.iconName, equals('pdf'));
      
      await filesBox.close();
    });

    test('AppFolder persistence test', () async {
      // Open folders box
      final foldersBox = await Hive.openBox<AppFolder>('folders');
      
      // Create a sample AppFolder
      final testFolder = AppFolder(
        id: 'test_folder_1',
        name: 'Test Folder',
        createdAt: DateTime.now(),
      );

      // Write to Hive
      await foldersBox.put(testFolder.id, testFolder);
      
      // Read back from Hive
      final retrievedFolder = foldersBox.get(testFolder.id);
      
      // Assert equality
      expect(retrievedFolder, isNotNull);
      expect(retrievedFolder!.id, equals(testFolder.id));
      expect(retrievedFolder.name, equals(testFolder.name));
      expect(retrievedFolder.createdAt, equals(testFolder.createdAt));
      
      // Test helper methods
      expect(retrievedFolder.isFolder, isTrue);
      expect(retrievedFolder.isPdf, isFalse);
      expect(retrievedFolder.isImage, isFalse);
      expect(retrievedFolder.isDocument, isFalse);
      expect(retrievedFolder.iconName, equals('folder'));
      
      await foldersBox.close();
    });

    test('AppFile copyWith method test', () {
      final originalFile = AppFile(
        id: 'original_id',
        name: 'original_name.pdf',
        path: '/original/path.pdf',
        type: 'pdf',
        size: 2048,
        dateAdded: DateTime(2023, 1, 1),
        parentFolderId: 'folder_1',
      );

      final copiedFile = originalFile.copyWith(
        name: 'new_name.pdf',
        size: 4096,
      );

      expect(copiedFile.id, equals(originalFile.id));
      expect(copiedFile.name, equals('new_name.pdf'));
      expect(copiedFile.path, equals(originalFile.path));
      expect(copiedFile.type, equals(originalFile.type));
      expect(copiedFile.size, equals(4096));
      expect(copiedFile.dateAdded, equals(originalFile.dateAdded));
      expect(copiedFile.parentFolderId, equals(originalFile.parentFolderId));
    });

    test('AppFolder copyWith method test', () {
      final originalFolder = AppFolder(
        id: 'original_folder_id',
        name: 'Original Folder',
        createdAt: DateTime(2023, 1, 1),
      );

      final copiedFolder = originalFolder.copyWith(
        name: 'New Folder Name',
      );

      expect(copiedFolder.id, equals(originalFolder.id));
      expect(copiedFolder.name, equals('New Folder Name'));
      expect(copiedFolder.createdAt, equals(originalFolder.createdAt));
    });

    test('AppFile equality test', () {
      final file1 = AppFile(
        id: 'same_id',
        name: 'file1.pdf',
        path: '/path1.pdf',
        type: 'pdf',
        size: 1024,
        dateAdded: DateTime.now(),
      );

      final file2 = AppFile(
        id: 'same_id',
        name: 'file2.pdf',
        path: '/path2.pdf',
        type: 'doc',
        size: 2048,
        dateAdded: DateTime.now(),
      );

      final file3 = AppFile(
        id: 'different_id',
        name: 'file1.pdf',
        path: '/path1.pdf',
        type: 'pdf',
        size: 1024,
        dateAdded: DateTime.now(),
      );

      expect(file1, equals(file2)); // Same ID
      expect(file1, isNot(equals(file3))); // Different ID
    });

    test('AppFolder equality test', () {
      final folder1 = AppFolder(
        id: 'same_id',
        name: 'Folder 1',
        createdAt: DateTime.now(),
      );

      final folder2 = AppFolder(
        id: 'same_id',
        name: 'Folder 2',
        createdAt: DateTime.now(),
      );

      final folder3 = AppFolder(
        id: 'different_id',
        name: 'Folder 1',
        createdAt: DateTime.now(),
      );

      expect(folder1, equals(folder2)); // Same ID
      expect(folder1, isNot(equals(folder3))); // Different ID
    });
  });
}






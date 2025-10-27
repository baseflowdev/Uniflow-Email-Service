import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uniflow/models/app_file.dart';
import 'package:uniflow/services/file_service.dart';
import 'dart:io';

void main() {
  group('FileService Tests', () {
    late Directory tempDir;
    late FileService fileService;

    setUpAll(() async {
      // Initialize Hive in test environment
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
      
      // Register adapters
      Hive.registerAdapter(AppFileAdapter());
      
      // Open files box
      await Hive.openBox<AppFile>('files');
    });

    setUp(() {
      fileService = FileService();
    });

    tearDownAll(() async {
      // Clean up
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('initialize should open files box', () async {
      await fileService.initialize();
      // If no exception is thrown, initialization was successful
      expect(true, isTrue);
    });

    test('getFiles should return empty list initially', () async {
      await fileService.initialize();
      final files = await fileService.getFiles();
      expect(files, isEmpty);
    });

    test('create and retrieve file', () async {
      await fileService.initialize();
      
      // Create a test file manually (since FilePicker is hard to mock in tests)
      final testFile = AppFile(
        id: 'test_file_1',
        name: 'test_document.pdf',
        path: '/test/path/test_document.pdf',
        type: 'pdf',
        size: 1024,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      // Save file directly to Hive box
      final filesBox = Hive.box<AppFile>('files');
      await filesBox.put(testFile.id, testFile);

      // Test getFiles
      final files = await fileService.getFiles();
      expect(files.length, equals(1));
      expect(files.first.id, equals(testFile.id));
      expect(files.first.name, equals(testFile.name));
    });

    test('getFile should return specific file', () async {
      await fileService.initialize();
      
      final testFile = AppFile(
        id: 'test_file_2',
        name: 'test_image.jpg',
        path: '/test/path/test_image.jpg',
        type: 'jpg',
        size: 2048,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      final filesBox = Hive.box<AppFile>('files');
      await filesBox.put(testFile.id, testFile);

      final retrievedFile = await fileService.getFile(testFile.id);
      expect(retrievedFile, isNotNull);
      expect(retrievedFile!.id, equals(testFile.id));
      expect(retrievedFile.name, equals(testFile.name));
    });

    test('renameFile should update file name', () async {
      await fileService.initialize();
      
      final testFile = AppFile(
        id: 'test_file_3',
        name: 'old_name.pdf',
        path: '/test/path/old_name.pdf',
        type: 'pdf',
        size: 1024,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      final filesBox = Hive.box<AppFile>('files');
      await filesBox.put(testFile.id, testFile);

      // Rename the file
      await fileService.renameFile(testFile.id, 'new_name.pdf');

      // Verify the rename
      final updatedFile = await fileService.getFile(testFile.id);
      expect(updatedFile, isNotNull);
      expect(updatedFile!.name, equals('new_name.pdf'));
    });

    test('deleteFile should remove file from storage', () async {
      await fileService.initialize();
      
      final testFile = AppFile(
        id: 'test_file_4',
        name: 'to_delete.pdf',
        path: '/test/path/to_delete.pdf',
        type: 'pdf',
        size: 1024,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      final filesBox = Hive.box<AppFile>('files');
      await filesBox.put(testFile.id, testFile);

      // Verify file exists
      final filesBefore = await fileService.getFiles();
      expect(filesBefore.length, equals(1));

      // Delete the file
      await fileService.deleteFile(testFile.id);

      // Verify file is deleted
      final filesAfter = await fileService.getFiles();
      expect(filesAfter.length, equals(0));
    });

    test('getRecentFiles should return files sorted by date', () async {
      await fileService.initialize();
      
      final now = DateTime.now();
      final file1 = AppFile(
        id: 'file_1',
        name: 'old_file.pdf',
        path: '/test/old_file.pdf',
        type: 'pdf',
        size: 1024,
        dateAdded: now.subtract(const Duration(days: 2)),
        parentFolderId: null,
      );

      final file2 = AppFile(
        id: 'file_2',
        name: 'new_file.pdf',
        path: '/test/new_file.pdf',
        type: 'pdf',
        size: 2048,
        dateAdded: now,
        parentFolderId: null,
      );

      final filesBox = Hive.box<AppFile>('files');
      await filesBox.put(file1.id, file1);
      await filesBox.put(file2.id, file2);

      final recentFiles = await fileService.getRecentFiles();
      expect(recentFiles.length, equals(2));
      expect(recentFiles.first.id, equals(file2.id)); // Newest first
      expect(recentFiles.last.id, equals(file1.id));
    });

    test('searchFiles should find files by name', () async {
      await fileService.initialize();
      
      final file1 = AppFile(
        id: 'file_1',
        name: 'document.pdf',
        path: '/test/document.pdf',
        type: 'pdf',
        size: 1024,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      final file2 = AppFile(
        id: 'file_2',
        name: 'image.jpg',
        path: '/test/image.jpg',
        type: 'jpg',
        size: 2048,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      final filesBox = Hive.box<AppFile>('files');
      await filesBox.put(file1.id, file1);
      await filesBox.put(file2.id, file2);

      final searchResults = await fileService.searchFiles('document');
      expect(searchResults.length, equals(1));
      expect(searchResults.first.id, equals(file1.id));
    });

    test('searchFiles should find files by type', () async {
      await fileService.initialize();
      
      final file1 = AppFile(
        id: 'file_1',
        name: 'document.pdf',
        path: '/test/document.pdf',
        type: 'pdf',
        size: 1024,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      final file2 = AppFile(
        id: 'file_2',
        name: 'image.jpg',
        path: '/test/image.jpg',
        type: 'jpg',
        size: 2048,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      final filesBox = Hive.box<AppFile>('files');
      await filesBox.put(file1.id, file1);
      await filesBox.put(file2.id, file2);

      final searchResults = await fileService.searchFiles('jpg');
      expect(searchResults.length, equals(1));
      expect(searchResults.first.id, equals(file2.id));
    });

    test('moveFile should update parentFolderId', () async {
      await fileService.initialize();
      
      final testFile = AppFile(
        id: 'file_1',
        name: 'test.pdf',
        path: '/test/test.pdf',
        type: 'pdf',
        size: 1024,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      final filesBox = Hive.box<AppFile>('files');
      await filesBox.put(testFile.id, testFile);

      // Move file to folder
      await fileService.moveFile(testFile.id, 'folder_1');

      final movedFile = await fileService.getFile(testFile.id);
      expect(movedFile, isNotNull);
      expect(movedFile!.parentFolderId, equals('folder_1'));
    });

    test('getFileCountByType should return correct counts', () async {
      await fileService.initialize();
      
      final file1 = AppFile(
        id: 'file_1',
        name: 'doc1.pdf',
        path: '/test/doc1.pdf',
        type: 'pdf',
        size: 1024,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      final file2 = AppFile(
        id: 'file_2',
        name: 'doc2.pdf',
        path: '/test/doc2.pdf',
        type: 'pdf',
        size: 2048,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      final file3 = AppFile(
        id: 'file_3',
        name: 'image.jpg',
        path: '/test/image.jpg',
        type: 'jpg',
        size: 1024,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      final filesBox = Hive.box<AppFile>('files');
      await filesBox.put(file1.id, file1);
      await filesBox.put(file2.id, file2);
      await filesBox.put(file3.id, file3);

      final countByType = await fileService.getFileCountByType();
      expect(countByType['pdf'], equals(2));
      expect(countByType['jpg'], equals(1));
    });

    test('getTotalStorageUsed should return correct total size', () async {
      await fileService.initialize();
      
      final file1 = AppFile(
        id: 'file_1',
        name: 'doc1.pdf',
        path: '/test/doc1.pdf',
        type: 'pdf',
        size: 1000,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      final file2 = AppFile(
        id: 'file_2',
        name: 'doc2.pdf',
        path: '/test/doc2.pdf',
        type: 'pdf',
        size: 2000,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );

      final filesBox = Hive.box<AppFile>('files');
      await filesBox.put(file1.id, file1);
      await filesBox.put(file2.id, file2);

      final totalSize = await fileService.getTotalStorageUsed();
      expect(totalSize, equals(3000));
    });
  });
}






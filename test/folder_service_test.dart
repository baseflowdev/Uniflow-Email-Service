import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uniflow/models/app_folder.dart';
import 'package:uniflow/models/app_file.dart';
import 'package:uniflow/services/folder_service.dart';
import 'dart:io';

void main() {
  group('FolderService Tests', () {
    late Directory tempDir;
    late FolderService folderService;

    setUpAll(() async {
      // Initialize Hive in test environment
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
      
      // Register adapters
      Hive.registerAdapter(AppFolderAdapter());
      Hive.registerAdapter(AppFileAdapter());
      
      // Open boxes
      await Hive.openBox<AppFolder>('folders');
      await Hive.openBox<AppFile>('files');
    });

    setUp(() {
      folderService = FolderService();
    });

    tearDownAll(() async {
      // Clean up
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('initialize should open folders and files boxes', () async {
      await folderService.initialize();
      // If no exception is thrown, initialization was successful
      expect(true, isTrue);
    });

    test('createFolder should create and return new folder', () async {
      await folderService.initialize();
      
      final folder = await folderService.createFolder('Test Folder');
      
      expect(folder.name, equals('Test Folder'));
      expect(folder.id, isNotEmpty);
      expect(folder.createdAt, isA<DateTime>());
    });

    test('getFolders should return created folders', () async {
      await folderService.initialize();
      
      // Create test folders
      final folder1 = await folderService.createFolder('Folder 1');
      final folder2 = await folderService.createFolder('Folder 2');
      
      final folders = await folderService.getFolders();
      expect(folders.length, equals(2));
      
      // Should be sorted by creation date (newest first)
      expect(folders.first.name, equals('Folder 2'));
      expect(folders.last.name, equals('Folder 1'));
    });

    test('getFolder should return specific folder', () async {
      await folderService.initialize();
      
      final createdFolder = await folderService.createFolder('Specific Folder');
      final retrievedFolder = await folderService.getFolder(createdFolder.id);
      
      expect(retrievedFolder, isNotNull);
      expect(retrievedFolder!.id, equals(createdFolder.id));
      expect(retrievedFolder.name, equals(createdFolder.name));
    });

    test('renameFolder should update folder name', () async {
      await folderService.initialize();
      
      final folder = await folderService.createFolder('Old Name');
      await folderService.renameFolder(folder.id, 'New Name');
      
      final updatedFolder = await folderService.getFolder(folder.id);
      expect(updatedFolder, isNotNull);
      expect(updatedFolder!.name, equals('New Name'));
    });

    test('deleteFolder should remove folder and move files to root', () async {
      await folderService.initialize();
      
      // Create a folder
      final folder = await folderService.createFolder('Folder to Delete');
      
      // Create a file in the folder
      final filesBox = Hive.box<AppFile>('files');
      final testFile = AppFile(
        id: 'test_file',
        name: 'test.pdf',
        path: '/test/test.pdf',
        type: 'pdf',
        size: 1024,
        dateAdded: DateTime.now(),
        parentFolderId: folder.id,
      );
      await filesBox.put(testFile.id, testFile);
      
      // Verify folder exists
      final foldersBefore = await folderService.getFolders();
      expect(foldersBefore.length, equals(1));
      
      // Verify file is in folder
      final filesInFolder = await folderService.getFilesInFolder(folder.id);
      expect(filesInFolder.length, equals(1));
      
      // Delete the folder
      await folderService.deleteFolder(folder.id);
      
      // Verify folder is deleted
      final foldersAfter = await folderService.getFolders();
      expect(foldersAfter.length, equals(0));
      
      // Verify file is moved to root (parentFolderId = null)
      final updatedFile = filesBox.get(testFile.id);
      expect(updatedFile, isNotNull);
      expect(updatedFile!.parentFolderId, isNull);
    });

    test('folderNameExists should detect existing names', () async {
      await folderService.initialize();
      
      await folderService.createFolder('Existing Folder');
      
      final exists = await folderService.folderNameExists('Existing Folder');
      expect(exists, isTrue);
      
      final notExists = await folderService.folderNameExists('Non-existing Folder');
      expect(notExists, isFalse);
    });

    test('folderNameExists should exclude specified folder ID', () async {
      await folderService.initialize();
      
      final folder = await folderService.createFolder('Test Folder');
      
      // Should return false when excluding the same folder
      final exists = await folderService.folderNameExists('Test Folder', excludeId: folder.id);
      expect(exists, isFalse);
      
      // Should return true when excluding different folder
      final exists2 = await folderService.folderNameExists('Test Folder', excludeId: 'different_id');
      expect(exists2, isTrue);
    });

    test('getFilesInFolder should return files in specific folder', () async {
      await folderService.initialize();
      
      final folder = await folderService.createFolder('Test Folder');
      
      // Create files in different locations
      final filesBox = Hive.box<AppFile>('files');
      final fileInFolder = AppFile(
        id: 'file_in_folder',
        name: 'in_folder.pdf',
        path: '/test/in_folder.pdf',
        type: 'pdf',
        size: 1024,
        dateAdded: DateTime.now(),
        parentFolderId: folder.id,
      );
      
      final fileInRoot = AppFile(
        id: 'file_in_root',
        name: 'in_root.pdf',
        path: '/test/in_root.pdf',
        type: 'pdf',
        size: 1024,
        dateAdded: DateTime.now(),
        parentFolderId: null,
      );
      
      await filesBox.put(fileInFolder.id, fileInFolder);
      await filesBox.put(fileInRoot.id, fileInRoot);
      
      final filesInFolder = await folderService.getFilesInFolder(folder.id);
      expect(filesInFolder.length, equals(1));
      expect(filesInFolder.first.id, equals(fileInFolder.id));
    });

    test('getFolderStats should return correct statistics', () async {
      await folderService.initialize();
      
      final folder = await folderService.createFolder('Stats Folder');
      
      // Create files in the folder
      final filesBox = Hive.box<AppFile>('files');
      final file1 = AppFile(
        id: 'file1',
        name: 'file1.pdf',
        path: '/test/file1.pdf',
        type: 'pdf',
        size: 1000,
        dateAdded: DateTime.now(),
        parentFolderId: folder.id,
      );
      
      final file2 = AppFile(
        id: 'file2',
        name: 'file2.pdf',
        path: '/test/file2.pdf',
        type: 'pdf',
        size: 2000,
        dateAdded: DateTime.now(),
        parentFolderId: folder.id,
      );
      
      await filesBox.put(file1.id, file1);
      await filesBox.put(file2.id, file2);
      
      final stats = await folderService.getFolderStats(folder.id);
      expect(stats['folder'], equals(folder));
      expect(stats['fileCount'], equals(2));
      expect(stats['totalSize'], equals(3000));
      expect(stats['formattedSize'], equals('2.9 KB'));
    });

    test('searchFolders should find folders by name', () async {
      await folderService.initialize();
      
      await folderService.createFolder('Important Folder');
      await folderService.createFolder('Regular Folder');
      
      final searchResults = await folderService.searchFolders('Important');
      expect(searchResults.length, equals(1));
      expect(searchResults.first.name, equals('Important Folder'));
    });

    test('getRecentFolders should return folders sorted by date', () async {
      await folderService.initialize();
      
      // Create folders with slight time differences
      final folder1 = await folderService.createFolder('First Folder');
      await Future.delayed(const Duration(milliseconds: 10));
      final folder2 = await folderService.createFolder('Second Folder');
      
      final recentFolders = await folderService.getRecentFolders();
      expect(recentFolders.length, equals(2));
      expect(recentFolders.first.name, equals('Second Folder')); // Newest first
      expect(recentFolders.last.name, equals('First Folder'));
    });

    test('getFolderCount should return correct count', () async {
      await folderService.initialize();
      
      expect(await folderService.getFolderCount(), equals(0));
      
      await folderService.createFolder('Folder 1');
      expect(await folderService.getFolderCount(), equals(1));
      
      await folderService.createFolder('Folder 2');
      expect(await folderService.getFolderCount(), equals(2));
    });
  });
}






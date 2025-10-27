import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uniflow/models/app_file.dart';
import 'package:uniflow/models/app_folder.dart';
import 'package:uniflow/services/file_service.dart';
import 'package:uniflow/services/folder_service.dart';
import 'dart:io';

void main() {
  group('Offline Persistence Tests', () {
    late Directory tempDir;
    late FileService fileService;
    late FolderService folderService;

    setUpAll(() async {
      // Initialize Hive in test environment
      tempDir = await Directory.systemTemp.createTemp('hive_persistence_test_');
      Hive.init(tempDir.path);
      
      // Register adapters
      Hive.registerAdapter(AppFileAdapter());
      Hive.registerAdapter(AppFolderAdapter());
      
      // Open boxes
      await Hive.openBox<AppFile>('files');
      await Hive.openBox<AppFolder>('folders');
    });

    setUp(() {
      fileService = FileService();
      folderService = FolderService();
    });

    tearDownAll(() async {
      // Clean up
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('AppFile persistence test - write and read back', () async {
      await fileService.initialize();
      
      // Create sample files
      final files = [
        AppFile(
          id: 'file1',
          name: 'document1.pdf',
          path: '/test/document1.pdf',
          type: 'pdf',
          size: 1024,
          dateAdded: DateTime.now(),
          parentFolderId: null,
        ),
        AppFile(
          id: 'file2',
          name: 'image1.jpg',
          path: '/test/image1.jpg',
          type: 'jpg',
          size: 2048,
          dateAdded: DateTime.now(),
          parentFolderId: 'folder1',
        ),
        AppFile(
          id: 'file3',
          name: 'document2.pdf',
          path: '/test/document2.pdf',
          type: 'pdf',
          size: 3072,
          dateAdded: DateTime.now(),
          parentFolderId: null,
        ),
      ];

      // Write files to Hive
      final filesBox = Hive.box<AppFile>('files');
      for (final file in files) {
        await filesBox.put(file.id, file);
      }

      // Close Hive to simulate app restart
      await Hive.close();

      // Reopen Hive
      Hive.init(tempDir.path);
      Hive.registerAdapter(AppFileAdapter());
      await Hive.openBox<AppFile>('files');

      // Initialize service again
      final newFileService = FileService();
      await newFileService.initialize();

      // Read files back
      final retrievedFiles = await newFileService.getFiles();
      
      // Verify persistence
      expect(retrievedFiles.length, equals(3));
      
      // Verify each file
      for (final originalFile in files) {
        final retrievedFile = retrievedFiles.firstWhere(
          (f) => f.id == originalFile.id,
          orElse: () => throw Exception('File not found: ${originalFile.id}'),
        );
        
        expect(retrievedFile.id, equals(originalFile.id));
        expect(retrievedFile.name, equals(originalFile.name));
        expect(retrievedFile.path, equals(originalFile.path));
        expect(retrievedFile.type, equals(originalFile.type));
        expect(retrievedFile.size, equals(originalFile.size));
        expect(retrievedFile.parentFolderId, equals(originalFile.parentFolderId));
      }
    });

    test('AppFolder persistence test - write and read back', () async {
      await folderService.initialize();
      
      // Create sample folders
      final folders = [
        AppFolder(
          id: 'folder1',
          name: 'Documents',
          createdAt: DateTime.now(),
        ),
        AppFolder(
          id: 'folder2',
          name: 'Images',
          createdAt: DateTime.now(),
        ),
        AppFolder(
          id: 'folder3',
          name: 'Important Files',
          createdAt: DateTime.now(),
        ),
      ];

      // Write folders to Hive
      final foldersBox = Hive.box<AppFolder>('folders');
      for (final folder in folders) {
        await foldersBox.put(folder.id, folder);
      }

      // Close Hive to simulate app restart
      await Hive.close();

      // Reopen Hive
      Hive.init(tempDir.path);
      Hive.registerAdapter(AppFolderAdapter());
      await Hive.openBox<AppFolder>('folders');

      // Initialize service again
      final newFolderService = FolderService();
      await newFolderService.initialize();

      // Read folders back
      final retrievedFolders = await newFolderService.getFolders();
      
      // Verify persistence
      expect(retrievedFolders.length, equals(3));
      
      // Verify each folder
      for (final originalFolder in folders) {
        final retrievedFolder = retrievedFolders.firstWhere(
          (f) => f.id == originalFolder.id,
          orElse: () => throw Exception('Folder not found: ${originalFolder.id}'),
        );
        
        expect(retrievedFolder.id, equals(originalFolder.id));
        expect(retrievedFolder.name, equals(originalFolder.name));
        expect(retrievedFolder.createdAt, equals(originalFolder.createdAt));
      }
    });

    test('Mixed data persistence test - files and folders together', () async {
      // Create mixed data
      final files = [
        AppFile(
          id: 'file1',
          name: 'doc1.pdf',
          path: '/test/doc1.pdf',
          type: 'pdf',
          size: 1024,
          dateAdded: DateTime.now(),
          parentFolderId: 'folder1',
        ),
        AppFile(
          id: 'file2',
          name: 'doc2.pdf',
          path: '/test/doc2.pdf',
          type: 'pdf',
          size: 2048,
          dateAdded: DateTime.now(),
          parentFolderId: null,
        ),
      ];

      final folders = [
        AppFolder(
          id: 'folder1',
          name: 'My Documents',
          createdAt: DateTime.now(),
        ),
      ];

      // Write to Hive
      final filesBox = Hive.box<AppFile>('files');
      final foldersBox = Hive.box<AppFolder>('folders');
      
      for (final file in files) {
        await filesBox.put(file.id, file);
      }
      for (final folder in folders) {
        await foldersBox.put(folder.id, folder);
      }

      // Close Hive
      await Hive.close();

      // Reopen Hive
      Hive.init(tempDir.path);
      Hive.registerAdapter(AppFileAdapter());
      Hive.registerAdapter(AppFolderAdapter());
      await Hive.openBox<AppFile>('files');
      await Hive.openBox<AppFolder>('folders');

      // Initialize services
      final newFileService = FileService();
      final newFolderService = FolderService();
      await newFileService.initialize();
      await newFolderService.initialize();

      // Read data back
      final retrievedFiles = await newFileService.getFiles();
      final retrievedFolders = await newFolderService.getFolders();

      // Verify persistence
      expect(retrievedFiles.length, equals(2));
      expect(retrievedFolders.length, equals(1));

      // Verify file in folder
      final filesInFolder = await newFileService.getFiles(folderId: 'folder1');
      expect(filesInFolder.length, equals(1));
      expect(filesInFolder.first.id, equals('file1'));

      // Verify file in root
      final filesInRoot = await newFileService.getFiles(folderId: null);
      expect(filesInRoot.length, equals(1));
      expect(filesInRoot.first.id, equals('file2'));
    });

    test('Data integrity test - verify no data corruption', () async {
      // Create complex data
      final now = DateTime.now();
      final files = List.generate(10, (index) => AppFile(
        id: 'file$index',
        name: 'file$index.pdf',
        path: '/test/file$index.pdf',
        type: 'pdf',
        size: 1024 * (index + 1),
        dateAdded: now.add(Duration(minutes: index)),
        parentFolderId: index % 2 == 0 ? 'folder1' : null,
      ));

      final folders = List.generate(5, (index) => AppFolder(
        id: 'folder$index',
        name: 'Folder $index',
        createdAt: now.add(Duration(hours: index)),
      ));

      // Write to Hive
      final filesBox = Hive.box<AppFile>('files');
      final foldersBox = Hive.box<AppFolder>('folders');
      
      for (final file in files) {
        await filesBox.put(file.id, file);
      }
      for (final folder in folders) {
        await foldersBox.put(folder.id, folder);
      }

      // Close Hive
      await Hive.close();

      // Reopen Hive
      Hive.init(tempDir.path);
      Hive.registerAdapter(AppFileAdapter());
      Hive.registerAdapter(AppFolderAdapter());
      await Hive.openBox<AppFile>('files');
      await Hive.openBox<AppFolder>('folders');

      // Initialize services
      final newFileService = FileService();
      final newFolderService = FolderService();
      await newFileService.initialize();
      await newFolderService.initialize();

      // Read data back
      final retrievedFiles = await newFileService.getFiles();
      final retrievedFolders = await newFolderService.getFolders();

      // Verify no data corruption
      expect(retrievedFiles.length, equals(10));
      expect(retrievedFolders.length, equals(5));

      // Verify data integrity
      for (final originalFile in files) {
        final retrievedFile = retrievedFiles.firstWhere(
          (f) => f.id == originalFile.id,
          orElse: () => throw Exception('File not found: ${originalFile.id}'),
        );
        
        expect(retrievedFile.name, equals(originalFile.name));
        expect(retrievedFile.size, equals(originalFile.size));
        expect(retrievedFile.type, equals(originalFile.type));
        expect(retrievedFile.parentFolderId, equals(originalFile.parentFolderId));
      }

      for (final originalFolder in folders) {
        final retrievedFolder = retrievedFolders.firstWhere(
          (f) => f.id == originalFolder.id,
          orElse: () => throw Exception('Folder not found: ${originalFolder.id}'),
        );
        
        expect(retrievedFolder.name, equals(originalFolder.name));
        expect(retrievedFolder.createdAt, equals(originalFolder.createdAt));
      }
    });

    test('Empty data persistence test - verify empty state is maintained', () async {
      // Ensure boxes are empty
      final filesBox = Hive.box<AppFile>('files');
      final foldersBox = Hive.box<AppFolder>('folders');
      
      await filesBox.clear();
      await foldersBox.clear();

      // Close Hive
      await Hive.close();

      // Reopen Hive
      Hive.init(tempDir.path);
      Hive.registerAdapter(AppFileAdapter());
      Hive.registerAdapter(AppFolderAdapter());
      await Hive.openBox<AppFile>('files');
      await Hive.openBox<AppFolder>('folders');

      // Initialize services
      final newFileService = FileService();
      final newFolderService = FolderService();
      await newFileService.initialize();
      await newFolderService.initialize();

      // Read data back
      final retrievedFiles = await newFileService.getFiles();
      final retrievedFolders = await newFolderService.getFolders();

      // Verify empty state is maintained
      expect(retrievedFiles.length, equals(0));
      expect(retrievedFolders.length, equals(0));
    });
  });
}






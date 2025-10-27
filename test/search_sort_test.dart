import 'package:flutter_test/flutter_test.dart';
import 'package:uniflow/providers/file_provider.dart';
import 'package:uniflow/models/app_file.dart';
import 'package:uniflow/models/app_folder.dart';

void main() {
  group('Search and Sort Tests', () {
    late FileProvider fileProvider;

    setUp(() {
      fileProvider = FileProvider();
    });

    test('searchFiles should filter files by name', () async {
      // Add sample files
      fileProvider.files.addAll([
        AppFile(
          id: 'file1',
          name: 'document.pdf',
          path: '/test/document.pdf',
          type: 'pdf',
          size: 1024,
          dateAdded: DateTime.now(),
        ),
        AppFile(
          id: 'file2',
          name: 'image.jpg',
          path: '/test/image.jpg',
          type: 'jpg',
          size: 2048,
          dateAdded: DateTime.now(),
        ),
        AppFile(
          id: 'file3',
          name: 'another_document.pdf',
          path: '/test/another_document.pdf',
          type: 'pdf',
          size: 1024,
          dateAdded: DateTime.now(),
        ),
      ]);

      // Test search by name
      fileProvider.setSearchQuery('document');
      final filteredItems = fileProvider.items;
      
      expect(filteredItems.length, equals(2));
      expect(filteredItems.any((item) => item.name.contains('document')), isTrue);
    });

    test('searchFiles should filter files by type', () async {
      // Add sample files
      fileProvider.files.addAll([
        AppFile(
          id: 'file1',
          name: 'document.pdf',
          path: '/test/document.pdf',
          type: 'pdf',
          size: 1024,
          dateAdded: DateTime.now(),
        ),
        AppFile(
          id: 'file2',
          name: 'image.jpg',
          path: '/test/image.jpg',
          type: 'jpg',
          size: 2048,
          dateAdded: DateTime.now(),
        ),
      ]);

      // Test search by type
      fileProvider.setSearchQuery('pdf');
      final filteredItems = fileProvider.items;
      
      expect(filteredItems.length, equals(1));
      expect(filteredItems.first.name, equals('document.pdf'));
    });

    test('searchFolders should filter folders by name', () async {
      // Add sample folders
      fileProvider.folders.addAll([
        AppFolder(
          id: 'folder1',
          name: 'Important Documents',
          createdAt: DateTime.now(),
        ),
        AppFolder(
          id: 'folder2',
          name: 'Images',
          createdAt: DateTime.now(),
        ),
        AppFolder(
          id: 'folder3',
          name: 'Important Photos',
          createdAt: DateTime.now(),
        ),
      ]);

      // Test search by name
      fileProvider.setSearchQuery('Important');
      final filteredItems = fileProvider.items;
      
      expect(filteredItems.length, equals(2));
      expect(filteredItems.any((item) => item.name.contains('Important')), isTrue);
    });

    test('sortFiles should sort by name ascending', () async {
      // Add sample files
      fileProvider.files.addAll([
        AppFile(
          id: 'file1',
          name: 'zebra.pdf',
          path: '/test/zebra.pdf',
          type: 'pdf',
          size: 1024,
          dateAdded: DateTime.now(),
        ),
        AppFile(
          id: 'file2',
          name: 'apple.jpg',
          path: '/test/apple.jpg',
          type: 'jpg',
          size: 2048,
          dateAdded: DateTime.now(),
        ),
        AppFile(
          id: 'file3',
          name: 'banana.pdf',
          path: '/test/banana.pdf',
          type: 'pdf',
          size: 1024,
          dateAdded: DateTime.now(),
        ),
      ]);

      // Sort by name ascending
      fileProvider.setSortBy('name');
      final sortedItems = fileProvider.items;
      
      expect(sortedItems.length, equals(3));
      expect(sortedItems[0].name, equals('apple.jpg'));
      expect(sortedItems[1].name, equals('banana.pdf'));
      expect(sortedItems[2].name, equals('zebra.pdf'));
    });

    test('sortFiles should sort by name descending', () async {
      // Add sample files
      fileProvider.files.addAll([
        AppFile(
          id: 'file1',
          name: 'apple.pdf',
          path: '/test/apple.pdf',
          type: 'pdf',
          size: 1024,
          dateAdded: DateTime.now(),
        ),
        AppFile(
          id: 'file2',
          name: 'zebra.jpg',
          path: '/test/zebra.jpg',
          type: 'jpg',
          size: 2048,
          dateAdded: DateTime.now(),
        ),
      ]);

      // Sort by name descending
      fileProvider.setSortBy('name'); // First call sets ascending
      fileProvider.setSortBy('name'); // Second call toggles to descending
      final sortedItems = fileProvider.items;
      
      expect(sortedItems.length, equals(2));
      expect(sortedItems[0].name, equals('zebra.jpg'));
      expect(sortedItems[1].name, equals('apple.pdf'));
    });

    test('sortFiles should sort by size ascending', () async {
      // Add sample files
      fileProvider.files.addAll([
        AppFile(
          id: 'file1',
          name: 'large.pdf',
          path: '/test/large.pdf',
          type: 'pdf',
          size: 3000,
          dateAdded: DateTime.now(),
        ),
        AppFile(
          id: 'file2',
          name: 'small.jpg',
          path: '/test/small.jpg',
          type: 'jpg',
          size: 1000,
          dateAdded: DateTime.now(),
        ),
        AppFile(
          id: 'file3',
          name: 'medium.pdf',
          path: '/test/medium.pdf',
          type: 'pdf',
          size: 2000,
          dateAdded: DateTime.now(),
        ),
      ]);

      // Sort by size ascending
      fileProvider.setSortBy('size');
      final sortedItems = fileProvider.items;
      
      expect(sortedItems.length, equals(3));
      expect(sortedItems[0].size, equals(1000));
      expect(sortedItems[1].size, equals(2000));
      expect(sortedItems[2].size, equals(3000));
    });

    test('sortFiles should sort by date ascending', () async {
      final now = DateTime.now();
      // Add sample files with different dates
      fileProvider.files.addAll([
        AppFile(
          id: 'file1',
          name: 'old.pdf',
          path: '/test/old.pdf',
          type: 'pdf',
          size: 1024,
          dateAdded: now.subtract(const Duration(days: 2)),
        ),
        AppFile(
          id: 'file2',
          name: 'new.jpg',
          path: '/test/new.jpg',
          type: 'jpg',
          size: 2048,
          dateAdded: now,
        ),
        AppFile(
          id: 'file3',
          name: 'medium.pdf',
          path: '/test/medium.pdf',
          type: 'pdf',
          size: 1024,
          dateAdded: now.subtract(const Duration(days: 1)),
        ),
      ]);

      // Sort by date ascending
      fileProvider.setSortBy('date');
      final sortedItems = fileProvider.items;
      
      expect(sortedItems.length, equals(3));
      expect(sortedItems[0].name, equals('old.pdf'));
      expect(sortedItems[1].name, equals('medium.pdf'));
      expect(sortedItems[2].name, equals('new.jpg'));
    });

    test('folders should always appear before files', () async {
      // Add sample folders and files
      fileProvider.folders.addAll([
        AppFolder(
          id: 'folder1',
          name: 'Z Folder',
          createdAt: DateTime.now(),
        ),
      ]);
      
      fileProvider.files.addAll([
        AppFile(
          id: 'file1',
          name: 'A File.pdf',
          path: '/test/A File.pdf',
          type: 'pdf',
          size: 1024,
          dateAdded: DateTime.now(),
        ),
      ]);

      // Sort by name
      fileProvider.setSortBy('name');
      final sortedItems = fileProvider.items;
      
      expect(sortedItems.length, equals(2));
      expect(sortedItems[0], isA<AppFolder>());
      expect(sortedItems[1], isA<AppFile>());
    });

    test('clearSearch should clear search query', () async {
      // Add sample files
      fileProvider.files.addAll([
        AppFile(
          id: 'file1',
          name: 'document.pdf',
          path: '/test/document.pdf',
          type: 'pdf',
          size: 1024,
          dateAdded: DateTime.now(),
        ),
        AppFile(
          id: 'file2',
          name: 'image.jpg',
          path: '/test/image.jpg',
          type: 'jpg',
          size: 2048,
          dateAdded: DateTime.now(),
        ),
      ]);

      // Set search query
      fileProvider.setSearchQuery('document');
      expect(fileProvider.searchQuery, equals('document'));
      expect(fileProvider.items.length, equals(1));

      // Clear search
      fileProvider.clearSearch();
      expect(fileProvider.searchQuery, equals(''));
      expect(fileProvider.items.length, equals(2));
    });
  });
}






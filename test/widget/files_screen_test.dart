import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uniflow/screens/files/files_screen.dart';
import 'package:uniflow/providers/file_provider.dart';
import 'package:uniflow/models/app_file.dart';
import 'package:uniflow/models/app_folder.dart';

void main() {
  group('FilesScreen Widget Tests', () {
    testWidgets('FilesScreen displays empty state when no files', (WidgetTester tester) async {
      // Create a mock FileProvider
      final fileProvider = FileProvider();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FileProvider>(
            create: (_) => fileProvider,
            child: const FilesScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.text('No files yet'), findsOneWidget);
      expect(find.text('Import some files or create a folder to get started'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('FilesScreen displays files and folders in grid view', (WidgetTester tester) async {
      // Create a mock FileProvider with sample data
      final fileProvider = FileProvider();
      
      // Add sample data directly to the provider
      fileProvider.files.addAll([
        AppFile(
          id: 'file1',
          name: 'test.pdf',
          path: '/test/test.pdf',
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
      
      fileProvider.folders.addAll([
        AppFolder(
          id: 'folder1',
          name: 'Test Folder',
          createdAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FileProvider>(
            create: (_) => fileProvider,
            child: const FilesScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify files and folders are displayed
      expect(find.text('test.pdf'), findsOneWidget);
      expect(find.text('image.jpg'), findsOneWidget);
      expect(find.text('Test Folder'), findsOneWidget);
    });

    testWidgets('FilesScreen toggles between grid and list view', (WidgetTester tester) async {
      final fileProvider = FileProvider();
      
      // Add sample data
      fileProvider.files.add(
        AppFile(
          id: 'file1',
          name: 'test.pdf',
          path: '/test/test.pdf',
          type: 'pdf',
          size: 1024,
          dateAdded: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FileProvider>(
            create: (_) => fileProvider,
            child: const FilesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the view toggle button
      final viewToggleButton = find.byIcon(Icons.grid_view);
      expect(viewToggleButton, findsOneWidget);
      
      await tester.tap(viewToggleButton);
      await tester.pumpAndSettle();

      // Verify the icon changed to list view
      expect(find.byIcon(Icons.view_list), findsOneWidget);
    });

    testWidgets('FilesScreen shows search dialog when search button is tapped', (WidgetTester tester) async {
      final fileProvider = FileProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FileProvider>(
            create: (_) => fileProvider,
            child: const FilesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the search button
      final searchButton = find.byIcon(Icons.search);
      expect(searchButton, findsOneWidget);
      
      await tester.tap(searchButton);
      await tester.pumpAndSettle();

      // Verify search dialog is displayed
      expect(find.text('Search Files'), findsOneWidget);
      expect(find.text('Enter search term...'), findsOneWidget);
    });

    testWidgets('FilesScreen shows add file bottom sheet when FAB is tapped', (WidgetTester tester) async {
      final fileProvider = FileProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FileProvider>(
            create: (_) => fileProvider,
            child: const FilesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the FAB
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Verify add file bottom sheet is displayed
      expect(find.text('Add New Item'), findsOneWidget);
      expect(find.text('Upload File'), findsOneWidget);
      expect(find.text('Create Folder'), findsOneWidget);
    });

    testWidgets('FilesScreen shows sort menu when sort button is tapped', (WidgetTester tester) async {
      final fileProvider = FileProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FileProvider>(
            create: (_) => fileProvider,
            child: const FilesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the sort button (three dots menu)
      final sortButton = find.byType(PopupMenuButton<String>);
      expect(sortButton, findsOneWidget);
      
      await tester.tap(sortButton);
      await tester.pumpAndSettle();

      // Verify sort options are displayed
      expect(find.text('Sort by Name'), findsOneWidget);
      expect(find.text('Sort by Date'), findsOneWidget);
      expect(find.text('Sort by Size'), findsOneWidget);
    });

    testWidgets('FilesScreen displays loading indicator when loading', (WidgetTester tester) async {
      final fileProvider = FileProvider();
      fileProvider.isLoading = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FileProvider>(
            create: (_) => fileProvider,
            child: const FilesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify loading indicator is displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('FilesScreen displays error message when error occurs', (WidgetTester tester) async {
      final fileProvider = FileProvider();
      fileProvider.error = 'Test error message';

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FileProvider>(
            create: (_) => fileProvider,
            child: const FilesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('Error: Test error message'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('FilesScreen shows create folder dialog when create folder is tapped', (WidgetTester tester) async {
      final fileProvider = FileProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FileProvider>(
            create: (_) => fileProvider,
            child: const FilesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap FAB to show bottom sheet
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Tap create folder option
      await tester.tap(find.text('Create Folder'));
      await tester.pumpAndSettle();

      // Verify create folder dialog is displayed
      expect(find.text('Create Folder'), findsOneWidget);
      expect(find.text('Folder name'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });
  });
}






import 'package:flutter_test/flutter_test.dart';
import 'package:uniflow/screens/files/files_screen.dart';
import 'package:uniflow/providers/file_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

void main() {
  group('Files Integration Tests', () {
    testWidgets('FilesScreen can be created and displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FileProvider>(
            create: (_) => FileProvider(),
            child: const FilesScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the Files screen is displayed
      expect(find.text('My Files'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FilesScreen shows empty state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FileProvider>(
            create: (_) => FileProvider(),
            child: const FilesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty state is shown
      expect(find.text('No files yet'), findsOneWidget);
      expect(find.text('Import some files or create a folder to get started'), findsOneWidget);
    });

    testWidgets('FAB opens add file bottom sheet', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FileProvider>(
            create: (_) => FileProvider(),
            child: const FilesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify bottom sheet is shown
      expect(find.text('Add New Item'), findsOneWidget);
      expect(find.text('Upload File'), findsOneWidget);
      expect(find.text('Create Folder'), findsOneWidget);
    });

    testWidgets('Search button opens search dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FileProvider>(
            create: (_) => FileProvider(),
            child: const FilesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the search button
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Verify search dialog is shown
      expect(find.text('Search Files'), findsOneWidget);
      expect(find.text('Enter search term...'), findsOneWidget);
    });

    testWidgets('View toggle button changes view mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FileProvider>(
            create: (_) => FileProvider(),
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
  });
}






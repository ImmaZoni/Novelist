// lib/main.dart
import 'package:flutter/material.dart';
import 'package:novelist/ui/screens/library_screen.dart'; // We'll create this next
import 'package:hive_flutter/hive_flutter.dart'; // For Hive in Flutter
import 'package:novelist/models/book.dart'; // Assuming you have a Book model

void main() async {
    // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for Flutter
  await Hive.initFlutter(); // Use initFlutter for Flutter apps

  // Register your TypeAdapters (created in Step 3)
  Hive.registerAdapter(BookAdapter()); // We'll generate BookAdapter next
  Hive.registerAdapter(BookFormatAdapter()); // For the enum

  // TODO: Register adapters for ReadingProgress, Bookmark, Note, Annotation later
  // Hive.registerAdapter(ReadingProgressAdapter());
  // Hive.registerAdapter(BookmarkAdapter());

  // Open your boxes (you can open them here or in the services that use them)
  // It's often good practice to open them where they are first needed or in a dedicated init service.
  // For simplicity now, we can open the library box here or ensure it's opened by LibraryService.
  // await Hive.openBox<Book>(kLibraryBox); // kLibraryBox from app_constants.dart

  runApp(const NovelistApp());
}

class NovelistApp extends StatelessWidget {
  const NovelistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novelist', // App title
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey), // Or your preferred seed color
        // TODO: Define more theme aspects: typography, other colors for light/dark themes
      ),
      // TODO: Implement dark theme later:
      // darkTheme: ThemeData.dark().copyWith(
      //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey, brightness: Brightness.dark),
      // ),
      // themeMode: ThemeMode.system, // Or allow user to choose
      home: const LibraryScreen(), // Start with the library screen
    );
  }
}
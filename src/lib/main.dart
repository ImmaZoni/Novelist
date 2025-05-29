// lib/main.dart
import 'package:flutter/material.dart';
import 'package:novelist/ui/screens/library_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:novelist/models/book.dart';
import 'package:novelist/services/settings_service.dart'; // Import SettingsService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(BookAdapter());
  Hive.registerAdapter(BookFormatAdapter());

  // Load initial theme mode
  final settingsService = SettingsService();
  final initialThemeMode = await settingsService.getAppThemeMode();

  runApp(NovelistApp(initialThemeMode: initialThemeMode));
}

class NovelistApp extends StatelessWidget {
  final ThemeMode initialThemeMode; // Accept initial theme mode

  const NovelistApp({super.key, required this.initialThemeMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novelist',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey, brightness: Brightness.light),
        // Define other light theme properties
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey, brightness: Brightness.dark),
        // Define other dark theme properties
      ),
      themeMode: initialThemeMode, // Use the loaded theme mode
      home: const LibraryScreen(),
    );
  }
}
// lib/core/app_routes.dart
import 'package:flutter/material.dart';
import 'package:novelist/models/book.dart'; // Assuming book.dart exists
import 'package:novelist/ui/screens/library_screen.dart';
import 'package:novelist/ui/screens/reading_screen.dart'; // Assuming reading_screen.dart exists
import 'package:novelist/ui/screens/settings_screen.dart'; // Assuming settings_screen.dart exists

class AppRoutes {
  static const String library = '/';
  static const String reading = '/reading';
  static const String settings = '/settings';
  // Add more routes as your app grows

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.library:
        return MaterialPageRoute(builder: (_) => const LibraryScreen());
      case AppRoutes.reading:
        final book = settings.arguments as Book?; // Example of passing arguments
        if (book != null) {
          return MaterialPageRoute(builder: (_) => ReadingScreen(book: book));
        }
        return _errorRoute("Book argument missing for reading screen");
      case AppRoutes.settings:
         return MaterialPageRoute(builder: (_) => const SettingsScreen());
      // Add more cases for other routes
      default:
        return _errorRoute("Unknown route: ${settings.name}");
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('ROUTE ERROR: $message')),
      ),
    );
  }
}

// To use named routes in main.dart:
//
// class NovelistApp extends StatelessWidget {
//   const NovelistApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Novelist',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
//       ),
//       initialRoute: AppRoutes.library, // Set initial route
//       onGenerateRoute: AppRoutes.generateRoute, // Use the route generator
//     );
//   }
// }
//
// And to navigate:
// Navigator.pushNamed(context, AppRoutes.reading, arguments: myBook);
// lib/ui/screens/reading_screen.dart
import 'package:flutter/material.dart';
import 'package:novelist/models/book.dart'; // Import your Book model

class ReadingScreen extends StatelessWidget {
  final Book book;

  const ReadingScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title), // Display book title in AppBar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Reading: ${book.title}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('Author: ${book.author ?? "N/A"}'),
            Text('File Path: ${book.filePath}'),
            Text('Format: ${book.format.toString().split('.').last}'),
            const SizedBox(height: 32),
            const Text(
              '(Content rendering will be here)',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
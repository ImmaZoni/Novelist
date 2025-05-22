// lib/ui/screens/library_screen.dart
import 'package:flutter/material.dart';
import 'package:novelist/models/book.dart';
import 'package:novelist/services/library_service.dart'; // Import the service
import 'package:novelist/ui/screens/reading_screen.dart';
import 'package:novelist/ui/screens/settings_screen.dart'; // Import settings screen
import 'dart:io'; // For File operations
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p; // Already in pubspec from utils.dart
import 'package:novelist/core/utils.dart'; // For getFileExtension
import 'package:permission_handler/permission_handler.dart'; // For permissions

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final LibraryService _libraryService = LibraryService(); // Instantiate your service
  late Future<List<Book>> _booksFuture; // To hold the future for books

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    // Initialize the service and then load books
    await _libraryService.init(); // Ensure service (and box) is initialized
    setState(() {
      _booksFuture = _libraryService.getBooks();
    });
  }

  void _refreshLibrary() {
    // Call this after adding/deleting books to update the UI
    setState(() {
      _booksFuture = _libraryService.getBooks();
    });
  }


Future<void> _importBook() async {
  // Request permissions if needed (especially for Android)
  // On desktop, file picker usually handles this. On mobile, explicit permission might be needed
  // for broader storage access, though FilePicker can sometimes work without it for specific types.
  // For simplicity, let's assume FilePicker handles what it can, but be mindful of platform differences.
  // if (Platform.isAndroid || Platform.isIOS) {
  //   var status = await Permission.storage.status; // or photos, mediaLibrary depending on scope
  //   if (!status.isGranted) {
  //     status = await Permission.storage.request();
  //   }
  //   if (!status.isGranted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Storage permission denied')),
  //     );
  //     return;
  //   }
  // }

  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['epub', 'pdf', 'mobi', 'txt', 'html'], // Define supported extensions
  );

  if (result != null && result.files.single.path != null) {
    PlatformFile file = result.files.single;
    String originalPath = file.path!;

    try {
      // 1. Get app's document directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String booksDir = p.join(appDocDir.path, 'books');
      await Directory(booksDir).create(recursive: true); // Ensure 'books' directory exists

      // 2. Create a unique filename or use the original, then copy
      final String fileName = p.basename(originalPath);
      final String newFilePath = p.join(booksDir, fileName);

      // Check if a book with this newFilePath already exists to avoid duplicates by path
      // (A more robust check might involve hashing the file or checking metadata)
      List<Book> currentBooks = await _libraryService.getBooks();
      if (currentBooks.any((book) => book.filePath == newFilePath)) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Book "${p.basename(newFilePath)}" already in library.')),
        );
        return;
      }

      await File(originalPath).copy(newFilePath);

      // 3. Determine book format (basic guess from extension)
      BookFormat format = BookFormat.unknown;
      String extension = getFileExtension(newFilePath); // From your utils.dart
      switch (extension) {
        case 'epub':
          format = BookFormat.epub;
          break;
        case 'pdf':
          format = BookFormat.pdf;
          break;
        case 'mobi':
          format = BookFormat.mobi;
          break;
        case 'txt':
          format = BookFormat.txt;
          break;
        case 'html':
          format = BookFormat.html;
          break;
      }

      // 4. TODO: Extract metadata (title, author) using a parser for EPUB, etc.
      // For now, use filename as title.
      String titleFromFile = p.basenameWithoutExtension(newFilePath);
      String? authorFromFile; // Placeholder

      // Example of calling a (yet to be created) metadata service
      // Map<String, String?> metadata = await MetadataService.extractMetadata(newFilePath, format);
      // titleFromFile = metadata['title'] ?? titleFromFile;
      // authorFromFile = metadata['author'];

      final newBook = Book(
        title: titleFromFile,
        author: authorFromFile, // Will be null for now
        filePath: newFilePath, // IMPORTANT: Use the new path in app storage
        format: format,
      );

      await _libraryService.addBook(newBook);
      _refreshLibrary();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported: ${newBook.title}')),
      );
    } catch (e, s) {
      ErrorHandler.recordError(e, s, reason: "Failed to import book: $originalPath");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing book: $e')),
      );
    }
  } else {
    // User canceled the picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Book import cancelled')),
    );
  }
}

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingScreen(book: book),
      ),
    ).then((_) {
      // When returning from ReadingScreen, the book's progress might have changed.
      // If the book object was modified and saved in ReadingScreen,
      // you might want to refresh or find a way to update just that item.
      _refreshLibrary(); // Simple refresh for now
    });
  }

   Future<void> _deleteBook(Book book) async {
    // Show a confirmation dialog
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Book?'),
          content: Text('Are you sure you want to delete "${book.title}"? This cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await _libraryService.deleteBook(book.id);
      _refreshLibrary();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted: ${book.title}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), // Add a refresh button for testing
            onPressed: _refreshLibrary,
            tooltip: 'Refresh Library',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Book>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // You can use your ErrorHandler here
            // ErrorHandler.recordError(snapshot.error, snapshot.stackTrace, reason: "Failed to load library");
            return Center(child: Text('Error loading library: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column( // Empty state UI
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Your library is empty.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Import your first book'),
                    onPressed: _importBook, // This will use the mock add for now
                  ),
                ],
              ),
            );
          }

          final books = snapshot.data!;
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                leading: const Icon(Icons.book_online_outlined), // Placeholder for cover
                title: Text(book.title),
                subtitle: Text(book.author ?? "Unknown Author"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _deleteBook(book),
                  tooltip: 'Delete Book',
                ),
                onTap: () => _openBook(book),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importBook, // This will use the mock add for now
        tooltip: 'Import Book (Test Add)',
        child: const Icon(Icons.add_circle_outline_sharp),
      ),
    );
  }
}
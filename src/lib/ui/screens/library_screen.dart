// lib/ui/screens/library_screen.dart
import 'package:flutter/material.dart';
import 'package:novelist/models/book.dart';
import 'package:novelist/services/library_service.dart';
import 'package:novelist/ui/screens/reading_screen.dart';
import 'package:novelist/ui/screens/settings_screen.dart';
import 'dart:io'; // For File operations
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:novelist/core/utils.dart';
import 'package:novelist/core/error_handler.dart';
import 'package:novelist/services/metadata_service.dart';
import 'package:novelist/core/app_constants.dart';
// Import the new screen (we'll create it next and then uncomment this)
import 'package:novelist/ui/screens/cover_search_screen.dart'; 

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final LibraryService _libraryService = LibraryService();
  late Future<List<Book>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    await _libraryService.init();
    setState(() {
      _booksFuture = _libraryService.getBooks();
    });
  }

  void _refreshLibrary() {
    setState(() {
      _booksFuture = _libraryService.getBooks();
    });
  }

  Future<void> _importBook() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'pdf', 'mobi', 'txt', 'html'],
    );

    if (result != null && result.files.single.path != null) {
      PlatformFile file = result.files.single;
      String originalPath = file.path!;

      try {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String booksDir = p.join(appDocDir.path, 'books');
        await Directory(booksDir).create(recursive: true);

        final String fileName = p.basename(originalPath);
        final String newFilePath = p.join(booksDir, fileName);

        List<Book> currentBooks = await _libraryService.getBooks();
        if (currentBooks.any((book) => book.filePath == newFilePath)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Book "${p.basename(newFilePath)}" already in library.')),
            );
          }
          return;
        }

        await File(originalPath).copy(newFilePath);

        BookFormat format = BookFormat.unknown;
        String extension = getFileExtension(newFilePath);
        switch (extension) {
          case 'epub':
            format = BookFormat.epub;
            break;
          case 'pdf':
            format = BookFormat.pdf;
            break;
          // Add other cases as needed
        }

        Map<String, String?> extractedMeta = await MetadataService.extractMetadata(newFilePath, format);

        String titleFromFile = extractedMeta['title'] ?? p.basenameWithoutExtension(newFilePath);
        String? authorFromFile = extractedMeta['author'];
        String? coverPathFromFile = extractedMeta['coverPath']; 

        final newBook = Book(
          title: titleFromFile,
          author: authorFromFile,
          filePath: newFilePath,
          format: format,
          coverImagePath: coverPathFromFile,
        );

        await _libraryService.addBook(newBook);
        _refreshLibrary();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported: ${newBook.title}')),
          );
        }
      } catch (e, s) {
        ErrorHandler.recordError(e, s, reason: "Failed to import book: $originalPath");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error importing book: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book import cancelled')),
        );
      }
    }
  }

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingScreen(book: book),
      ),
    ).then((_) {
      _refreshLibrary();
    });
  }

  Future<void> _deleteBook(Book book) async {
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
      try {
        await _libraryService.deleteBook(book.id); 
        _refreshLibrary();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted: ${book.title}')),
          );
        }
      } catch (e,s) {
         ErrorHandler.recordError(e, s, reason: "Error deleting book from library screen", scope: "LibraryScreen");
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting book: $e')),
          );
        }
      }
    }
  }

  // *** ADDED THIS METHOD ***
  void _showBookOptions(BuildContext context, Book book) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.image_search),
                title: const Text('Set Book Cover'),
                onTap: () {
                  Navigator.pop(bc); // Close the bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CoverSearchScreen(book: book),
                    ),
                  ).then((coverChanged) { // Expecting a boolean true if cover was changed
                    if (coverChanged == true) {
                      _refreshLibrary();
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Metadata'),
                onTap: () {
                  Navigator.pop(bc);
                  ErrorHandler.logInfo("Edit metadata tapped for ${book.title} - Not implemented.", scope: "LibraryScreen");
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Edit metadata for "${book.title}" (Not Implemented Yet)')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
                title: const Text('Delete Book', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(bc);
                  _deleteBook(book);
                },
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         title: const Text('My Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
            ErrorHandler.recordError(snapshot.error, snapshot.stackTrace, reason: "Failed to load library");
            return Center(child: Text('Error loading library: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book, size: 80, color: Colors.grey),
                  const SizedBox(height: kDefaultPadding),
                  const Text(
                    'Your library is empty.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: kSmallPadding),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Import your first book'),
                    onPressed: _importBook,
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
              Widget leadingWidget;
              if (book.coverImagePath != null && book.coverImagePath!.isNotEmpty) {
                File coverFile = File(book.coverImagePath!);
                leadingWidget = SizedBox( 
                  width: 50,
                  height: 70, 
                  child: Image.file(
                    coverFile,
                    fit: BoxFit.cover, 
                    errorBuilder: (context, error, stackTrace) {
                      ErrorHandler.logWarning("Failed to load cover: ${book.coverImagePath} for ${book.title}. Error: $error", scope: "LibraryScreen");
                      return const Icon(Icons.broken_image, size: 40); 
                    },
                  ),
                );
              } else {
                leadingWidget = const Icon(Icons.book_outlined, size: 40); 
              }

              return ListTile(
                leading: leadingWidget,
                title: Text(book.title),
                subtitle: Text(book.author ?? "Unknown Author"),
                onLongPress: () { // *** ADDED ON LONG PRESS ***
                  _showBookOptions(context, book);
                },
                trailing: IconButton( 
                  icon: const Icon(Icons.more_vert), // *** CHANGED ICON ***
                  onPressed: () => _showBookOptions(context, book), // *** CALLS OPTIONS MENU ***
                  tooltip: 'More options',
                ),
                onTap: () => _openBook(book),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importBook,
        tooltip: 'Import Book',
        child: const Icon(Icons.add_circle_outline_sharp),
      ),
    );
  }
}
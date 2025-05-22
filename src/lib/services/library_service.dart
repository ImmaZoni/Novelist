// lib/services/library_service.dart
import "dart:io";
import 'package:hive_flutter/hive_flutter.dart';
import 'package:novelist/core/app_constants.dart'; // For kLibraryBox
import 'package:novelist/models/book.dart';
import 'package:novelist/core/error_handler.dart';

class LibraryService {
  late Box<Book> _libraryBox;

  // Initialize the service, typically called once when the app starts or before first use.
  Future<void> init() async {
    // Open the Hive box for books. It will be created if it doesn't exist.
    // If BookAdapter is not registered in main.dart before this, it will fail.
    if (!Hive.isBoxOpen(kLibraryBox)) {
      _libraryBox = await Hive.openBox<Book>(kLibraryBox);
    } else {
      _libraryBox = Hive.box<Book>(kLibraryBox);
    }
  }

  // Get all books from the library
  Future<List<Book>> getBooks() async {
    // Ensure the box is open (could add a check or rely on init)
    if (!_libraryBox.isOpen) await init();
    return _libraryBox.values.toList();
  }

  // Add a new book to the library
  // The book's 'id' will be used as the key in the Hive box.
  Future<void> addBook(Book book) async {
    if (!_libraryBox.isOpen) await init();
    await _libraryBox.put(book.id, book); // Using book.id as the key
  }

  // Update an existing book
  Future<void> updateBook(Book book) async {
    if (!_libraryBox.isOpen) await init();
    // If the book object extends HiveObject and was fetched from the box,
    // you can just call book.save() on the modified object.
    // Otherwise, use put to overwrite.
    await _libraryBox.put(book.id, book);
  }

  // Get a specific book by its ID
  Future<Book?> getBookById(String bookId) async {
    if (!_libraryBox.isOpen) await init();
    return _libraryBox.get(bookId);
  }

  // Delete a book from the library by its ID
  Future<void> deleteBook(String bookId) async {
    if (!_libraryBox.isOpen) await init();
    final book = _libraryBox.get(bookId); // Get the book before deleting from Hive

    if (book != null) {
      try {
        // Delete the book file
        final bookFile = File(book.filePath);
        if (await bookFile.exists()) {
          await bookFile.delete();
        }
        // Delete the cover image file
        if (book.coverImagePath != null) {
          final coverFile = File(book.coverImagePath!);
          if (await coverFile.exists()) {
            await coverFile.delete();
          }
        }
      } catch (e, s) {
        ErrorHandler.recordError(e, s, reason: "Failed to delete book files for ${book.title}");
      }
    }
    await _libraryBox.delete(bookId);
  }

  // Close the box when the service is disposed or app is closing (optional but good practice)
  Future<void> dispose() async {
    await _libraryBox.close();
  }
}
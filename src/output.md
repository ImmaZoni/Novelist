# Project Structure

```
README.md
analysis_options.yaml
/android
/ios
/lib
- /core
-- app_constants.dart
-- app_routes.dart
-- error_handler.dart
-- utils.dart
- main.dart
- /models
-- book.dart
-- book.g.dart
- /plugins
- /services
-- library_service.dart
-- metadata_service.dart
- /ui
-- /screens
--- library_screen.dart
--- reading_screen.dart
--- settings_screen.dart
/linux
/macos
pubspec.lock
pubspec.yaml
/test
/web
/windows
```

# File Contents

## README.md

```markdown
# novelist

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

```

## analysis_options.yaml

```yaml
# This file configures the analyzer, which statically analyzes Dart code to
# check for errors, warnings, and lints.
#
# The issues identified by the analyzer are surfaced in the UI of Dart-enabled
# IDEs (https://dart.dev/tools#ides-and-editors). The analyzer can also be
# invoked from the command line by running `flutter analyze`.

# The following line activates a set of recommended lints for Flutter apps,
# packages, and plugins designed to encourage good coding practices.
include: package:flutter_lints/flutter.yaml

linter:
  # The lint rules applied to this project can be customized in the
  # section below to disable rules from the `package:flutter_lints/flutter.yaml`
  # included above or to enable additional rules. A list of all available lints
  # and their documentation is published at https://dart.dev/lints.
  #
  # Instead of disabling a lint rule for the entire project in the
  # section below, it can also be suppressed for a single line of code
  # or a specific dart file by using the `// ignore: name_of_lint` and
  # `// ignore_for_file: name_of_lint` syntax on the line or in the file
  # producing the lint.
  rules:
    # avoid_print: false  # Uncomment to disable the `avoid_print` rule
    # prefer_single_quotes: true  # Uncomment to enable the `prefer_single_quotes` rule

# Additional information about this file can be found at
# https://dart.dev/guides/language/analysis-options

```

## lib/core/app_constants.dart

```dart
// lib/core/app_constants.dart

import 'package:flutter/material.dart';

// --- App Information ---
const String kAppName = 'Novelist';
const String kAppVersion = '1.0.0-alpha'; // Or your initial version

// --- UI Constants ---
// Example: Default padding
const double kDefaultPadding = 16.0;
const double kSmallPadding = 8.0;
const double kMediumPadding = 24.0;
const double kLargePadding = 32.0;

// Example: BorderRadius
const double kDefaultBorderRadius = 8.0;

// --- Colors (Can be expanded into a full AppColors class if needed) ---
// You might define your primary theme colors here if not directly in ThemeData,
// or specific colors used in multiple places.
// For now, we'll mostly rely on ThemeData, but here's an example:
// const Color kAccentColor = Colors.amber;

// --- Storage Keys (for shared_preferences or Hive boxes) ---
const String kSettingsBox = 'novelist_settings_box';
const String kLibraryBox = 'novelist_library_box';

const String kThemeModeKey = 'theme_mode';
// Add more keys as needed for settings

// --- Routes (If using named routes) ---
// Defined in app_routes.dart but can be referenced here if needed.
// Example:
// const String kRouteLibrary = '/';
// const String kRouteReading = '/reading';
// const String kRouteSettings = '/settings';

// --- Default Values ---
const String kDefaultFontFamily = 'Roboto'; // Example, Flutter uses this by default

// --- API Endpoints or other service-specific constants (if any) ---
// Example:
// const String kGoogleBooksApiBaseUrl = 'https://www.googleapis.com/books/v1/';

// --- Durations ---
const Duration kShortAnimationDuration = Duration(milliseconds: 200);
const Duration kMediumAnimationDuration = Duration(milliseconds: 500);

// --- You can add more categories as your app grows ---
// e.g., Error Messages, Notification Channels, etc.

// Example of a utility function that might live here or in a separate utils file
// String formatBookTitle(String title) {
//   return title.length > 30 ? '${title.substring(0, 27)}...' : title;
// }
```

## lib/core/app_routes.dart

```dart
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
```

## lib/core/error_handler.dart

```dart
// lib/core/error_handler.dart
import 'package:flutter/foundation.dart'; // For kDebugMode

class ErrorHandler {
  static void recordError(dynamic error, StackTrace? stackTrace, {String? reason, bool fatal = false}) {
    if (kDebugMode) {
      print('-------------------------------- ERROR --------------------------------');
      if (reason != null) {
        print('Reason: $reason');
      }
      print('Error: $error');
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
      print('-----------------------------------------------------------------------');
    }

    // TODO: Integrate with a crash reporting service like Sentry or Firebase Crashlytics in production
    // if (!kDebugMode) {
    //   if (fatal) {
    //     FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: reason, fatal: true);
    //   } else {
    //     FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: reason);
    //   }
    // }
  }

  static void logInfo(String message, {String? scope}) {
    if (kDebugMode) {
      print('[INFO${scope != null ? ' - $scope' : ''}] $message');
    }
    // TODO: Optionally log to a file or analytics in production
  }

  static void logWarning(String message, {String? scope}) {
     if (kDebugMode) {
      print('[WARNING${scope != null ? ' - $scope' : ''}] $message');
    }
    // TODO: Optionally log to a file or analytics in production
  }
}

// Example usage:
// try {
//   // ... some operation
// } catch (e, s) {
//   ErrorHandler.recordError(e, s, reason: 'Failed to load books');
// }
//
// ErrorHandler.logInfo('User opened library screen.');
```

## lib/core/utils.dart

```dart
// lib/core/utils.dart

import 'dart:io';
import 'package:path/path.dart' as p; // Add path package: path: ^1.9.0 (or latest)

// Example: Get file extension
String getFileExtension(String filePath) {
  try {
    return p.extension(filePath).toLowerCase().replaceAll('.', '');
  } catch (e) {
    return '';
  }
}

// Example: Format file size (very basic)
String formatBytes(int bytes, int decimals) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (bytes.toString().length - 1) ~/ 3; // Not a precise calculation for base 1024
  // For a more accurate one, use log base 1024 or iterate.
  // This is a simpler approximation for display.
  // Proper way:
  // var i = (log(bytes) / log(1024)).floor();
  // return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
  // Simpler for now:
  if (i >= suffixes.length) i = suffixes.length - 1;
  return '${(bytes / (1 << (i * 10))).toStringAsFixed(decimals)} ${suffixes[i]}';
}

// You might add more specific utilities here like:
// - Date formatting helpers
// - String manipulation helpers not specific to a model
```

## lib/main.dart

```dart
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
```

## lib/models/book.dart

```dart
// lib/models/book.dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'book.g.dart'; // This line will be generated by build_runner

@HiveType(typeId: 1) // Unique typeId for BookFormat enum
enum BookFormat {
  @HiveField(0)
  epub,
  @HiveField(1)
  pdf,
  @HiveField(2)
  mobi,
  @HiveField(3)
  txt,
  @HiveField(4)
  html,
  @HiveField(5)
  unknown
}

@HiveType(typeId: 0) // Unique typeId for Book class
class Book extends HiveObject { // Extend HiveObject for easier management
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? author;

  @HiveField(3)
  String filePath; // Path to the actual book file in app's storage

  @HiveField(4)
  BookFormat format;

  @HiveField(5)
  String? coverImagePath; // Path to a cover image

  @HiveField(6)
  DateTime dateAdded;

  @HiveField(7)
  DateTime? lastRead;

  // --- Reading Progress related fields (can be a separate linked object later) ---
  @HiveField(8)
  double readingPercentage; // e.g., 0.0 to 1.0

  @HiveField(9)
  String? lastLocation; // e.g., EPUB CFI, PDF page number

  // --- Other potential fields ---
  // @HiveField(10)
  // List<String> collectionIds; // IDs of collections this book belongs to

  // @HiveField(11)
  // List<String> bookmarkIds; // IDs of bookmarks associated with this book

  // @HiveField(12)
  // List<String> annotationIds; // IDs of annotations for this book

  Book({
    String? id,
    required this.title,
    this.author,
    required this.filePath,
    required this.format,
    this.coverImagePath,
    DateTime? dateAdded,
    this.lastRead,
    this.readingPercentage = 0.0,
    this.lastLocation,
  })  : id = id ?? const Uuid().v4(),
        dateAdded = dateAdded ?? DateTime.now();

  // No need for toJson/fromJson if primarily using Hive adapters,
  // but they can be useful for other purposes (like API calls).

  // You might add a convenience method to update progress:
  void updateReadingProgress({required double percentage, String? location}) {
    readingPercentage = percentage;
    lastLocation = location;
    if (this.isInBox) { // Check if the object is managed by Hive
      this.save(); // Save changes if it's a Hive-managed object
    }
  }
}
```

## lib/models/book.g.dart

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookAdapter extends TypeAdapter<Book> {
  @override
  final int typeId = 0;

  @override
  Book read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Book(
      id: fields[0] as String?,
      title: fields[1] as String,
      author: fields[2] as String?,
      filePath: fields[3] as String,
      format: fields[4] as BookFormat,
      coverImagePath: fields[5] as String?,
      dateAdded: fields[6] as DateTime?,
      lastRead: fields[7] as DateTime?,
      readingPercentage: fields[8] as double,
      lastLocation: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.filePath)
      ..writeByte(4)
      ..write(obj.format)
      ..writeByte(5)
      ..write(obj.coverImagePath)
      ..writeByte(6)
      ..write(obj.dateAdded)
      ..writeByte(7)
      ..write(obj.lastRead)
      ..writeByte(8)
      ..write(obj.readingPercentage)
      ..writeByte(9)
      ..write(obj.lastLocation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BookFormatAdapter extends TypeAdapter<BookFormat> {
  @override
  final int typeId = 1;

  @override
  BookFormat read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BookFormat.epub;
      case 1:
        return BookFormat.pdf;
      case 2:
        return BookFormat.mobi;
      case 3:
        return BookFormat.txt;
      case 4:
        return BookFormat.html;
      case 5:
        return BookFormat.unknown;
      default:
        return BookFormat.epub;
    }
  }

  @override
  void write(BinaryWriter writer, BookFormat obj) {
    switch (obj) {
      case BookFormat.epub:
        writer.writeByte(0);
        break;
      case BookFormat.pdf:
        writer.writeByte(1);
        break;
      case BookFormat.mobi:
        writer.writeByte(2);
        break;
      case BookFormat.txt:
        writer.writeByte(3);
        break;
      case BookFormat.html:
        writer.writeByte(4);
        break;
      case BookFormat.unknown:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookFormatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

```

## lib/services/library_service.dart

```dart
// lib/services/library_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:novelist/core/app_constants.dart'; // For kLibraryBox
import 'package:novelist/models/book.dart';

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
```

## lib/services/metadata_service.dart

```dart
// lib/services/metadata_service.dart
import 'package:epubx/epubx.dart'; // Or epubx
import 'package:novelist/models/book.dart'; // For BookFormat

class MetadataService {
  static Future<Map<String, String?>> extractMetadata(String filePath, BookFormat format) async {
    Map<String, String?> metadata = {'title': null, 'author': null, 'coverPath': null};

    if (format == BookFormat.epub) {
      try {
        // Note: epubx reads the file directly.
        EpubBook epubBook = await EpubReader.readBook(filePath); // epubx specific

        metadata['title'] = epubBook.Title;
        metadata['author'] = epubBook.Author ?? (epubBook.AuthorList?.isNotEmpty == true ? epubBook.AuthorList!.join(', ') : null);

        // TODO: Extract and save cover image if desired
        // if (epubBook.CoverImage != null) {
        //   // 1. Get app's document directory (use path_provider)
        //   // 2. Create a 'covers' subdirectory
        //   // 3. Save epubBook.CoverImage (which is Uint8List) to a file in 'covers'
        //   // 4. Store the path to this cover image file in metadata['coverPath']
        // }

      } catch (e) {
        print("Error parsing EPUB metadata for $filePath: $e");
        // Fallback to filename if parsing fails
      }
    } else if (format == BookFormat.pdf) {
      // TODO: PDF metadata extraction (can be complex, may need a dedicated PDF library)
    }
    // Add other formats if needed

    return metadata;
  }
}
```

## lib/ui/screens/library_screen.dart

```dart
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
```

## lib/ui/screens/reading_screen.dart

```dart
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
```

## lib/ui/screens/settings_screen.dart

```dart
// lib/ui/screens/settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Text(
          'Application settings will be here.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
```

## pubspec.lock

```lock
# Generated by pub
# See https://dart.dev/tools/pub/glossary#lockfile
packages:
  _fe_analyzer_shared:
    dependency: transitive
    description:
      name: _fe_analyzer_shared
      sha256: "16e298750b6d0af7ce8a3ba7c18c69c3785d11b15ec83f6dcd0ad2a0009b3cab"
      url: "https://pub.dev"
    source: hosted
    version: "76.0.0"
  _macros:
    dependency: transitive
    description: dart
    source: sdk
    version: "0.3.3"
  analyzer:
    dependency: transitive
    description:
      name: analyzer
      sha256: "1f14db053a8c23e260789e9b0980fa27f2680dd640932cae5e1137cce0e46e1e"
      url: "https://pub.dev"
    source: hosted
    version: "6.11.0"
  args:
    dependency: transitive
    description:
      name: args
      sha256: d0481093c50b1da8910eb0bb301626d4d8eb7284aa739614d2b394ee09e3ea04
      url: "https://pub.dev"
    source: hosted
    version: "2.7.0"
  async:
    dependency: transitive
    description:
      name: async
      sha256: "758e6d74e971c3e5aceb4110bfd6698efc7f501675bcfe0c775459a8140750eb"
      url: "https://pub.dev"
    source: hosted
    version: "2.13.0"
  boolean_selector:
    dependency: transitive
    description:
      name: boolean_selector
      sha256: "8aab1771e1243a5063b8b0ff68042d67334e3feab9e95b9490f9a6ebf73b42ea"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.2"
  build:
    dependency: transitive
    description:
      name: build
      sha256: cef23f1eda9b57566c81e2133d196f8e3df48f244b317368d65c5943d91148f0
      url: "https://pub.dev"
    source: hosted
    version: "2.4.2"
  build_config:
    dependency: transitive
    description:
      name: build_config
      sha256: "4ae2de3e1e67ea270081eaee972e1bd8f027d459f249e0f1186730784c2e7e33"
      url: "https://pub.dev"
    source: hosted
    version: "1.1.2"
  build_daemon:
    dependency: transitive
    description:
      name: build_daemon
      sha256: "8e928697a82be082206edb0b9c99c5a4ad6bc31c9e9b8b2f291ae65cd4a25daa"
      url: "https://pub.dev"
    source: hosted
    version: "4.0.4"
  build_resolvers:
    dependency: transitive
    description:
      name: build_resolvers
      sha256: b9e4fda21d846e192628e7a4f6deda6888c36b5b69ba02ff291a01fd529140f0
      url: "https://pub.dev"
    source: hosted
    version: "2.4.4"
  build_runner:
    dependency: "direct dev"
    description:
      name: build_runner
      sha256: "058fe9dce1de7d69c4b84fada934df3e0153dd000758c4d65964d0166779aa99"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.15"
  build_runner_core:
    dependency: transitive
    description:
      name: build_runner_core
      sha256: "22e3aa1c80e0ada3722fe5b63fd43d9c8990759d0a2cf489c8c5d7b2bdebc021"
      url: "https://pub.dev"
    source: hosted
    version: "8.0.0"
  built_collection:
    dependency: transitive
    description:
      name: built_collection
      sha256: "376e3dd27b51ea877c28d525560790aee2e6fbb5f20e2f85d5081027d94e2100"
      url: "https://pub.dev"
    source: hosted
    version: "5.1.1"
  built_value:
    dependency: transitive
    description:
      name: built_value
      sha256: ea90e81dc4a25a043d9bee692d20ed6d1c4a1662a28c03a96417446c093ed6b4
      url: "https://pub.dev"
    source: hosted
    version: "8.9.5"
  characters:
    dependency: transitive
    description:
      name: characters
      sha256: f71061c654a3380576a52b451dd5532377954cf9dbd272a78fc8479606670803
      url: "https://pub.dev"
    source: hosted
    version: "1.4.0"
  checked_yaml:
    dependency: transitive
    description:
      name: checked_yaml
      sha256: feb6bed21949061731a7a75fc5d2aa727cf160b91af9a3e464c5e3a32e28b5ff
      url: "https://pub.dev"
    source: hosted
    version: "2.0.3"
  clock:
    dependency: transitive
    description:
      name: clock
      sha256: fddb70d9b5277016c77a80201021d40a2247104d9f4aa7bab7157b7e3f05b84b
      url: "https://pub.dev"
    source: hosted
    version: "1.1.2"
  code_builder:
    dependency: transitive
    description:
      name: code_builder
      sha256: "0ec10bf4a89e4c613960bf1e8b42c64127021740fb21640c29c909826a5eea3e"
      url: "https://pub.dev"
    source: hosted
    version: "4.10.1"
  collection:
    dependency: transitive
    description:
      name: collection
      sha256: "2f5709ae4d3d59dd8f7cd309b4e023046b57d8a6c82130785d2b0e5868084e76"
      url: "https://pub.dev"
    source: hosted
    version: "1.19.1"
  convert:
    dependency: transitive
    description:
      name: convert
      sha256: b30acd5944035672bc15c6b7a8b47d773e41e2f17de064350988c5d02adb1c68
      url: "https://pub.dev"
    source: hosted
    version: "3.1.2"
  crypto:
    dependency: transitive
    description:
      name: crypto
      sha256: "1e445881f28f22d6140f181e07737b22f1e099a5e1ff94b0af2f9e4a463f4855"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.6"
  cupertino_icons:
    dependency: "direct main"
    description:
      name: cupertino_icons
      sha256: ba631d1c7f7bef6b729a622b7b752645a2d076dba9976925b8f25725a30e1ee6
      url: "https://pub.dev"
    source: hosted
    version: "1.0.8"
  dart_style:
    dependency: transitive
    description:
      name: dart_style
      sha256: "7306ab8a2359a48d22310ad823521d723acfed60ee1f7e37388e8986853b6820"
      url: "https://pub.dev"
    source: hosted
    version: "2.3.8"
  fake_async:
    dependency: transitive
    description:
      name: fake_async
      sha256: "5368f224a74523e8d2e7399ea1638b37aecfca824a3cc4dfdf77bf1fa905ac44"
      url: "https://pub.dev"
    source: hosted
    version: "1.3.3"
  ffi:
    dependency: transitive
    description:
      name: ffi
      sha256: "289279317b4b16eb2bb7e271abccd4bf84ec9bdcbe999e278a94b804f5630418"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.4"
  file:
    dependency: transitive
    description:
      name: file
      sha256: a3b4f84adafef897088c160faf7dfffb7696046cb13ae90b508c2cbc95d3b8d4
      url: "https://pub.dev"
    source: hosted
    version: "7.0.1"
  fixnum:
    dependency: transitive
    description:
      name: fixnum
      sha256: b6dc7065e46c974bc7c5f143080a6764ec7a4be6da1285ececdc37be96de53be
      url: "https://pub.dev"
    source: hosted
    version: "1.1.1"
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
  flutter_lints:
    dependency: "direct dev"
    description:
      name: flutter_lints
      sha256: "5398f14efa795ffb7a33e9b6a08798b26a180edac4ad7db3f231e40f82ce11e1"
      url: "https://pub.dev"
    source: hosted
    version: "5.0.0"
  flutter_test:
    dependency: "direct dev"
    description: flutter
    source: sdk
    version: "0.0.0"
  frontend_server_client:
    dependency: transitive
    description:
      name: frontend_server_client
      sha256: f64a0333a82f30b0cca061bc3d143813a486dc086b574bfb233b7c1372427694
      url: "https://pub.dev"
    source: hosted
    version: "4.0.0"
  glob:
    dependency: transitive
    description:
      name: glob
      sha256: c3f1ee72c96f8f78935e18aa8cecced9ab132419e8625dc187e1c2408efc20de
      url: "https://pub.dev"
    source: hosted
    version: "2.1.3"
  graphs:
    dependency: transitive
    description:
      name: graphs
      sha256: "741bbf84165310a68ff28fe9e727332eef1407342fca52759cb21ad8177bb8d0"
      url: "https://pub.dev"
    source: hosted
    version: "2.3.2"
  hive:
    dependency: "direct main"
    description:
      name: hive
      sha256: "8dcf6db979d7933da8217edcec84e9df1bdb4e4edc7fc77dbd5aa74356d6d941"
      url: "https://pub.dev"
    source: hosted
    version: "2.2.3"
  hive_flutter:
    dependency: "direct main"
    description:
      name: hive_flutter
      sha256: dca1da446b1d808a51689fb5d0c6c9510c0a2ba01e22805d492c73b68e33eecc
      url: "https://pub.dev"
    source: hosted
    version: "1.1.0"
  hive_generator:
    dependency: "direct dev"
    description:
      name: hive_generator
      sha256: "06cb8f58ace74de61f63500564931f9505368f45f98958bd7a6c35ba24159db4"
      url: "https://pub.dev"
    source: hosted
    version: "2.0.1"
  http:
    dependency: transitive
    description:
      name: http
      sha256: "2c11f3f94c687ee9bad77c171151672986360b2b001d109814ee7140b2cf261b"
      url: "https://pub.dev"
    source: hosted
    version: "1.4.0"
  http_multi_server:
    dependency: transitive
    description:
      name: http_multi_server
      sha256: aa6199f908078bb1c5efb8d8638d4ae191aac11b311132c3ef48ce352fb52ef8
      url: "https://pub.dev"
    source: hosted
    version: "3.2.2"
  http_parser:
    dependency: transitive
    description:
      name: http_parser
      sha256: "178d74305e7866013777bab2c3d8726205dc5a4dd935297175b19a23a2e66571"
      url: "https://pub.dev"
    source: hosted
    version: "4.1.2"
  io:
    dependency: transitive
    description:
      name: io
      sha256: dfd5a80599cf0165756e3181807ed3e77daf6dd4137caaad72d0b7931597650b
      url: "https://pub.dev"
    source: hosted
    version: "1.0.5"
  js:
    dependency: transitive
    description:
      name: js
      sha256: "53385261521cc4a0c4658fd0ad07a7d14591cf8fc33abbceae306ddb974888dc"
      url: "https://pub.dev"
    source: hosted
    version: "0.7.2"
  json_annotation:
    dependency: transitive
    description:
      name: json_annotation
      sha256: "1ce844379ca14835a50d2f019a3099f419082cfdd231cd86a142af94dd5c6bb1"
      url: "https://pub.dev"
    source: hosted
    version: "4.9.0"
  leak_tracker:
    dependency: transitive
    description:
      name: leak_tracker
      sha256: "6bb818ecbdffe216e81182c2f0714a2e62b593f4a4f13098713ff1685dfb6ab0"
      url: "https://pub.dev"
    source: hosted
    version: "10.0.9"
  leak_tracker_flutter_testing:
    dependency: transitive
    description:
      name: leak_tracker_flutter_testing
      sha256: f8b613e7e6a13ec79cfdc0e97638fddb3ab848452eff057653abd3edba760573
      url: "https://pub.dev"
    source: hosted
    version: "3.0.9"
  leak_tracker_testing:
    dependency: transitive
    description:
      name: leak_tracker_testing
      sha256: "6ba465d5d76e67ddf503e1161d1f4a6bc42306f9d66ca1e8f079a47290fb06d3"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.1"
  lints:
    dependency: transitive
    description:
      name: lints
      sha256: c35bb79562d980e9a453fc715854e1ed39e24e7d0297a880ef54e17f9874a9d7
      url: "https://pub.dev"
    source: hosted
    version: "5.1.1"
  logging:
    dependency: transitive
    description:
      name: logging
      sha256: c8245ada5f1717ed44271ed1c26b8ce85ca3228fd2ffdb75468ab01979309d61
      url: "https://pub.dev"
    source: hosted
    version: "1.3.0"
  macros:
    dependency: transitive
    description:
      name: macros
      sha256: "1d9e801cd66f7ea3663c45fc708450db1fa57f988142c64289142c9b7ee80656"
      url: "https://pub.dev"
    source: hosted
    version: "0.1.3-main.0"
  matcher:
    dependency: transitive
    description:
      name: matcher
      sha256: dc58c723c3c24bf8d3e2d3ad3f2f9d7bd9cf43ec6feaa64181775e60190153f2
      url: "https://pub.dev"
    source: hosted
    version: "0.12.17"
  material_color_utilities:
    dependency: transitive
    description:
      name: material_color_utilities
      sha256: f7142bb1154231d7ea5f96bc7bde4bda2a0945d2806bb11670e30b850d56bdec
      url: "https://pub.dev"
    source: hosted
    version: "0.11.1"
  meta:
    dependency: transitive
    description:
      name: meta
      sha256: e3641ec5d63ebf0d9b41bd43201a66e3fc79a65db5f61fc181f04cd27aab950c
      url: "https://pub.dev"
    source: hosted
    version: "1.16.0"
  mime:
    dependency: transitive
    description:
      name: mime
      sha256: "41a20518f0cb1256669420fdba0cd90d21561e560ac240f26ef8322e45bb7ed6"
      url: "https://pub.dev"
    source: hosted
    version: "2.0.0"
  package_config:
    dependency: transitive
    description:
      name: package_config
      sha256: f096c55ebb7deb7e384101542bfba8c52696c1b56fca2eb62827989ef2353bbc
      url: "https://pub.dev"
    source: hosted
    version: "2.2.0"
  path:
    dependency: "direct main"
    description:
      name: path
      sha256: "75cca69d1490965be98c73ceaea117e8a04dd21217b37b292c9ddbec0d955bc5"
      url: "https://pub.dev"
    source: hosted
    version: "1.9.1"
  path_provider:
    dependency: transitive
    description:
      name: path_provider
      sha256: "50c5dd5b6e1aaf6fb3a78b33f6aa3afca52bf903a8a5298f53101fdaee55bbcd"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.5"
  path_provider_android:
    dependency: transitive
    description:
      name: path_provider_android
      sha256: d0d310befe2c8ab9e7f393288ccbb11b60c019c6b5afc21973eeee4dda2b35e9
      url: "https://pub.dev"
    source: hosted
    version: "2.2.17"
  path_provider_foundation:
    dependency: transitive
    description:
      name: path_provider_foundation
      sha256: "4843174df4d288f5e29185bd6e72a6fbdf5a4a4602717eed565497429f179942"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.1"
  path_provider_linux:
    dependency: transitive
    description:
      name: path_provider_linux
      sha256: f7a1fe3a634fe7734c8d3f2766ad746ae2a2884abe22e241a8b301bf5cac3279
      url: "https://pub.dev"
    source: hosted
    version: "2.2.1"
  path_provider_platform_interface:
    dependency: transitive
    description:
      name: path_provider_platform_interface
      sha256: "88f5779f72ba699763fa3a3b06aa4bf6de76c8e5de842cf6f29e2e06476c2334"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.2"
  path_provider_windows:
    dependency: transitive
    description:
      name: path_provider_windows
      sha256: bd6f00dbd873bfb70d0761682da2b3a2c2fccc2b9e84c495821639601d81afe7
      url: "https://pub.dev"
    source: hosted
    version: "2.3.0"
  platform:
    dependency: transitive
    description:
      name: platform
      sha256: "5d6b1b0036a5f331ebc77c850ebc8506cbc1e9416c27e59b439f917a902a4984"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.6"
  plugin_platform_interface:
    dependency: transitive
    description:
      name: plugin_platform_interface
      sha256: "4820fbfdb9478b1ebae27888254d445073732dae3d6ea81f0b7e06d5dedc3f02"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.8"
  pool:
    dependency: transitive
    description:
      name: pool
      sha256: "20fe868b6314b322ea036ba325e6fc0711a22948856475e2c2b6306e8ab39c2a"
      url: "https://pub.dev"
    source: hosted
    version: "1.5.1"
  pub_semver:
    dependency: transitive
    description:
      name: pub_semver
      sha256: "5bfcf68ca79ef689f8990d1160781b4bad40a3bd5e5218ad4076ddb7f4081585"
      url: "https://pub.dev"
    source: hosted
    version: "2.2.0"
  pubspec_parse:
    dependency: transitive
    description:
      name: pubspec_parse
      sha256: "0560ba233314abbed0a48a2956f7f022cce7c3e1e73df540277da7544cad4082"
      url: "https://pub.dev"
    source: hosted
    version: "1.5.0"
  shelf:
    dependency: transitive
    description:
      name: shelf
      sha256: e7dd780a7ffb623c57850b33f43309312fc863fb6aa3d276a754bb299839ef12
      url: "https://pub.dev"
    source: hosted
    version: "1.4.2"
  shelf_web_socket:
    dependency: transitive
    description:
      name: shelf_web_socket
      sha256: "3632775c8e90d6c9712f883e633716432a27758216dfb61bd86a8321c0580925"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.0"
  sky_engine:
    dependency: transitive
    description: flutter
    source: sdk
    version: "0.0.0"
  source_gen:
    dependency: transitive
    description:
      name: source_gen
      sha256: "14658ba5f669685cd3d63701d01b31ea748310f7ab854e471962670abcf57832"
      url: "https://pub.dev"
    source: hosted
    version: "1.5.0"
  source_helper:
    dependency: transitive
    description:
      name: source_helper
      sha256: "86d247119aedce8e63f4751bd9626fc9613255935558447569ad42f9f5b48b3c"
      url: "https://pub.dev"
    source: hosted
    version: "1.3.5"
  source_span:
    dependency: transitive
    description:
      name: source_span
      sha256: "254ee5351d6cb365c859e20ee823c3bb479bf4a293c22d17a9f1bf144ce86f7c"
      url: "https://pub.dev"
    source: hosted
    version: "1.10.1"
  sprintf:
    dependency: transitive
    description:
      name: sprintf
      sha256: "1fc9ffe69d4df602376b52949af107d8f5703b77cda567c4d7d86a0693120f23"
      url: "https://pub.dev"
    source: hosted
    version: "7.0.0"
  stack_trace:
    dependency: transitive
    description:
      name: stack_trace
      sha256: "8b27215b45d22309b5cddda1aa2b19bdfec9df0e765f2de506401c071d38d1b1"
      url: "https://pub.dev"
    source: hosted
    version: "1.12.1"
  stream_channel:
    dependency: transitive
    description:
      name: stream_channel
      sha256: "969e04c80b8bcdf826f8f16579c7b14d780458bd97f56d107d3950fdbeef059d"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.4"
  stream_transform:
    dependency: transitive
    description:
      name: stream_transform
      sha256: ad47125e588cfd37a9a7f86c7d6356dde8dfe89d071d293f80ca9e9273a33871
      url: "https://pub.dev"
    source: hosted
    version: "2.1.1"
  string_scanner:
    dependency: transitive
    description:
      name: string_scanner
      sha256: "921cd31725b72fe181906c6a94d987c78e3b98c2e205b397ea399d4054872b43"
      url: "https://pub.dev"
    source: hosted
    version: "1.4.1"
  term_glyph:
    dependency: transitive
    description:
      name: term_glyph
      sha256: "7f554798625ea768a7518313e58f83891c7f5024f88e46e7182a4558850a4b8e"
      url: "https://pub.dev"
    source: hosted
    version: "1.2.2"
  test_api:
    dependency: transitive
    description:
      name: test_api
      sha256: fb31f383e2ee25fbbfe06b40fe21e1e458d14080e3c67e7ba0acfde4df4e0bbd
      url: "https://pub.dev"
    source: hosted
    version: "0.7.4"
  timing:
    dependency: transitive
    description:
      name: timing
      sha256: "62ee18aca144e4a9f29d212f5a4c6a053be252b895ab14b5821996cff4ed90fe"
      url: "https://pub.dev"
    source: hosted
    version: "1.0.2"
  typed_data:
    dependency: transitive
    description:
      name: typed_data
      sha256: f9049c039ebfeb4cf7a7104a675823cd72dba8297f264b6637062516699fa006
      url: "https://pub.dev"
    source: hosted
    version: "1.4.0"
  uuid:
    dependency: "direct main"
    description:
      name: uuid
      sha256: a5be9ef6618a7ac1e964353ef476418026db906c4facdedaa299b7a2e71690ff
      url: "https://pub.dev"
    source: hosted
    version: "4.5.1"
  vector_math:
    dependency: transitive
    description:
      name: vector_math
      sha256: "80b3257d1492ce4d091729e3a67a60407d227c27241d6927be0130c98e741803"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.4"
  vm_service:
    dependency: transitive
    description:
      name: vm_service
      sha256: ddfa8d30d89985b96407efce8acbdd124701f96741f2d981ca860662f1c0dc02
      url: "https://pub.dev"
    source: hosted
    version: "15.0.0"
  watcher:
    dependency: transitive
    description:
      name: watcher
      sha256: "69da27e49efa56a15f8afe8f4438c4ec02eff0a117df1b22ea4aad194fe1c104"
      url: "https://pub.dev"
    source: hosted
    version: "1.1.1"
  web:
    dependency: transitive
    description:
      name: web
      sha256: "868d88a33d8a87b18ffc05f9f030ba328ffefba92d6c127917a2ba740f9cfe4a"
      url: "https://pub.dev"
    source: hosted
    version: "1.1.1"
  web_socket:
    dependency: transitive
    description:
      name: web_socket
      sha256: "34d64019aa8e36bf9842ac014bb5d2f5586ca73df5e4d9bf5c936975cae6982c"
      url: "https://pub.dev"
    source: hosted
    version: "1.0.1"
  web_socket_channel:
    dependency: transitive
    description:
      name: web_socket_channel
      sha256: d645757fb0f4773d602444000a8131ff5d48c9e47adfe9772652dd1a4f2d45c8
      url: "https://pub.dev"
    source: hosted
    version: "3.0.3"
  xdg_directories:
    dependency: transitive
    description:
      name: xdg_directories
      sha256: "7a3f37b05d989967cdddcbb571f1ea834867ae2faa29725fd085180e0883aa15"
      url: "https://pub.dev"
    source: hosted
    version: "1.1.0"
  yaml:
    dependency: transitive
    description:
      name: yaml
      sha256: b9da305ac7c39faa3f030eccd175340f968459dae4af175130b3fc47e40d76ce
      url: "https://pub.dev"
    source: hosted
    version: "3.1.3"
sdks:
  dart: ">=3.8.0 <4.0.0"
  flutter: ">=3.27.0"

```

## pubspec.yaml

```yaml
name: novelist
description: "An open-source, cross-platform eReader application for a modern reading experience."
# The following line prevents the package from being accidentally published to
# pub.dev using `flutter pub publish`. This is preferred for private packages.
publish_to: 'none' # Remove this line if you wish to publish to pub.dev

# The following defines the version and build number for your application.
# A version number is three numbers separated by dots, like 1.2.43
# followed by an optional build number separated by a +.
# Both the version and the builder number may be overridden in flutter
# build by specifying --build-name and --build-number, respectively.
# In Android, build-name is used as versionName while build-number used as versionCode.
# Read more about Android versioning at https://developer.android.com/studio/publish/versioning
# In iOS, build-name is used as CFBundleShortVersionString while build-number is used as CFBundleVersion.
# Read more about iOS versioning at
# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
# In Windows, build-name is used as the major, minor, and patch parts
# of the product and file versions while build-number is used as the build suffix.
version: 1.0.0+1

environment:
  sdk: ^3.8.0

# Dependencies specify other packages that your package needs in order to work.
# To automatically upgrade your package dependencies to the latest versions
# consider running `flutter pub upgrade --major-versions`. Alternatively,
# dependencies can be manually updated by changing the version numbers below to
# the latest version available on pub.dev. To see which dependencies have newer
# versions available, run `flutter pub outdated`.
dependencies:
  flutter:
    sdk: flutter

  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.8
  uuid: ^4.3.3
  path: ^1.9.0
  hive: ^2.2.3 # Or latest
  hive_flutter: ^1.1.0 # Or latest
  file_picker: ^6.2.1
  path_provider: ^2.1.3
  premission_handler: ^11.3.1
  epubx: ^2.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # The "flutter_lints" package below contains a set of recommended lints to
  # encourage good coding practices. The lint set provided by the package is
  # activated in the `analysis_options.yaml` file located at the root of your
  # package. See that file for information about deactivating specific lint
  # rules and activating additional ones.
  flutter_lints: ^5.0.0
  hive_generator: ^2.0.1 # Or latest
  build_runner: ^2.4.11 # Or latest

# For information on the generic Dart part of this file, see the
# following page: https://dart.dev/tools/pub/pubspec

# The following section is specific to Flutter packages.
flutter:

  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true

  # To add assets to your application, add an assets section, like this:
  # assets:
  #   - images/a_dot_burr.jpeg
  #   - images/a_dot_ham.jpeg

  # An image asset can refer to one or more resolution-specific "variants", see
  # https://flutter.dev/to/resolution-aware-images

  # For details regarding adding assets from package dependencies, see
  # https://flutter.dev/to/asset-from-package

  # To add custom fonts to your application, add a fonts section here,
  # in this "flutter" section. Each entry in this list should have a
  # "family" key with the font family name, and a "fonts" key with a
  # list giving the asset and other descriptors for the font. For
  # example:
  # fonts:
  #   - family: Schyler
  #     fonts:
  #       - asset: fonts/Schyler-Regular.ttf
  #       - asset: fonts/Schyler-Italic.ttf
  #         style: italic
  #   - family: Trajan Pro
  #     fonts:
  #       - asset: fonts/TrajanPro.ttf
  #       - asset: fonts/TrajanPro_Bold.ttf
  #         weight: 700
  #
  # For details regarding fonts from package dependencies,
  # see https://flutter.dev/to/font-from-package

```


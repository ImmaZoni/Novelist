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

  @HiveField(10)
  int? currentChapterIndex; // Index of the current chapter in the book

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
    this.currentChapterIndex
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
      currentChapterIndex: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..writeByte(11)
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
      ..write(obj.lastLocation)
      ..writeByte(10)
      ..write(obj.currentChapterIndex);
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
```

## lib/services/metadata_service.dart

```dart
// lib/services/metadata_service.dart
import 'dart:io'; // Import for File operations
import 'dart:typed_data'; // Import for Uint8List
import 'package:epubx/epubx.dart'; // Or your chosen epub parsing package
import 'package:novelist/models/book.dart';
import 'package:novelist/core/error_handler.dart';

class MetadataService {
  static Future<Map<String, String?>> extractMetadata(String filePath, BookFormat format) async {
    Map<String, String?> metadata = {'title': null, 'author': null, 'coverPath': null};

    if (format == BookFormat.epub) {
      try {
        // 1. Read the file bytes
        File epubFile = File(filePath);
        if (!await epubFile.exists()) {
          ErrorHandler.logWarning("EPUB file not found at path: $filePath", scope: "MetadataService");
          return metadata; // Return empty metadata if file doesn't exist
        }
        Uint8List bytes = await epubFile.readAsBytes();

        // 2. Pass the bytes to EpubReader
        EpubBook epubBook = await EpubReader.readBook(bytes); // Pass bytes, not filePath

        metadata['title'] = epubBook.Title;
        metadata['author'] = epubBook.Author ?? (epubBook.AuthorList?.isNotEmpty == true ? epubBook.AuthorList!.join(', ') : null);

        // TODO: Extract and save cover image if desired
        // if (epubBook.CoverImage != null) {
        //   Uint8List coverBytes = epubBook.CoverImage!;
        //   // 1. Get app's document directory (use path_provider)
        //   // final Directory appDocDir = await getApplicationDocumentsDirectory();
        //   // final String coversDir = p.join(appDocDir.path, 'covers');
        //   // await Directory(coversDir).create(recursive: true);
        //   // 2. Create a unique filename for the cover
        //   // final String coverFileName = '${Uuid().v4()}.png'; // Or determine format from bytes
        //   // final String coverFilePath = p.join(coversDir, coverFileName);
        //   // 3. Save coverBytes to coverFilePath
        //   // await File(coverFilePath).writeAsBytes(coverBytes);
        //   // 4. Store the coverFilePath in metadata
        //   // metadata['coverPath'] = coverFilePath;
        // }

      } catch (e, s) {
        ErrorHandler.recordError(e, s, reason: "Error parsing EPUB metadata for $filePath");
        // Fallback: title might still be derivable from filename if parsing fails completely
        // For example, you could add:
        // if (metadata['title'] == null) {
        //   metadata['title'] = p.basenameWithoutExtension(filePath);
        // }
      }
    } else if (format == BookFormat.pdf) {
      // TODO: PDF metadata extraction (can be complex, may need a dedicated PDF library)
      // For now, as a fallback for PDF and others:
      // metadata['title'] = p.basenameWithoutExtension(filePath);
    } else {
      // For other unknown formats, perhaps just use filename
      // metadata['title'] = p.basenameWithoutExtension(filePath);
    }

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
import 'package:novelist/core/error_handler.dart';
import 'package:novelist/services/metadata_service.dart';

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

      // Example of calling a (yet to be created) metadata service
      Map<String, String?> extractedMeta = await MetadataService.extractMetadata(newFilePath, format);

      String titleFromFile = extractedMeta['title'] ?? p.basenameWithoutExtension(newFilePath);
      String? authorFromFile = extractedMeta['author'];
      String? coverPathFromFile = extractedMeta['coverPath']; // You'll need to implement cover saving in MetadataService for this

      final newBook = Book(
        title: titleFromFile,
        author: authorFromFile,
        filePath: newFilePath,
        format: format,
        coverImagePath: coverPathFromFile, // Populate this
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
            ErrorHandler.recordError(snapshot.error, snapshot.stackTrace, reason: "Failed to load library");
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
                leading: book.coverImagePath != null && book.coverImagePath!.isNotEmpty
                ? Image.file(
                    File(book.coverImagePath!),
                    width: 50, // Adjust size as needed
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if image fails to load
                      return const Icon(Icons.book_online_outlined, size: 40);
                    },
                  )
                : const Icon(Icons.book_online_outlined, size: 40), // Fallback if no cover
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
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:novelist/models/book.dart';
import 'package:novelist/core/error_handler.dart';
import 'package:novelist/services/library_service.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:novelist/core/app_constants.dart';
// import 'package:path/path.dart' as p; // Remove if not used directly in this file

class TocEntry {
  final String title;
  final int chapterIndexForDisplayLogic;
  final int depth;
  final String? targetFile; // Href of the chapter file

  TocEntry({
    required this.title,
    required this.chapterIndexForDisplayLogic,
    this.depth = 0,
    this.targetFile,
  });
}

class ReadingScreen extends StatefulWidget {
  final Book book;

  const ReadingScreen({super.key, required this.book});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final LibraryService _libraryService = LibraryService();
  epubx.EpubBook? _epubBookData;
  String? _currentChapterContent;
  bool _isLoading = true;
  String? _loadingError;

  int _currentChapterIndex = 0;
  double _currentFontSize = 16.0;
  final ScrollController _scrollController = ScrollController();
  List<TocEntry> _tocList = [];

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.book.currentChapterIndex ?? 0;
    _initialLoadEpub();
  }

  @override
  void dispose() {
    _saveReadingProgress();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initialLoadEpub() async {
    // ... (same as previous correct version)
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadingError = null;
    });
    try {
      if (widget.book.format != BookFormat.epub) {
        throw Exception("Unsupported format: ${widget.book.format}");
      }

      File bookFile = File(widget.book.filePath);
      if (!await bookFile.exists()) {
        throw Exception("Book file not found: ${widget.book.filePath}");
      }
      Uint8List bytes = await bookFile.readAsBytes();
      epubx.EpubBook epub = await epubx.EpubReader.readBook(bytes);

      if (!mounted) return;
      setState(() {
        _epubBookData = epub;
        _buildTocList();
      });

      int chapterCount = _getChapterCount();
      if (chapterCount > 0 && _currentChapterIndex >= chapterCount) {
        _currentChapterIndex = 0;
      } else if (chapterCount == 0 && _currentChapterIndex != 0) {
        _currentChapterIndex = 0;
      }
      
      await _displayChapter(_currentChapterIndex, fromInit: true);

    } catch (e, s) {
      ErrorHandler.recordError(e, s, reason: "Failed to load EPUB for ${widget.book.title}");
      if (mounted) {
        setState(() {
          _loadingError = "Error loading book: $e";
          _isLoading = false;
        });
      }
    }
  }

  int _getChapterCount() {
    return _epubBookData?.Schema?.Package?.Spine?.Items?.length ?? 
           _epubBookData?.Chapters?.length ?? 
           0;
  }

  Future<void> _displayChapter(int chapterIndex, {bool fromInit = false}) async {
    // ... (ensure null checks for _epubBookData and its nested properties)
    if (_epubBookData == null || !mounted) return;

    if (!fromInit) {
      await _saveReadingProgress();
    }
    
    if (mounted) {
      setState(() {
        _isLoading = true;
        _currentChapterIndex = chapterIndex;
      });
    }

    String? chapterHtmlContent;
    final spineItems = _epubBookData!.Schema?.Package?.Spine?.Items;

    if (spineItems != null && spineItems.isNotEmpty) {
      if (chapterIndex >= 0 && chapterIndex < spineItems.length) {
        final spineItem = spineItems[chapterIndex];
        final manifestItem = _epubBookData!.Schema?.Package?.Manifest?.Items
            ?.firstWhere((item) => item.Id == spineItem.IdRef,
                orElse: () => epubx.EpubManifestItem()
            );
        
        final String? hrefKey = manifestItem?.Href;
        if (hrefKey != null && 
            _epubBookData!.Content?.Html?.containsKey(hrefKey) == true) {
          chapterHtmlContent = _epubBookData!.Content!.Html![hrefKey]!.Content;
        }
      }
    }

    if (chapterHtmlContent == null) {
      List<epubx.EpubChapter>? chapters = _epubBookData!.Chapters;
      if (chapters != null && chapterIndex >= 0 && chapterIndex < chapters.length) {
        epubx.EpubChapter chapter = chapters[chapterIndex];
        chapterHtmlContent = chapter.HtmlContent;
        if (chapterHtmlContent == null && chapter.ContentFileName != null) {
          final chapterFile = _epubBookData!.Content?.Html?[chapter.ContentFileName!];
          if (chapterFile != null) {
            chapterHtmlContent = chapterFile.Content;
          }
        }
      }
    }
    
    if (!mounted) return;
    if (chapterHtmlContent != null) {
      setState(() {
        _currentChapterContent = chapterHtmlContent;
        _isLoading = false;
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
    } else {
      ErrorHandler.logWarning("Could not load content for chapter index $chapterIndex", scope: "ReadingScreen");
      setState(() {
        _currentChapterContent = "<p>Error: Could not load chapter content for index $chapterIndex.</p>";
        _isLoading = false;
      });
    }
  }

  void _buildTocList() {
    _tocList = [];
    if (_epubBookData == null) return;

    final nav = _epubBookData!.Schema?.Navigation;
    final List<epubx.EpubNavigationMap>? navMaps = nav?.NavMap;

    if (navMaps != null && navMaps.isNotEmpty) {
      // Try to find a navMap with points (usually the first one if it exists)
      epubx.EpubNavigationMap? mainNavMap;
      for (var map in navMaps) {
        if (map.Points.isNotEmpty) {
          mainNavMap = map;
          break;
        }
      }

      if (mainNavMap != null && mainNavMap.Points.isNotEmpty) {
         void addNavPoints(List<epubx.EpubNavigationPoint> points, int depth) {
            for (var point in points) {
              int spineIndex = _findSpineIndexForNavPoint(point);
              if (point.Label != null) {
                 _tocList.add(TocEntry(
                    title: point.Label!,
                    chapterIndexForDisplayLogic: spineIndex, // Can be -1 if not directly in spine
                    depth: depth,
                    targetFile: point.Content?.Source
                  ));
              }
              if (point.ChildNavigationPoints != null && point.ChildNavigationPoints!.isNotEmpty) { // Null check before isNotEmpty
                addNavPoints(point.ChildNavigationPoints!, depth + 1);
              }
            }
         }
        addNavPoints(mainNavMap.Points, 0);
      }
    }
    // Fallback to _epubBookData.Chapters if NavMap is not good or empty
    if (_tocList.isEmpty && _epubBookData!.Chapters?.isNotEmpty == true) {
       for (var i = 0; i < _epubBookData!.Chapters!.length; i++) {
         var chapter = _epubBookData!.Chapters![i];
         if (chapter.Title != null) {
            _tocList.add(TocEntry(
              title: chapter.Title!,
              chapterIndexForDisplayLogic: i, 
              depth: 0, 
              targetFile: chapter.ContentFileName
            ));
         }
       }
    }
  }

  int _findSpineIndexForNavPoint(epubx.EpubNavigationPoint navPoint) {
    final String? targetFile = navPoint.Content?.Source?.split('#').first;
    if (targetFile == null || _epubBookData?.Schema?.Package?.Spine?.Items == null) return -1;

    final spineItems = _epubBookData!.Schema!.Package!.Spine!.Items!; // Safe after null check
    for (var i = 0; i < spineItems.length; i++) {
        final manifestItem = _epubBookData!.Schema?.Package?.Manifest?.Items
            ?.firstWhere((item) => item.Id == spineItems[i].IdRef, orElse: () => epubx.EpubManifestItem());
        if (manifestItem?.Href == targetFile) {
            return i;
        }
    }
    return -1;
  }

  void _goToChapterByTocEntry(TocEntry tocEntry) {
    if (mounted) Navigator.of(context).pop();
    if (_epubBookData == null) return;
    
    if (tocEntry.chapterIndexForDisplayLogic != -1) {
        _displayChapter(tocEntry.chapterIndexForDisplayLogic);
    } else if (tocEntry.targetFile != null) {
        // If chapterIndex was -1, try to find by targetFile again (more robust)
        int foundIndex = -1;
        final spineItems = _epubBookData!.Schema?.Package?.Spine?.Items;
        if (spineItems != null) {
            for (var i = 0; i < spineItems.length; i++) {
                final manifestItem = _epubBookData!.Schema?.Package?.Manifest?.Items
                    ?.firstWhere((item) => item.Id == spineItems[i].IdRef, orElse: () => epubx.EpubManifestItem());
                if (manifestItem?.Href == tocEntry.targetFile) {
                    foundIndex = i;
                    break;
                }
            }
        }
        if (foundIndex != -1) {
            _displayChapter(foundIndex);
        } else {
            ErrorHandler.logWarning("Could not navigate to TOC item by targetFile: ${tocEntry.title}", scope: "ReadingScreen");
            if(mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Could not navigate to chapter: ${tocEntry.title}")),
                );
            }
        }
    } else {
         ErrorHandler.logWarning("Could not navigate to TOC item (no index/target): ${tocEntry.title}", scope: "ReadingScreen");
         if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Could not navigate to chapter: ${tocEntry.title}")),
            );
         }
    }
  }

  // ... ( _goToNextChapter, _goToPreviousChapter, _saveReadingProgress, _changeFontSize, _showTocDialog, _showReaderSettingsDialog are mostly okay, ensure `mounted` checks before UI calls)
  // Make sure they also use _getChapterCount() for consistency.

  void _goToNextChapter() {
    if (_epubBookData == null) return;
    final int chapterCount = _getChapterCount();
    if (chapterCount > 0 && _currentChapterIndex < chapterCount - 1) {
      _displayChapter(_currentChapterIndex + 1);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are at the last chapter.')),
        );
      }
    }
  }

  void _goToPreviousChapter() {
    if (_currentChapterIndex > 0) {
      _displayChapter(_currentChapterIndex - 1);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are at the first chapter.')),
        );
      }
    }
  }

  Future<void> _saveReadingProgress() async {
    if (!mounted) return;
    try {
      Book? bookToUpdate = await _libraryService.getBookById(widget.book.id);
      if (bookToUpdate == null) {
        ErrorHandler.logWarning("Book not found for saving progress: ${widget.book.id}", scope: "ReadingScreen");
        return;
      }

      bookToUpdate.currentChapterIndex = _currentChapterIndex;
      bookToUpdate.lastRead = DateTime.now();
      await _libraryService.updateBook(bookToUpdate);
      ErrorHandler.logInfo("Saved progress for ${widget.book.title}", scope: "ReadingScreen");
    } catch (e,s) {
      ErrorHandler.recordError(e,s, reason: "Failed to save reading progress for ${widget.book.title}");
    }
  }

  void _changeFontSize(double delta) {
    if(mounted) {
      setState(() {
        _currentFontSize = (_currentFontSize + delta).clamp(10.0, 30.0);
      });
    }
  }

  void _showTocDialog() {
    if (_tocList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Table of Contents not available or empty.')),
        );
      }
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return ListView.builder(
              controller: scrollController,
              itemCount: _tocList.length,
              itemBuilder: (context, index) {
                final tocEntry = _tocList[index];
                return ListTile(
                  contentPadding: EdgeInsets.only(left: (tocEntry.depth * 16.0) + 16.0),
                  title: Text(tocEntry.title), // tocEntry.title comes from EpubNavigationPoint.Label or EpubChapter.Title
                  onTap: () => _goToChapterByTocEntry(tocEntry),
                );
              },
            );
          }
        );
      },
    );
  }

 void _showReaderSettingsDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("Font Size", style: Theme.of(context).textTheme.titleMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.remove), onPressed: () => _changeFontSize(-2)),
                  Text(_currentFontSize.toStringAsFixed(0), style: const TextStyle(fontSize: 18)),
                  IconButton(icon: const Icon(Icons.add), onPressed: () => _changeFontSize(2)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = _isLoading ? "Loading..." : (_epubBookData?.Title ?? widget.book.title);
    if (_loadingError != null) appBarTitle = "Error";

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) async { // Corrected signature if needed
        if (didPop && mounted) {
          await _saveReadingProgress();
        }
      },
      // Fallback for older Flutter versions, or if onPopInvokedWithResult isn't the one
      // onPopInvoked: (bool didPop) async { 
      //   if (didPop && mounted) {
      //     await _saveReadingProgress();
      //   }
      // },
      child: Scaffold(
        appBar: AppBar(
          title: Text(appBarTitle, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              icon: const Icon(Icons.list_alt),
              onPressed: (_isLoading || _epubBookData == null) ? null : _showTocDialog,
              tooltip: 'Table of Contents',
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: _isLoading ? null : _showReaderSettingsDialog,
              tooltip: 'Reader Settings',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _isLoading ? null : _goToPreviousChapter,
              tooltip: 'Previous Chapter',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _isLoading ? null : _goToNextChapter,
              tooltip: 'Next Chapter',
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // ... (Same as before, ensure mounted checks for ScaffoldMessenger)
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadingError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Text(_loadingError!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (_currentChapterContent == null) {
      return const Center(child: Text("No content to display for this chapter."));
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Html(
        data: _currentChapterContent!,
        style: {
          "body": Style(
            fontSize: FontSize(_currentFontSize),
            lineHeight: LineHeight.em(1.5),
          ),
          "p": Style(margin: Margins.only(bottom: _currentFontSize * 0.5)),
          "h1": Style(fontSize: FontSize(_currentFontSize * 1.8), fontWeight: FontWeight.bold),
          "h2": Style(fontSize: FontSize(_currentFontSize * 1.5), fontWeight: FontWeight.bold),
          "h3": Style(fontSize: FontSize(_currentFontSize * 1.3), fontWeight: FontWeight.bold),
        },
        onLinkTap: (url, attributes, element) async {
          ErrorHandler.logInfo("Link tapped: $url", scope: "ReadingScreen");
          if (url != null) {
            if (url.startsWith("http://") || url.startsWith("https://")) {
              final uri = Uri.parse(url);
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  throw 'Could not launch $url';
                }
              } catch(e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not launch $url: $e')),
                  );
                }
              }
            } else {
              ErrorHandler.logInfo("Internal link: $url (not yet handled)", scope: "ReadingScreen");
                 if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Internal link navigation not yet implemented: $url')),
                  );
                }
            }
          }
        },
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
  file_picker: ^10.1.9
  path_provider: ^2.1.3
  epubx: ^4.0.0
  permission_handler: ^12.0.0+1
  flutter_html: ^3.0.0
  url_launcher: ^6.3.1

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


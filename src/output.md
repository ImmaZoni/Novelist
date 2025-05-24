# Project Structure

```
analysis_options.yaml
/android
/ios
/lib
- /core
-- app_constants.dart
-- app_routes.dart
-- error_handler.dart
-- /rendering
--- /epub
---- epub_controller.dart
---- epub_document_service.dart
---- epub_viewer_widget.dart
---- toc_entry.dart
--- /pdf
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
  static void recordError(dynamic error, StackTrace? stackTrace, {String? reason, bool fatal = false, String? scope}) { // ADDED scope
    if (kDebugMode) {
      print('-------------------------------- ERROR (${scope ?? 'Global'}) --------------------------------');
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

  static void logInfo(String message, {String? scope}) { // scope was already here, ensure consistency
    if (kDebugMode) {
      print('[INFO${scope != null ? ' - $scope' : ''}] $message');
    }
    // TODO: Optionally log to a file or analytics in production
  }

  static void logWarning(String message, {String? scope}) { // scope was already here, ensure consistency
     if (kDebugMode) {
      print('[WARNING${scope != null ? ' - $scope' : ''}] $message');
    }
    // TODO: Optionally log to a file or analytics in production
  }
}
```

## lib/core/rendering/epub/epub_controller.dart

```dart
// lib/core/rendering/epub/epub_controller.dart
// REMOVE: import 'package:flutter/foundation.dart'; // For ChangeNotifier (already in material.dart)
import 'package:flutter/material.dart'; // For Size and ChangeNotifier
import 'package:novelist/models/book.dart';
import 'package:novelist/core/rendering/epub/epub_document_service.dart';
import 'package:novelist/core/rendering/epub/toc_entry.dart';
import 'package:novelist/core/error_handler.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class EpubController with ChangeNotifier {
  final Book _book;
  final EpubDocumentService _documentService;

  EpubController({required Book book})
      : _book = book,
        _documentService = EpubDocumentService();

  // --- State ---
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _loadingError;
  String? get loadingError => _loadingError;

  int _currentChapterIndex = 0;
  int get currentChapterIndex => _currentChapterIndex;

  double _currentFontSize = 16.0;
  double get currentFontSize => _currentFontSize;

  List<TocEntry> _tocList = [];
  List<TocEntry> get tableOfContents => _tocList;

  String? _bookTitleFromEpub;
  String? get bookTitleFromEpub => _bookTitleFromEpub;

  int _totalChapters = 0;
  int get totalChapters => _totalChapters;

  // --- Pagination State ---
  List<String> _currentChapterPages = [];
  int _currentPageInChapterIndex = 0;
  int get currentPageInChapterIndex => _currentPageInChapterIndex;
  int get totalPagesInCurrentChapter => _currentChapterPages.length;

  // ignore: unused_field // We'll use this later for actual measurement
  Size _screenSize = Size.zero;

  String? get currentVisiblePageContent {
    if (_currentChapterPages.isEmpty || _currentPageInChapterIndex < 0 || _currentPageInChapterIndex >= _currentChapterPages.length) {
      ErrorHandler.logWarning(
          "Attempted to access invalid page: $_currentPageInChapterIndex of ${_currentChapterPages.length} pages.",
          scope: "EpubController");
      return "<p>Error: Page content not available.</p>";
    }
    return _currentChapterPages[_currentPageInChapterIndex];
  }

  Future<void> initialize(Size screenSize) async {
    _isLoading = true;
    _loadingError = null;
    _screenSize = screenSize; // Storing it for later use
    notifyListeners();

    try {
      final success = await _documentService.loadBook(_book.filePath);
      if (success) {
        _bookTitleFromEpub = _documentService.bookTitle ?? _book.title;
        _tocList = _documentService.tableOfContents;
        _totalChapters = _documentService.getChapterCount();
        
        _currentChapterIndex = _book.currentChapterIndex ?? 0;
        if (_totalChapters > 0 && _currentChapterIndex >= _totalChapters) { // ADDED curly braces
          _currentChapterIndex = 0;
        } else if (_totalChapters == 0 && _currentChapterIndex != 0) { // ADDED curly braces
          _currentChapterIndex = 0;
        }

        await _loadAndPaginateChapter(_currentChapterIndex, fromInitializing: true);
      } else {
        _loadingError = "Failed to load EPUB document.";
        _isLoading = false;
      }
    } catch (e, s) {
      ErrorHandler.recordError(e, s, reason: "Error initializing EpubController for ${_book.title}", scope: "EpubController");
      _loadingError = "An unexpected error occurred: $e";
      _isLoading = false;
    } finally {
      if (_loadingError != null) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> _loadAndPaginateChapter(int chapterIndex, {bool fromInitializing = false}) async {
    if (!fromInitializing) {
      _isLoading = true;
      notifyListeners();
    }

    String? chapterHtml = _documentService.getChapterHtmlContent(chapterIndex);
    _currentChapterIndex = chapterIndex;
    _currentPageInChapterIndex = 0; 
    _currentChapterPages = [];

    if (chapterHtml == null || chapterHtml.trim().isEmpty) {
      ErrorHandler.logWarning(
          "Chapter content is null or empty for index $chapterIndex in '${_book.title}'.",
          scope: "EpubController");
      _currentChapterPages.add("<p>Chapter content not available.</p>");
    } else {
      _currentChapterPages = _crudePaginateHtml(chapterHtml, 20); 
      if(_currentChapterPages.isEmpty) {
        _currentChapterPages.add(chapterHtml); 
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }

  List<String> _crudePaginateHtml(String html, int blocksPerPage) {
      if (html.trim().isEmpty) return ["<p></p>"];

      List<String> pages = [];
      var document = html_parser.parseFragment(html);
      List<dom.Node> bodyNodes = document.nodes.toList();
      
      if (bodyNodes.isEmpty) return [html]; 

      StringBuffer currentPageHtml = StringBuffer();
      int blockCount = 0;

      for (var node in bodyNodes) {
          if (node.nodeType == dom.Node.ELEMENT_NODE) {
            dom.Element element = node as dom.Element; // Cast to Element
            currentPageHtml.write(element.outerHtml); // Use outerHtml from Element
            blockCount++;
            if (blockCount >= blocksPerPage) {
                pages.add(currentPageHtml.toString());
                currentPageHtml.clear();
                blockCount = 0;
            }
          } else if (node.nodeType == dom.Node.TEXT_NODE && node.text!.trim().isNotEmpty) {
            currentPageHtml.write("<p>${node.text!.trim()}</p>"); 
            blockCount++;
             if (blockCount >= blocksPerPage) {
                pages.add(currentPageHtml.toString());
                currentPageHtml.clear();
                blockCount = 0;
            }
          } else if (node.nodeType == dom.Node.COMMENT_NODE) {
            // Skip comments or handle if necessary
            // currentPageHtml.write("<!-- ${node.text} -->"); 
          } else {
            // For other node types, decide how to handle.
            // If they have a meaningful string representation, append it.
            // Otherwise, they might be ignored or logged.
            // For now, try to get text content if available, otherwise skip
            if (node.text != null && node.text!.trim().isNotEmpty) {
                 currentPageHtml.write(node.text!.trim());
            }
          }
      }

      if (currentPageHtml.isNotEmpty) {
          pages.add(currentPageHtml.toString());
      }
      if (pages.isEmpty && html.trim().isNotEmpty) { // Ensure fallback if original html was not empty
        pages.add(html); 
      } else if (pages.isEmpty && html.trim().isEmpty) {
        pages.add("<p></p>"); // Add an empty page if everything was empty
      }


      ErrorHandler.logInfo("Crude pagination: Chapter split into ${pages.length} pages.", scope: "EpubController");
      return pages;
  }

  Future<void> nextPage() async {
    if (_currentChapterPages.isEmpty) {
        ErrorHandler.logWarning("Attempted nextPage but current chapter has no pages.", scope: "EpubController");
        return;
    }
    if (_currentPageInChapterIndex < _currentChapterPages.length - 1) {
      _currentPageInChapterIndex++;
      notifyListeners();
    } else {
      if (_currentChapterIndex < _totalChapters - 1) {
        await _loadAndPaginateChapter(_currentChapterIndex + 1);
      } else {
        ErrorHandler.logInfo("Already at the last page of the last chapter.", scope: "EpubController");
      }
    }
  }

  Future<void> previousPage() async {
    if (_currentChapterPages.isEmpty && _currentChapterIndex == 0) {
      ErrorHandler.logWarning("Attempted previousPage but at the very beginning with no pages.", scope: "EpubController");
      return;
    }
    if (_currentPageInChapterIndex > 0) {
      _currentPageInChapterIndex--;
      notifyListeners();
    } else {
      if (_currentChapterIndex > 0) {
        await _loadAndPaginateChapter(_currentChapterIndex - 1);
        _currentPageInChapterIndex = _currentChapterPages.isNotEmpty ? _currentChapterPages.length - 1 : 0;
      } else {
        ErrorHandler.logInfo("Already at the first page of the first chapter.", scope: "EpubController");
      }
    }
    notifyListeners(); 
  }

  Future<void> navigateToChapter(int chapterIndex) async {
    if (chapterIndex >= 0 && chapterIndex < _totalChapters) {
      await _loadAndPaginateChapter(chapterIndex);
    } else {
      ErrorHandler.logWarning(
          "Attempted to navigate to invalid chapter index: $chapterIndex. Total chapters: $_totalChapters.",
          scope: "EpubController");
    }
  }

  Future<void> navigateToTocEntry(TocEntry tocEntry) async {
    int targetChapterIndex = tocEntry.chapterIndexForDisplayLogic;

    if (targetChapterIndex != -1) {
      await navigateToChapter(targetChapterIndex);
    } else if (tocEntry.targetFileHref != null) {
      int foundIndex = -1;
      final epubx.EpubBook? epubData = _documentService.epubBookData;
      final List<epubx.EpubSpineItemRef>? spineItems = epubData?.Schema?.Package?.Spine?.Items;
      
      if (epubData != null && spineItems != null) {
        String targetHref = tocEntry.targetFileHref!.split('#').first;
        for (var i = 0; i < spineItems.length; i++) {
          epubx.EpubManifestItem? manifestItem;
          try {
            manifestItem = epubData.Schema?.Package?.Manifest?.Items
                ?.firstWhere((item) => item.Id == spineItems[i].IdRef);
          } catch (_) { manifestItem = null; }

          if (manifestItem?.Href == targetHref) {
            foundIndex = i;
            break;
          }
        }
      }
      if (foundIndex != -1) {
        await navigateToChapter(foundIndex);
      } else {
         ErrorHandler.logWarning("TOC: Could not find chapter for href ${tocEntry.targetFileHref}", scope: "EpubController");
      }
    } else {
       ErrorHandler.logWarning("TOC: Invalid entry ${tocEntry.title}", scope: "EpubController");
    }
  }
  
  void setFontSize(double size) {
    _currentFontSize = size.clamp(10.0, 30.0);
    ErrorHandler.logInfo("Font size changed. Re-paginating current chapter.", scope: "EpubController");
    if (_totalChapters > 0 && _currentChapterIndex >= 0 && _currentChapterIndex < _totalChapters) {
       _loadAndPaginateChapter(_currentChapterIndex);
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // _documentService.dispose(); // Already called in ReadingScreen dispose if controller is disposed there
    super.dispose();
  }
}
```

## lib/core/rendering/epub/epub_document_service.dart

```dart
// lib/core/rendering/epub/epub_document_service.dart
import 'dart:convert'; // For base64Encode
import 'dart:io';
import 'dart:typed_data';
import 'package:epubx/epubx.dart' as epubx;
import 'package:novelist/core/error_handler.dart';
import 'package:novelist/core/rendering/epub/toc_entry.dart';
import 'package:html/parser.dart' as html_parser; // For parsing HTML
import 'package:html/dom.dart' as dom; // For DOM manipulation
import 'package:path/path.dart' as p; // For path normalization

class EpubDocumentService {
  epubx.EpubBook? _epubBookData;
  List<TocEntry> _tocList = [];
  String? _bookTitle; // Store the title separately after parsing

  // Public getters
  epubx.EpubBook? get epubBookData => _epubBookData;
  List<TocEntry> get tableOfContents => _tocList;
  String? get bookTitle => _bookTitle;

  Future<bool> loadBook(String filePath) async {
    try {
      File bookFile = File(filePath);
      if (!await bookFile.exists()) {
        ErrorHandler.logWarning("EPUB file not found at path: $filePath", scope: "EpubDocumentService");
        return false;
      }
      Uint8List bytes = await bookFile.readAsBytes();
      _epubBookData = await epubx.EpubReader.readBook(bytes);
      _bookTitle = _epubBookData?.Title;

      _buildTocList();
      return true;
    } catch (e, s) {
      ErrorHandler.recordError(e, s, reason: "Failed to load EPUB for $filePath", scope: "EpubDocumentService");
      _epubBookData = null;
      _tocList = [];
      _bookTitle = null;
      return false;
    }
  }

  void _buildTocList() {
    _tocList = [];
    if (_epubBookData == null) return;

    final epubx.EpubNavigation? nav = _epubBookData!.Schema?.Navigation;
    final epubx.EpubNavigationMap? navMap = nav?.NavMap;

    if (navMap != null && navMap.Points != null && navMap.Points!.isNotEmpty) {
      void addNavPointsRecursive(List<epubx.EpubNavigationPoint> points, int depth) {
        for (var point in points) {
          int displayIndex = _findSpineIndexForNavPoint(point);
          String? labelText = (point.NavigationLabels != null && point.NavigationLabels!.isNotEmpty)
              ? point.NavigationLabels!.first.Text
              : null;

          if (labelText != null) {
            _tocList.add(TocEntry(
              title: labelText,
              chapterIndexForDisplayLogic: displayIndex,
              depth: depth,
              targetFileHref: point.Content?.Source,
            ));
          }
          if (point.ChildNavigationPoints != null && point.ChildNavigationPoints!.isNotEmpty) {
            addNavPointsRecursive(point.ChildNavigationPoints!, depth + 1);
          }
        }
      }
      addNavPointsRecursive(navMap.Points!, 0);
    }

    // Fallback to NCX chapters if NAV map TOC is empty or not found
    if (_tocList.isEmpty && _epubBookData!.Chapters?.isNotEmpty == true) {
      ErrorHandler.logInfo("NAV TOC empty or not found, falling back to NCX Chapters for TOC.", scope: "EpubDocumentService");
      for (var i = 0; i < _epubBookData!.Chapters!.length; i++) {
        var chapter = _epubBookData!.Chapters![i];
        if (chapter.Title != null) {
          _tocList.add(TocEntry(
            title: chapter.Title!,
            chapterIndexForDisplayLogic: i,
            depth: 0,
            targetFileHref: chapter.ContentFileName,
          ));
        }
      }
    }
  }

  int _findSpineIndexForNavPoint(epubx.EpubNavigationPoint navPoint) {
    final String? targetFile = navPoint.Content?.Source?.split('#').first;
    if (targetFile == null || _epubBookData == null) return -1;

    final List<epubx.EpubSpineItemRef>? spineItems = _epubBookData!.Schema?.Package?.Spine?.Items;
    if (spineItems == null) return -1;

    for (var i = 0; i < spineItems.length; i++) {
      epubx.EpubManifestItem? manifestItem;
      try {
        manifestItem = _epubBookData!.Schema?.Package?.Manifest?.Items
            ?.firstWhere((item) => item.Id == spineItems[i].IdRef);
      } catch (_) {
        manifestItem = null;
      }
      if (manifestItem?.Href == targetFile) {
        return i;
      }
    }
    return -1;
  }

  int getChapterCount() {
    if (_epubBookData == null) return 0;
    return _epubBookData!.Schema?.Package?.Spine?.Items?.length ??
           _epubBookData!.Chapters?.length ?? 0;
  }

  String? getChapterHtmlContent(int chapterIndex) {
    if (_epubBookData == null || chapterIndex < 0) return null;

    String? rawChapterHtmlContent;
    String? currentChapterFilePath; // To resolve relative image paths

    final List<epubx.EpubSpineItemRef>? spineItems = _epubBookData!.Schema?.Package?.Spine?.Items;

    // Try to get content based on spine (preferred)
    if (spineItems != null && chapterIndex < spineItems.length) {
      final epubx.EpubSpineItemRef spineItem = spineItems[chapterIndex];
      epubx.EpubManifestItem? manifestItem;
      try {
        manifestItem = _epubBookData!.Schema?.Package?.Manifest?.Items
            ?.firstWhere((item) => item.Id == spineItem.IdRef);
      } catch (_) {
        manifestItem = null;
      }

      final String? hrefKey = manifestItem?.Href;
      if (hrefKey != null) {
        currentChapterFilePath = hrefKey; // Store the path of the current HTML file
        if (_epubBookData!.Content?.Html?.containsKey(hrefKey) == true) {
          rawChapterHtmlContent = _epubBookData!.Content!.Html![hrefKey]!.Content;
        }
      }
    }

    // Fallback to legacy Chapters if spine method fails or content is null
    if (rawChapterHtmlContent == null) {
      ErrorHandler.logInfo("Could not get chapter $chapterIndex via spine, trying legacy Chapters.", scope: "EpubDocumentService");
      final List<epubx.EpubChapter>? chapters = _epubBookData!.Chapters;
      if (chapters != null && chapterIndex < chapters.length) {
        final epubx.EpubChapter chapter = chapters[chapterIndex];
        rawChapterHtmlContent = chapter.HtmlContent;
        currentChapterFilePath = chapter.ContentFileName; // Path from legacy chapter
        if (rawChapterHtmlContent == null && chapter.ContentFileName != null) {
          // Try to get content from ContentFileName if HtmlContent is null
          final epubx.EpubTextContentFile? chapterFile = _epubBookData!.Content?.Html?[chapter.ContentFileName!];
          rawChapterHtmlContent = chapterFile?.Content;
        }
      }
    }
    
    if (rawChapterHtmlContent == null) {
      ErrorHandler.logWarning("Raw HTML content is null for chapter index $chapterIndex after all attempts.", scope: "EpubDocumentService");
      return "<p>Error: Could not load chapter content.</p>";
    }

    // Process HTML to embed images as Base64
    String processedHtml = _processHtmlContent(rawChapterHtmlContent, currentChapterFilePath, _epubBookData!);
    
    // For debugging the output (can be removed or commented out)
    // ErrorHandler.logInfo("Processed HTML for chapter $chapterIndex (first 500 chars): ${processedHtml.substring(0, processedHtml.length > 500 ? 500 : processedHtml.length)}", scope: "EpubDocumentService");

    return processedHtml;
  }

  String _processHtmlContent(String htmlContent, String? chapterFilePath, epubx.EpubBook bookData) {
    if (chapterFilePath == null) {
        ErrorHandler.logWarning("Chapter file path is null, cannot process relative image paths.", scope: "EpubDocumentService");
        return htmlContent; 
    }

    var document = html_parser.parse(htmlContent);
    List<dom.Element> imgElements = document.getElementsByTagName('img');
    List<dom.Element> svgImageElements = document.getElementsByTagName('image'); // For <image xlink:href="..."> within <svg>

    // Handle <img> tags
    for (var imgElement in imgElements) {
      String? src = imgElement.attributes['src'];
      _processImageSrc(src, imgElement, chapterFilePath, bookData, 'src');
    }

    // Handle <image xlink:href="..."> tags within SVGs
    for (var svgImageElement in svgImageElements) {
        String? src = svgImageElement.attributes['xlink:href'] ?? svgImageElement.attributes['href']; // Check both
         _processImageSrc(src, svgImageElement, chapterFilePath, bookData, 
            svgImageElement.attributes.containsKey('xlink:href') ? 'xlink:href' : 'href');
    }

    return document.outerHtml;
  }

  void _processImageSrc(String? src, dom.Element imgElement, String chapterFilePath, epubx.EpubBook bookData, String attributeName) {
     if (src != null && !src.startsWith('data:image')) { // Only process if not already a data URI
        try {
          String absoluteImgPath = p.normalize(p.join(p.dirname(chapterFilePath), src));
          
          if (absoluteImgPath.startsWith('/')) {
            absoluteImgPath = absoluteImgPath.substring(1);
          }

          epubx.EpubByteContentFile? imageFile;
          
          if (bookData.Content?.Images?.containsKey(absoluteImgPath) ?? false) {
            imageFile = bookData.Content!.Images![absoluteImgPath];
          } 
          else if (bookData.Content?.AllFiles?.containsKey(absoluteImgPath) ?? false) {
             var file = bookData.Content!.AllFiles![absoluteImgPath];
             if (file is epubx.EpubByteContentFile) {
                imageFile = file;
             }
          }

          if (imageFile != null && imageFile.Content != null) {
            Uint8List imageBytes = Uint8List.fromList(imageFile.Content!); 
            
            String? resolvedMimeType = imageFile.ContentType != null
                ? _epubContentTypeToMimeType(imageFile.ContentType!)
                : _getMimeType(absoluteImgPath);
            
            String base64Image = base64Encode(imageBytes);
            imgElement.attributes[attributeName] = 'data:$resolvedMimeType;base64,$base64Image';
            // ErrorHandler.logInfo("Successfully processed image: $absoluteImgPath -> data URI", scope: "EpubDocumentService");
          } else {
            if (imageFile == null) {
                ErrorHandler.logWarning("Image not found in EPUB content: $src (resolved to: $absoluteImgPath)", scope: "EpubDocumentService");
            } else {
                ErrorHandler.logWarning("Image content is null for: $src (resolved to: $absoluteImgPath)", scope: "EpubDocumentService");
            }
          }
        } catch (e, s) {
          ErrorHandler.recordError(e, s, reason: "Failed to process image with src: $src", scope: "EpubDocumentService");
        }
      }
  }

  String _epubContentTypeToMimeType(epubx.EpubContentType type) {
    switch (type) {
      case epubx.EpubContentType.IMAGE_GIF:
        return 'image/gif';
      case epubx.EpubContentType.IMAGE_JPEG:
        return 'image/jpeg';
      case epubx.EpubContentType.IMAGE_PNG:
        return 'image/png';
      case epubx.EpubContentType.IMAGE_SVG:
        return 'image/svg+xml';
      case epubx.EpubContentType.IMAGE_BMP:
        return 'image/bmp';
      case epubx.EpubContentType.CSS:
      case epubx.EpubContentType.OEB1_CSS:
        return 'text/css';
      case epubx.EpubContentType.XHTML_1_1:
        return 'application/xhtml+xml';
      case epubx.EpubContentType.DTBOOK:
        return 'application/x-dtbook+xml';
      case epubx.EpubContentType.DTBOOK_NCX:
        return 'application/x-dtbncx+xml';
      case epubx.EpubContentType.OEB1_DOCUMENT:
        return 'application/x-oeb1-document';
      case epubx.EpubContentType.XML:
        return 'application/xml';
      case epubx.EpubContentType.FONT_TRUETYPE:
        return 'font/ttf';
      case epubx.EpubContentType.FONT_OPENTYPE:
        return 'font/otf';
      case epubx.EpubContentType.OTHER:
        return 'application/octet-stream';
    }
  }

  String _getMimeType(String filePath) {
    String extension = p.extension(filePath).toLowerCase();
    if (extension == '.jpg' || extension == '.jpeg') return 'image/jpeg';
    if (extension == '.png') return 'image/png';
    if (extension == '.gif') return 'image/gif';
    if (extension == '.svg') return 'image/svg+xml';
    if (extension == '.webp') return 'image/webp';
    return 'application/octet-stream'; // Default MIME type
  }

  void dispose() {
    _epubBookData = null;
    _tocList = [];
    _bookTitle = null;
    ErrorHandler.logInfo("EpubDocumentService disposed.", scope: "EpubDocumentService");
  }
}
```

## lib/core/rendering/epub/epub_viewer_widget.dart

```dart
// lib/core/rendering/epub/epub_viewer_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:novelist/core/app_constants.dart';
import 'package:novelist/core/error_handler.dart';
import 'package:novelist/core/rendering/epub/epub_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class EpubViewerWidget extends StatefulWidget {
  final EpubController controller;
  final ScrollController scrollController; // Pass scroll controller from ReadingScreen

  const EpubViewerWidget({
    super.key,
    required this.controller,
    required this.scrollController,
  });

  @override
  State<EpubViewerWidget> createState() => _EpubViewerWidgetState();
}

class _EpubViewerWidgetState extends State<EpubViewerWidget> {
  @override
  void initState() {
    super.initState();
    // Listen to controller changes to rebuild the widget
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(covariant EpubViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onControllerUpdate);
      widget.controller.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    // This is called when notifyListeners() is called in the controller
    if (mounted) {
      setState(() {
        // The widget will rebuild with new data from the controller
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller; // Convenience

    // Use currentVisiblePageContent instead of currentChapterHtmlContent
    if (controller.isLoading && controller.currentVisiblePageContent == null) {
      // Show loading indicator only if content isn't already available (e.g., initial load)
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.loadingError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Text(
            "Error: ${controller.loadingError}",
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Check currentVisiblePageContent
    if (controller.currentVisiblePageContent == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(kDefaultPadding),
          child: Text("No content to display for this page."), // Updated message
        ),
      );
    }

    return SingleChildScrollView(
      key: ValueKey(controller.currentChapterIndex.toString() + "_" + controller.currentPageInChapterIndex.toString()), // Force rebuild on page/chapter change
      controller: widget.scrollController, // Use the passed ScrollController
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Html(
        data: controller.currentVisiblePageContent!, // Use the paginated content
        style: {
          "body": Style(
            fontSize: FontSize(controller.currentFontSize),
            lineHeight: LineHeight.em(1.5),
          ),
          "p": Style(margin: Margins.only(bottom: controller.currentFontSize * 0.5)),
          "h1": Style(fontSize: FontSize(controller.currentFontSize * 1.8), fontWeight: FontWeight.bold),
          "h2": Style(fontSize: FontSize(controller.currentFontSize * 1.5), fontWeight: FontWeight.bold),
          "h3": Style(fontSize: FontSize(controller.currentFontSize * 1.3), fontWeight: FontWeight.bold),
        },
        onLinkTap: (url, attributes, element) async {
          ErrorHandler.logInfo("Link tapped: $url", scope: "EpubViewerWidget");
          if (url != null) {
            final uri = Uri.tryParse(url);
            if (uri != null && (uri.isScheme("HTTP") || uri.isScheme("HTTPS"))) {
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  throw 'Could not launch $url';
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not launch $url: $e')),
                  );
                }
              }
            } else {
              ErrorHandler.logInfo("Internal EPUB link tapped: $url. Navigation not yet implemented.", scope: "EpubViewerWidget");
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

## lib/core/rendering/epub/toc_entry.dart

```dart
class TocEntry {
  final String title;
  final int chapterIndexForDisplayLogic; // Index for direct navigation if known
  final int depth;
  final String? targetFileHref; // Actual href, e.g., "chapter1.xhtml#section2"

  TocEntry({
    required this.title,
    required this.chapterIndexForDisplayLogic,
    this.depth = 0,
    this.targetFileHref,
  });
}
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
import 'package:flutter/material.dart';
import 'package:novelist/models/book.dart';
import 'package:novelist/services/library_service.dart';
import 'package:novelist/core/error_handler.dart';
import 'package:novelist/core/app_constants.dart';
import 'package:novelist/core/rendering/epub/epub_controller.dart';
import 'package:novelist/core/rendering/epub/epub_viewer_widget.dart';
import 'package:novelist/core/rendering/epub/toc_entry.dart';

class ReadingScreen extends StatefulWidget {
  final Book book;
  const ReadingScreen({super.key, required this.book});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final LibraryService _libraryService = LibraryService();
  late final EpubController _epubController;

  final ScrollController _scrollController = ScrollController();

  bool _isInitialized = false;
  bool _readerInitializing = false; // To prevent multiple init calls in didChangeDependencies

  @override
  void initState() {
    super.initState();
    if (widget.book.format == BookFormat.epub) {
      _epubController = EpubController(book: widget.book);
      // Initialization will be triggered by didChangeDependencies
    } else {
      // Log error for unsupported formats, _isInitialized will remain false
      ErrorHandler.logWarning(
          "Unsupported book format in ReadingScreen: ${widget.book.format}",
          scope: "ReadingScreen");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize reader here, as MediaQuery is available and we need screen size for pagination
    if (widget.book.format == BookFormat.epub && !_isInitialized && !_readerInitializing) {
      _readerInitializing = true; 
      // Ensure context is available for MediaQuery
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { // Check if still mounted after the frame
            final screenSize = MediaQuery.of(context).size;
            _initializeReader(screenSize).then((_) {
                if (mounted) {
                    setState(() { _readerInitializing = false; });
                }
            });
        } else {
             _readerInitializing = false; // Reset if not mounted
        }
      });
    }
  }

  Future<void> _initializeReader(Size screenSize) async {
    if (widget.book.format == BookFormat.epub) {
      _epubController.addListener(_onReaderControllerUpdate);
      await _epubController.initialize(screenSize); // Pass screenSize
    }
    // For other formats, you'd initialize their controllers here

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
    }
  }

  void _onReaderControllerUpdate() {
    if (mounted) {
      setState(() {
        // Rebuilds ReadingScreen if needed, e.g., for AppBar title or page numbers
      });
    }
  }

  @override
  void dispose() {
    if (widget.book.format == BookFormat.epub && _isInitialized) { // only if initialized
      _epubController.removeListener(_onReaderControllerUpdate);
      _saveReadingProgress(); 
      _epubController.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveReadingProgress() async {
    if (!_isInitialized || widget.book.format != BookFormat.epub) return;

    try {
      Book? bookToUpdate = await _libraryService.getBookById(widget.book.id);
      if (bookToUpdate == null) {
        ErrorHandler.logWarning("Book not found for saving progress: ${widget.book.id}", scope: "ReadingScreen");
        return;
      }
      bookToUpdate.currentChapterIndex = _epubController.currentChapterIndex;
      // TODO: Consider saving _epubController.currentPageInChapterIndex if persistent sub-chapter progress is desired
      bookToUpdate.lastRead = DateTime.now();
      await _libraryService.updateBook(bookToUpdate);
      ErrorHandler.logInfo(
          "Saved progress for ${widget.book.title} (Chapter: ${_epubController.currentChapterIndex}, Page in Chapter: ${_epubController.currentPageInChapterIndex})",
          scope: "ReadingScreen");
    } catch (e, s) {
      ErrorHandler.recordError(e, s, reason: "Failed to save reading progress for ${widget.book.title}", scope: "ReadingScreen");
    }
  }

  void _showTocDialog() {
    if (widget.book.format != BookFormat.epub || !_isInitialized || _epubController.tableOfContents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Table of Contents not available or empty.')),
      );
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
              itemCount: _epubController.tableOfContents.length,
              itemBuilder: (context, index) {
                final TocEntry tocEntry = _epubController.tableOfContents[index];
                bool isCurrentChapter = _epubController.currentChapterIndex == tocEntry.chapterIndexForDisplayLogic && tocEntry.chapterIndexForDisplayLogic != -1;
                return ListTile(
                  contentPadding: EdgeInsets.only(left: (tocEntry.depth * kSmallPadding) + kDefaultPadding, right: kDefaultPadding),
                  title: Text(
                    tocEntry.title,
                    style: TextStyle(fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.normal),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _epubController.navigateToTocEntry(tocEntry).then((_) {
                      if (_scrollController.hasClients) _scrollController.jumpTo(0);
                    });
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _showReaderSettingsDialog() {
    if (widget.book.format != BookFormat.epub || !_isInitialized) return;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("Font Size", style: Theme.of(context).textTheme.titleMedium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          _epubController.setFontSize(_epubController.currentFontSize - 2);
                          // The listener in _EpubViewerWidgetState and _ReadingScreenState will trigger UI updates.
                        },
                      ),
                      Text(
                        _epubController.currentFontSize.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                           _epubController.setFontSize(_epubController.currentFontSize + 2);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: kDefaultPadding),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = widget.book.title;
    String pageInfo = "";

    if (_isInitialized && widget.book.format == BookFormat.epub) {
      appBarTitle = _epubController.bookTitleFromEpub ?? widget.book.title;
      if (_epubController.loadingError != null) {
        appBarTitle = "Error Loading Book";
      } else if (!_epubController.isLoading) {
         pageInfo = " (Page ${_epubController.currentPageInChapterIndex + 1} of ${_epubController.totalPagesInCurrentChapter})";
      }
    } else if (widget.book.format == BookFormat.epub && _readerInitializing) { // Show loading if reader is init
        appBarTitle = "Loading...";
    }


    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          await _saveReadingProgress();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(appBarTitle, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)),
              if (_isInitialized && widget.book.format == BookFormat.epub && !_epubController.isLoading && pageInfo.isNotEmpty)
                Text(pageInfo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
            ],
          ),
          actions: _buildAppBarActions(),
        ),
        body: _buildReaderBody(),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (widget.book.format != BookFormat.epub || !_isInitialized) {
      // Show a loading indicator in actions if initializing
      if (widget.book.format == BookFormat.epub && _readerInitializing) {
        return [const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))];
      }
      return []; 
    }

    return [
      IconButton(
        icon: const Icon(Icons.list_alt),
        onPressed: _showTocDialog,
        tooltip: 'Table of Contents',
      ),
      IconButton(
        icon: const Icon(Icons.tune),
        onPressed: _showReaderSettingsDialog,
        tooltip: 'Reader Settings',
      ),
      IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () => _epubController.previousPage().then((_) {
          if (_scrollController.hasClients) _scrollController.jumpTo(0);
        }),
        tooltip: 'Previous Page',
      ),
      IconButton(
        icon: const Icon(Icons.arrow_forward_ios),
        onPressed: () => _epubController.nextPage().then((_) {
          if (_scrollController.hasClients) _scrollController.jumpTo(0);
        }),
        tooltip: 'Next Page',
      ),
    ];
  }

  Widget _buildReaderBody() {
    if (widget.book.format != BookFormat.epub) {
      return Center( /* ... unsupported format message ... */ );
    }
    
    // If not yet initialized and it's an EPUB, show loading.
    // _readerInitializing handles the very first loading phase.
    // _isInitialized handles subsequent states.
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Once initialized, EpubViewerWidget handles its own internal loading/error based on controller state.
    return EpubViewerWidget(
        controller: _epubController,
        scrollController: _scrollController,
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
  html: ^0.15.6
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


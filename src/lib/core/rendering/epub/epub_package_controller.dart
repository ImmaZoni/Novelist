// lib/core/rendering/epub/epub_package_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:novelist/models/book.dart' as app_book; // Aliasing to avoid conflict
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart'; // Package components
import 'package:novelist/core/error_handler.dart';
// We don't need our own TocEntry as the package provides EpubChapter

class EpubPackageController with ChangeNotifier {
  final app_book.Book _appBook; // Our application's Book model
  final EpubController packageController; // Controller from flutter_epub_viewer

  EpubPackageController({required app_book.Book appBook})
      : _appBook = appBook,
        packageController = EpubController(); // Initialize the package's controller

  // --- State ---
  bool _isLoading = true; // Tracks initial loading of the book by the viewer
  bool get isLoading => _isLoading;

  String? _loadingError;
  String? get loadingError => _loadingError;

  List<EpubChapter> _tocChapters = [];
  List<EpubChapter> get tableOfContents => _tocChapters;

  String _bookTitleFromEpub = ""; // Title from EPUB metadata
  String get bookTitleFromEpub => _bookTitleFromEpub.isNotEmpty ? _bookTitleFromEpub : _appBook.title;
  
  // Current reading location (CFI) - might be updated by onRelocated callback
  String? _currentCfiLocation;
  String? get currentCfiLocation => _currentCfiLocation;

  // Font size - we manage this so we can persist it and apply it
  double _currentFontSize = 16.0;
  double get currentFontSize => _currentFontSize;

  // Theme - similar to font size
  // EpubTheme _currentTheme = EpubTheme.light(); // Example
  // EpubTheme get currentTheme => _currentTheme;

  // --- Initialization and Callbacks for EpubViewer ---
  EpubSource get epubSource => EpubSource.fromFile(File(_appBook.filePath));
  String? get initialCfi => _appBook.lastLocation; // Use our saved CFI

  void onEpubLoaded() {
    ErrorHandler.logInfo("EpubPackageController: EPUB loaded for ${_appBook.title}", scope: "EpubPackageController");
    _isLoading = false;
    
    // Fetch title from actual book if available
    // The package itself doesn't directly expose the book title via its controller easily.
    // We can rely on our MetadataService for this, or try to parse it if needed,
    // but for now, the app_book.title is a good default.
    // If Epub.js has a way to get it via JS eval, that's an option for later.

    // Attempt to parse chapters once loaded
    packageController.parseChapters().then((chapters) {
      _tocChapters = chapters;
      notifyListeners(); // Notify listeners that TOC might be ready
    }).catchError((e, s) {
      ErrorHandler.recordError(e, s, reason: "Failed to parse chapters", scope: "EpubPackageController");
    });

    // Apply initial font size (could be loaded from user settings)
    // TODO: Load _currentFontSize from a settings service
    packageController.setFontSize(fontSize: _currentFontSize);
    
    // Apply initial theme
    // TODO: Load theme from settings and apply
    // packageController.updateTheme(theme: _currentTheme);

    notifyListeners();
  }

  void onChaptersLoaded(List<EpubChapter> chapters) {
    ErrorHandler.logInfo("EpubPackageController: Chapters loaded (${chapters.length})", scope: "EpubPackageController");
    _tocChapters = chapters;
    notifyListeners();
  }

  void onRelocated(EpubLocation location) {
    _currentCfiLocation = location.startCfi;
    // ErrorHandler.logInfo("EpubPackageController: Relocated to ${location.startCfi}, progress: ${location.progress}", scope: "EpubPackageController");
    // Persist this location via a method call if needed immediately, or rely on _saveReadingProgress in ReadingScreen
    notifyListeners(); // If any UI depends on the current location
  }

  // --- Actions ---
  void nextPage() {
    try {
      packageController.next();
    } catch (e) { ErrorHandler.logWarning("Error on nextPage: $e", scope: "EpubPackageController"); }
  }

  void previousPage() {
     try {
      packageController.prev();
    } catch (e) { ErrorHandler.logWarning("Error on prevPage: $e", scope: "EpubPackageController"); }
  }

  void navigateToCfi(String cfi) {
     try {
      packageController.display(cfi: cfi);
    } catch (e) { ErrorHandler.logWarning("Error on navigateToCfi ($cfi): $e", scope: "EpubPackageController"); }
  }

  void setFontSize(double size) {
    _currentFontSize = size.clamp(10.0, 30.0);
    try {
      packageController.setFontSize(fontSize: _currentFontSize);
    } catch (e) { ErrorHandler.logWarning("Error on setFontSize: $e", scope: "EpubPackageController"); }
    notifyListeners();
    // TODO: Persist font size choice
    // ConfigService.setReaderConfig("fontSize", _currentFontSize.toString());
  }

  void updateTheme(EpubTheme theme) {
    // _currentTheme = theme;
    try {
      packageController.updateTheme(theme: theme);
    } catch (e) { ErrorHandler.logWarning("Error on updateTheme: $e", scope: "EpubPackageController"); }
    notifyListeners();
    // TODO: Persist theme choice
  }
  
  // Method to get current location for saving
  Future<EpubLocation?> getCurrentViewerLocation() async {
    try {
      return await packageController.getCurrentLocation();
    } catch (e) {
      ErrorHandler.logWarning("Error getting current location: $e", scope: "EpubPackageController");
      return null;
    }
  }


  @override
  void dispose() {
    // The flutter_epub_viewer's EpubController doesn't have a public dispose method.
    // Its InAppWebViewController is disposed when the EpubViewer widget is disposed.
    ErrorHandler.logInfo("EpubPackageController disposed for ${_appBook.title}", scope: "EpubPackageController");
    super.dispose();
  }
}
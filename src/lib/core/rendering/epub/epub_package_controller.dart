// lib/core/rendering/epub/epub_package_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:novelist/models/book.dart' as app_book;
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:novelist/core/error_handler.dart';
import 'package:novelist/services/settings_service.dart'; // Import SettingsService

class EpubPackageController with ChangeNotifier {
  final app_book.Book _appBook;
  final EpubController packageController; // Controller from flutter_epub_viewer
  final SettingsService _settingsService = SettingsService(); // Instance of SettingsService

  // --- State ---
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _loadingError;
  String? get loadingError => _loadingError;

  List<EpubChapter> _tocChapters = [];
  List<EpubChapter> get tableOfContents => _tocChapters;

  String _bookTitleFromEpub = "";
  String get bookTitleFromEpub => _bookTitleFromEpub.isNotEmpty ? _bookTitleFromEpub : _appBook.title;
  
  String? _currentCfiLocation;
  String? get currentCfiLocation => _currentCfiLocation;

  double _currentFontSize = 16.0; // Default, will be overridden by loaded settings
  double get currentFontSize => _currentFontSize;

  ReaderThemeSetting _currentReaderThemeSetting = ReaderThemeSetting.system; // Default
  ReaderThemeSetting get currentReaderThemeSetting => _currentReaderThemeSetting;


  EpubPackageController({required app_book.Book appBook})
      : _appBook = appBook,
        packageController = EpubController() {
    _loadDefaultSettings(); 
  }

  Future<void> _loadDefaultSettings() async {
    _currentFontSize = await _settingsService.getDefaultFontSize();
    _currentReaderThemeSetting = await _settingsService.getReaderTheme();
    // Initial application of theme and font size will happen in onEpubLoaded
    // or can be triggered here if packageController is ready, but onEpubLoaded is safer.
    notifyListeners(); // Notify for initial font size if UI uses it before EPUB load
  }
  
  void _applyCurrentThemeToViewer() {
    EpubTheme themeToApply;
    switch (_currentReaderThemeSetting) {
      case ReaderThemeSetting.light:
        themeToApply = EpubTheme.light();
        break;
      case ReaderThemeSetting.dark:
        themeToApply = EpubTheme.dark();
        break;
      case ReaderThemeSetting.sepia:
        themeToApply = EpubTheme.custom(
          backgroundColor: const Color(0xFFFBF0D9), 
          foregroundColor: const Color(0xFF5B4636)
        );
        break;
      case ReaderThemeSetting.system:
      default:
        // Check platform brightness. Note: This won't auto-update if system theme changes while app is running
        // unless we add a listener for platform brightness changes.
        final Brightness platformBrightness = 
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        themeToApply = platformBrightness == Brightness.dark ? EpubTheme.dark() : EpubTheme.light();
        break;
    }
    try {
      packageController.updateTheme(theme: themeToApply);
      ErrorHandler.logInfo("Applied reader theme: ${_currentReaderThemeSetting.name}", scope: "EpubPackageController");
    } catch(e, s) {
       ErrorHandler.recordError(e, s, reason: "Error applying theme in controller", scope:"EpubPackageController");
    }
  }

  // --- Callbacks for EpubViewer ---
  EpubSource get epubSource => EpubSource.fromFile(File(_appBook.filePath));
  String? get initialCfi => _appBook.lastLocation;

  void onEpubLoaded() {
    ErrorHandler.logInfo("EpubPackageController: EPUB loaded for ${_appBook.title}", scope: "EpubPackageController");
    _isLoading = false; // Set loading to false
    
    packageController.parseChapters().then((chapters) {
      _tocChapters = chapters;
      notifyListeners();
    }).catchError((e, s) {
      ErrorHandler.recordError(e, s, reason: "Failed to parse chapters on load", scope: "EpubPackageController");
    });

    try {
      packageController.setFontSize(fontSize: _currentFontSize);
      ErrorHandler.logInfo("Applied initial font size: $_currentFontSize", scope: "EpubPackageController");
    } catch (e,s) { 
      ErrorHandler.recordError(e, s, reason: "Error setting initial font size", scope:"EpubPackageController");
    }
    
    _applyCurrentThemeToViewer(); // Apply the loaded/default theme

    notifyListeners();
  }

  void onChaptersLoaded(List<EpubChapter> chapters) {
    ErrorHandler.logInfo("EpubPackageController: Chapters loaded (${chapters.length})", scope: "EpubPackageController");
    _tocChapters = chapters;
    notifyListeners();
  }

  void onRelocated(EpubLocation location) {
    _currentCfiLocation = location.startCfi;
    notifyListeners();
  }

  // --- Actions ---
  void nextPage() {
    try { packageController.next(); } 
    catch (e) { ErrorHandler.logWarning("Error on nextPage: $e", scope: "EpubPackageController"); }
  }

  void previousPage() {
     try { packageController.prev(); } 
     catch (e) { ErrorHandler.logWarning("Error on prevPage: $e", scope: "EpubPackageController"); }
  }

  void navigateToCfi(String cfi) {
     try { packageController.display(cfi: cfi); } 
     catch (e) { ErrorHandler.logWarning("Error on navigateToCfi ($cfi): $e", scope: "EpubPackageController"); }
  }

  Future<void> setFontSize(double size) async { // Make async if saving is async
    _currentFontSize = size.clamp(10.0, 30.0);
    try {
      packageController.setFontSize(fontSize: _currentFontSize);
    } catch (e) { ErrorHandler.logWarning("Error on setFontSize: $e", scope: "EpubPackageController"); }
    
    await _settingsService.saveDefaultFontSize(_currentFontSize); 
    notifyListeners();
  }

  Future<void> setReaderTheme(ReaderThemeSetting themeSetting) async { // Make async
    _currentReaderThemeSetting = themeSetting;
    _applyCurrentThemeToViewer(); // Apply it immediately to the viewer
    await _settingsService.saveReaderTheme(themeSetting); // Save the choice
    notifyListeners();
  }
  
  Future<EpubLocation?> getCurrentViewerLocation() async {
    try {
      return await packageController.getCurrentLocation();
    } catch (e,s) {
      ErrorHandler.recordError(e,s, reason: "Error getting current location", scope: "EpubPackageController");
      return null;
    }
  }

  @override
  void dispose() {
    ErrorHandler.logInfo("EpubPackageController disposed for ${_appBook.title}", scope: "EpubPackageController");
    // packageController from flutter_epub_viewer does not have a public dispose method.
    // It relies on its InAppWebViewController being disposed by the EpubViewer widget.
    super.dispose();
  }
}
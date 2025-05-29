// lib/core/rendering/epub/epub_package_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:novelist/models/book.dart' as app_book;
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:novelist/core/error_handler.dart';
import 'package:novelist/services/settings_service.dart';

class EpubPackageController with ChangeNotifier {
  final app_book.Book _appBook;
  final EpubController packageController;
  final SettingsService _settingsService = SettingsService();

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

  double _currentFontSize = 16.0;
  double get currentFontSize => _currentFontSize;

  ReaderThemeSetting _currentReaderThemeSetting = ReaderThemeSetting.system;
  ReaderThemeSetting get currentReaderThemeSetting => _currentReaderThemeSetting;

  String _currentReaderFontFamily = 'Default';
  String get currentReaderFontFamily => _currentReaderFontFamily;

  EpubPackageController({required app_book.Book appBook})
      : _appBook = appBook,
        packageController = EpubController() {
    _loadDefaultSettings();
  }

  Future<void> _loadDefaultSettings() async {
    _currentFontSize = await _settingsService.getDefaultFontSize();
    _currentReaderThemeSetting = await _settingsService.getReaderTheme();
    _currentReaderFontFamily = await _settingsService.getReaderFontFamily();
    notifyListeners(); 
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
        final Brightness platformBrightness = 
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        themeToApply = platformBrightness == Brightness.dark ? EpubTheme.dark() : EpubTheme.light();
        break;
    }
    try {
      if (packageController.webViewController != null) { // Check if controller is ready
        packageController.updateTheme(theme: themeToApply);
        ErrorHandler.logInfo("Applied reader theme: ${_currentReaderThemeSetting.name}", scope: "EpubPackageController");
      } else {
         ErrorHandler.logWarning("WebViewController not ready for theme update.", scope: "EpubPackageController");
      }
    } catch(e, s) {
       ErrorHandler.recordError(e, s, reason: "Error applying theme in controller", scope:"EpubPackageController");
    }
  }

  Future<void> _applyCurrentFontFamilyToViewer() async {
    if (packageController.webViewController == null) {
      ErrorHandler.logWarning("WebViewController not ready, cannot apply font family.", scope: "EpubPackageController");
      return;
    }
    
    String jsCommand;
    if (_currentReaderFontFamily == 'Default' || _currentReaderFontFamily.isEmpty) {
      // To reset to default, Epub.js usually reapplies theme styles or accepts an empty string.
      // Passing an empty string or 'inherit' might work.
      jsCommand = "window.rendition.themes.font('');"; // Or 'inherit'
      ErrorHandler.logInfo("Applying default font family.", scope: "EpubPackageController");
    } else {
      jsCommand = "window.rendition.themes.font('$_currentReaderFontFamily');";
    }
    
    try {
      await packageController.webViewController!.evaluateJavascript(source: jsCommand);
      ErrorHandler.logInfo("Applied font family: $_currentReaderFontFamily via JS: $jsCommand", scope: "EpubPackageController");
    } catch (e,s) {
      ErrorHandler.recordError(e, s, reason: "Error applying font family '$_currentReaderFontFamily'", scope: "EpubPackageController");
    }
  }

  EpubSource get epubSource => EpubSource.fromFile(File(_appBook.filePath));
  String? get initialCfi => _appBook.lastLocation;

  void onEpubLoaded() {
    ErrorHandler.logInfo("EpubPackageController: EPUB loaded for ${_appBook.title}", scope: "EpubPackageController");
    
    packageController.parseChapters().then((chapters) {
      _tocChapters = chapters;
      notifyListeners();
    }).catchError((e, s) { 
      ErrorHandler.recordError(e, s, reason: "Failed to parse chapters on load", scope: "EpubPackageController");
    });

    // Apply settings now that viewer is confirmed ready
    try {
      packageController.setFontSize(fontSize: _currentFontSize);
      ErrorHandler.logInfo("Applied initial font size: $_currentFontSize", scope: "EpubPackageController");
    } catch (e,s) { 
      ErrorHandler.recordError(e, s, reason: "Error setting initial font size", scope:"EpubPackageController");
    }
    
    _applyCurrentThemeToViewer();
    _applyCurrentFontFamilyToViewer().then((_) {
      // Set isLoading to false after all initial settings are attempted
       _isLoading = false;
       notifyListeners();
    });
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

  Future<void> setFontSize(double size) async {
    double newFontSize = size.clamp(10.0, 30.0);
    if (newFontSize == _currentFontSize) return;

    _currentFontSize = newFontSize;
    if (packageController.webViewController != null) {
      try {
        await packageController.setFontSize(fontSize: _currentFontSize);
      } catch (e) { ErrorHandler.logWarning("Error on setFontSize: $e", scope: "EpubPackageController"); }
    }
    await _settingsService.saveDefaultFontSize(_currentFontSize); 
    notifyListeners();
  }

  Future<void> setReaderTheme(ReaderThemeSetting themeSetting) async {
    if (themeSetting == _currentReaderThemeSetting) return;
    _currentReaderThemeSetting = themeSetting;
    if (packageController.webViewController != null) {
      _applyCurrentThemeToViewer();
    }
    await _settingsService.saveReaderTheme(themeSetting);
    notifyListeners();
  }

  Future<void> setReaderFontFamily(String fontFamily) async {
    if (fontFamily == _currentReaderFontFamily) return;
    _currentReaderFontFamily = fontFamily;
    if (packageController.webViewController != null) {
      await _applyCurrentFontFamilyToViewer();
    }
    await _settingsService.saveReaderFontFamily(_currentReaderFontFamily);
    notifyListeners();
  }
  
  Future<EpubLocation?> getCurrentViewerLocation() async {
    if (packageController.webViewController == null) return null;
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
    super.dispose();
  }
}
// lib/core/rendering/epub/epub_controller.dart
import 'package:flutter/foundation.dart'; // For ChangeNotifier
import 'package:novelist/models/book.dart';
import 'package:novelist/core/rendering/epub/epub_document_service.dart';
import 'package:novelist/core/rendering/epub/toc_entry.dart';
import 'package:novelist/core/error_handler.dart';
import 'package:epubx/epubx.dart' as epubx;

class EpubController with ChangeNotifier {
  final Book _book; // The book object passed from ReadingScreen
  final EpubDocumentService _documentService;

  EpubController({required Book book})
      : _book = book,
        _documentService = EpubDocumentService();

  // --- State ---
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _loadingError;
  String? get loadingError => _loadingError;

  String? _currentChapterHtmlContent;
  String? get currentChapterHtmlContent => _currentChapterHtmlContent;

  int _currentChapterIndex = 0;
  int get currentChapterIndex => _currentChapterIndex;

  double _currentFontSize = 16.0; // Default font size
  double get currentFontSize => _currentFontSize;

  List<TocEntry> _tocList = [];
  List<TocEntry> get tableOfContents => _tocList;

  String? _bookTitleFromEpub;
  String? get bookTitleFromEpub => _bookTitleFromEpub;

  int _totalChapters = 0;
  int get totalChapters => _totalChapters;

  // --- Initialization ---
  Future<void> initialize() async {
    _isLoading = true;
    _loadingError = null;
    notifyListeners();

    try {
      final success = await _documentService.loadBook(_book.filePath);
      if (success) {
        _bookTitleFromEpub = _documentService.bookTitle ?? _book.title; // Fallback to book model title
        _tocList = _documentService.tableOfContents;
        _totalChapters = _documentService.getChapterCount();
        
        // Load last read chapter index or default to 0
        _currentChapterIndex = _book.currentChapterIndex ?? 0;
        if (_totalChapters > 0 && _currentChapterIndex >= _totalChapters) {
            ErrorHandler.logWarning(
                "Saved chapter index $_currentChapterIndex out of bounds for book with $_totalChapters chapters. Resetting to 0.",
                scope: "EpubController"
            );
            _currentChapterIndex = 0;
        } else if (_totalChapters == 0 && _currentChapterIndex != 0) {
            ErrorHandler.logWarning(
                "Book has 0 chapters but saved index is $_currentChapterIndex. Resetting to 0.",
                scope: "EpubController"
            );
            _currentChapterIndex = 0;
        }

        await _loadChapter(_currentChapterIndex, isInitializing: true);
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
        _isLoading = false; // Ensure loading is false if an error occurred during loading process
      }
      notifyListeners();
    }
  }

  // --- Chapter Loading and Navigation ---
  Future<void> _loadChapter(int chapterIndex, {bool isInitializing = false}) async {
    if (!isInitializing) { // Don't set loading true if just initializing and chapter load is part of it
      _isLoading = true;
      notifyListeners();
    }

    _currentChapterHtmlContent = _documentService.getChapterHtmlContent(chapterIndex);
    _currentChapterIndex = chapterIndex; // Update the index

    if (_currentChapterHtmlContent == null) {
      ErrorHandler.logWarning(
          "Chapter content is null for index $chapterIndex in '${_book.title}'. Total chapters: $_totalChapters.",
          scope: "EpubController");
      _currentChapterHtmlContent = "<p>Error: Could not load chapter content.</p>";
      // Potentially set _loadingError here too if this is a critical failure
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> navigateToChapter(int chapterIndex) async {
    if (chapterIndex >= 0 && chapterIndex < _totalChapters) {
      await _loadChapter(chapterIndex);
      // Note: Saving progress will be handled by ReadingScreen or a dedicated service when needed
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
      // This logic attempts to find a spine index based on href if chapterIndexForDisplayLogic was -1
      // This might be redundant if _findSpineIndexForNavPoint in EpubDocumentService is robust
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
        ErrorHandler.logWarning(
            "Could not navigate to TOC entry by targetFileHref: ${tocEntry.title} (href: ${tocEntry.targetFileHref})",
            scope: "EpubController");
      }
    } else {
         ErrorHandler.logWarning(
            "Could not navigate to TOC entry (no valid index/target): ${tocEntry.title}",
            scope: "EpubController");
    }
  }

  Future<void> nextChapter() async {
    if (_currentChapterIndex < _totalChapters - 1) {
      await navigateToChapter(_currentChapterIndex + 1);
    }
  }

  Future<void> previousChapter() async {
    if (_currentChapterIndex > 0) {
      await navigateToChapter(_currentChapterIndex - 1);
    }
  }

  // --- Settings ---
  void setFontSize(double size) {
    _currentFontSize = size.clamp(10.0, 30.0); // Clamp to reasonable values
    notifyListeners();
  }

  // --- Lifecycle ---
  @override
  void dispose() {
    ErrorHandler.logInfo("EpubController disposing for ${_book.title}.", scope: "EpubController");
    _documentService.dispose();
    super.dispose();
  }
}
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
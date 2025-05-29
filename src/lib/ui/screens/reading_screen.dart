// lib/ui/screens/reading_screen.dart
// No need for dart:async, flutter_html here anymore for EPUBs
import 'dart:io'; // For File
import 'package:flutter/material.dart';
import 'package:novelist/models/book.dart';
import 'package:novelist/services/library_service.dart';
import 'package:novelist/core/error_handler.dart';
import 'package:novelist/core/app_constants.dart';
// Import our new EPUB package controller and viewer
import 'package:novelist/core/rendering/epub/epub_package_controller.dart';
import 'package:novelist/core/rendering/epub/epub_package_viewer_widget.dart';
// Import EpubChapter from the package for TOC dialog
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart' show EpubChapter, EpubTheme, EpubThemeType; // Only import what's needed


class ReadingScreen extends StatefulWidget {
  final Book book;
  const ReadingScreen({super.key, required this.book});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final LibraryService _libraryService = LibraryService();
  // Use our wrapper controller
  late final EpubPackageController _epubController;

  // ScrollController might not be needed if flutter_epub_viewer handles its own scrolling/paging
  // final ScrollController _scrollController = ScrollController(); 

  bool _isControllerInitialized = false; // Tracks if our wrapper controller is ready

  @override
  void initState() {
    super.initState();
    if (widget.book.format == BookFormat.epub) {
      _epubController = EpubPackageController(appBook: widget.book);
      _initializeEpubController();
    } else {
      ErrorHandler.logError(
          "Unsupported book format in ReadingScreen: ${widget.book.format}",
          scope: "ReadingScreen");
    }
  }

  void _initializeEpubController() {
    // Our EpubPackageController's initialize method might not be strictly necessary
    // if all setup is done via its constructor or if EpubViewer triggers everything.
    // For now, let's assume its constructor is enough, and we listen for changes.
    _epubController.addListener(_onEpubControllerUpdate);
    setState(() {
      _isControllerInitialized = true; // Our controller is ready to be used
    });
  }

  void _onEpubControllerUpdate() {
    // This is called when our _epubController.notifyListeners() is called.
    // Useful for updating AppBar title, page numbers, etc.
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    if (widget.book.format == BookFormat.epub && _isControllerInitialized) {
      // Save progress before disposing our controller
      _saveReadingProgress(); 
      _epubController.removeListener(_onEpubControllerUpdate);
      _epubController.dispose(); // Call dispose on our wrapper controller
    }
    // _scrollController.dispose(); // Dispose if used
    super.dispose();
  }

  Future<void> _saveReadingProgress() async {
    if (!_isControllerInitialized || widget.book.format != BookFormat.epub) return;

    try {
      Book? bookToUpdate = await _libraryService.getBookById(widget.book.id);
      if (bookToUpdate == null) {
        ErrorHandler.logWarning("Book not found for saving progress: ${widget.book.id}", scope: "ReadingScreen");
        return;
      }

      // Use the method from our wrapper controller
      final currentLocation = await _epubController.getCurrentViewerLocation();
      if (currentLocation != null) {
         bookToUpdate.lastLocation = currentLocation.startCfi;
         // Note: chapterIndex is harder to get directly from package's location.
         // We rely on CFI for EPUBs. If chapter index is strictly needed for book model,
         // _epubController would need logic to map CFI back to _tocChapters.
      }
      
      bookToUpdate.lastRead = DateTime.now();
      await _libraryService.updateBook(bookToUpdate);
      ErrorHandler.logInfo(
          "Saved progress for ${widget.book.title} (CFI: ${bookToUpdate.lastLocation})",
          scope: "ReadingScreen");
    } catch (e, s) {
      ErrorHandler.recordError(e, s, reason: "Failed to save reading progress for ${widget.book.title}", scope: "ReadingScreen");
    }
  }

  void _showTocDialog() {
    if (!_isControllerInitialized || _epubController.tableOfContents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Table of Contents not available or still loading.'))
      );
      // Optionally, trigger chapter parsing again if it failed initially in controller
      // _epubController.packageController.parseChapters().then(...);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false, initialChildSize: 0.7, maxChildSize: 0.9,
          builder: (_, scrollController) {
            return ListView.builder(
              controller: scrollController,
              itemCount: _epubController.tableOfContents.length,
              itemBuilder: (context, index) {
                final EpubChapter chapter = _epubController.tableOfContents[index];
                // TODO: Implement highlighting of current chapter based on CFI comparison
                // This is more complex as chapter.href might be just a file, and current location is a precise CFI.
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: kDefaultPadding + ( (chapter.subitems?.isNotEmpty ?? false) ? 0 : 16.0 ) ), // Basic indent for items without subitems
                  title: Text(chapter.title ?? "Unknown Chapter"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _epubController.navigateToCfi(chapter.href);
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
     if (!_isControllerInitialized) return;
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
                          setModalState(() {}); 
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
                           setModalState(() {}); 
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: kDefaultPadding),
                  Text("Theme", style: Theme.of(context).textTheme.titleMedium),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      ElevatedButton(onPressed: () => _epubController.updateTheme(EpubTheme.light()), child: const Text("Light")),
                      ElevatedButton(onPressed: () => _epubController.updateTheme(EpubTheme.dark()), child: const Text("Dark")),
                      // Add Sepia - EpubTheme doesn't have a built-in sepia.
                      // We'd use EpubTheme.custom(backgroundColor: ..., foregroundColor: ...)
                      // ElevatedButton(onPressed: () => _epubController.updateTheme(EpubTheme.custom(backgroundColor: Color(0xFFFBF0D9), foregroundColor: Color(0xFF5B4636))), child: const Text("Sepia")),
                    ],
                  )

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
    if (widget.book.format != BookFormat.epub) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: Center(
          child: Text("Unsupported format: ${widget.book.format.toString().split('.').last}"),
        ),
      );
    }
    
    // If our controller isn't ready yet, show loading.
    // The actual EPUB loading indicator will be inside EpubPackageViewerWidget (handled by EpubViewer)
    if (!_isControllerInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: const Center(child: CircularProgressIndicator(key: Key("reading_screen_controller_init_loader")))
      );
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
          // Use title from our controller, which might eventually get it from EPUB metadata
          title: Text(_epubController.bookTitleFromEpub, overflow: TextOverflow.ellipsis),
          actions: _isControllerInitialized && !_epubController.isLoading ? _buildAppBarActions() : [
             const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          ],
        ),
        // Use our wrapper viewer widget
        body: EpubPackageViewerWidget(controller: _epubController),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    // Disable buttons if the underlying viewer is still loading/processing via our controller's isLoading state
    final bool enableButtons = !_epubController.isLoading;
    return [
      IconButton(
        icon: const Icon(Icons.list_alt),
        onPressed: enableButtons ? _showTocDialog : null,
        tooltip: 'Table of Contents',
      ),
      IconButton(
        icon: const Icon(Icons.tune),
        onPressed: enableButtons ? _showReaderSettingsDialog : null,
        tooltip: 'Reader Settings',
      ),
      IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: enableButtons ? () => _epubController.previousPage() : null,
        tooltip: 'Previous Page',
      ),
      IconButton(
        icon: const Icon(Icons.arrow_forward_ios),
        onPressed: enableButtons ? () => _epubController.nextPage() : null,
        tooltip: 'Next Page',
      ),
    ];
  }
}
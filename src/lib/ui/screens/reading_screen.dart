// lib/ui/screens/reading_screen.dart
import 'package:flutter/material.dart';
import 'package:novelist/models/book.dart';
import 'package:novelist/services/library_service.dart';
import 'package:novelist/core/error_handler.dart';
import 'package:novelist/core/app_constants.dart';
import 'package:novelist/core/rendering/epub/epub_controller.dart';
import 'package:novelist/core/rendering/epub/epub_viewer_widget.dart';
import 'package:novelist/core/rendering/epub/toc_entry.dart'; // Still needed for TOC dialog

class ReadingScreen extends StatefulWidget {
  final Book book;
  const ReadingScreen({super.key, required this.book});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final LibraryService _libraryService = LibraryService();
  late final EpubController _epubController; // For EPUBs
  // Add controllers for other formats later, e.g., PdfController _pdfController;

  final ScrollController _scrollController = ScrollController(); // For scrolling content

  bool _isInitialized = false; // To track if controller initialization is done

  @override
  void initState() {
    super.initState();

    if (widget.book.format == BookFormat.epub) {
      _epubController = EpubController(book: widget.book);
      _initializeReader();
    } else {
      // Handle unsupported formats or initialize other controllers
      ErrorHandler.logWarning("Unsupported book format in ReadingScreen: ${widget.book.format}", scope: "ReadingScreen");
      // Potentially set an error state to display a message
    }
  }

  Future<void> _initializeReader() async {
    if (widget.book.format == BookFormat.epub) {
      // Listen to controller changes to update UI if needed (e.g., app bar title)
      _epubController.addListener(_onReaderControllerUpdate);
      await _epubController.initialize();
    }
    // Add init for other formats here

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      // Jump to top after initial load if controller manages scrolling,
      // or ensure EpubViewerWidget does this.
      if (_scrollController.hasClients) {
         _scrollController.jumpTo(0.0);
      }
    }
  }

  void _onReaderControllerUpdate() {
    // This is called when notifyListeners() is called in the controller.
    // Useful if ReadingScreen itself needs to rebuild based on controller state (e.g., app bar title)
    if (mounted) {
      setState(() {
        // Example: Update AppBar title if it depends on controller.bookTitleFromEpub
      });
    }
  }

  @override
  void dispose() {
    if (widget.book.format == BookFormat.epub) {
      _epubController.removeListener(_onReaderControllerUpdate);
      _saveReadingProgress(); // Save progress before disposing controller
      _epubController.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveReadingProgress() async {
    if (!_isInitialized) return; // Don't save if not even initialized

    if (widget.book.format == BookFormat.epub) {
      try {
        // Fetch the latest version of the book from storage
        Book? bookToUpdate = await _libraryService.getBookById(widget.book.id);
        if (bookToUpdate == null) {
          ErrorHandler.logWarning("Book not found for saving progress: ${widget.book.id}", scope: "ReadingScreen");
          return;
        }

        bookToUpdate.currentChapterIndex = _epubController.currentChapterIndex;
        bookToUpdate.lastRead = DateTime.now();
        // TODO: Update book.readingPercentage and book.lastLocation if those are tracked by controller
        // bookToUpdate.readingPercentage = _epubController.readingPercentage;
        // bookToUpdate.lastLocation = _epubController.currentLocationCFI // (example for EPUB)

        await _libraryService.updateBook(bookToUpdate);
        ErrorHandler.logInfo("Saved progress for ${widget.book.title} (Chapter: ${_epubController.currentChapterIndex})", scope: "ReadingScreen");
      } catch (e, s) {
        ErrorHandler.recordError(e, s, reason: "Failed to save reading progress for ${widget.book.title}", scope: "ReadingScreen");
      }
    }
    // Add progress saving for other formats here
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
      isScrollControlled: true, // Allows for taller bottom sheets
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7, // Start at 70% of screen height
          maxChildSize: 0.9,     // Max at 90%
          builder: (_, scrollController) {
            return ListView.builder(
              controller: scrollController,
              itemCount: _epubController.tableOfContents.length,
              itemBuilder: (context, index) {
                final TocEntry tocEntry = _epubController.tableOfContents[index];
                return ListTile(
                  contentPadding: EdgeInsets.only(left: (tocEntry.depth * kSmallPadding) + kDefaultPadding, right: kDefaultPadding),
                  title: Text(tocEntry.title, style: TextStyle(
                    fontWeight: _epubController.currentChapterIndex == tocEntry.chapterIndexForDisplayLogic && tocEntry.chapterIndexForDisplayLogic != -1
                        ? FontWeight.bold // Highlight current chapter if index matches
                        : FontWeight.normal,
                  )),
                  onTap: () {
                    Navigator.of(context).pop(); // Close the bottom sheet
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
        // Use a StatefulBuilder to manage local state of the font size slider/buttons
        // without needing to call setState on the whole ReadingScreen or EpubController for intermediate changes.
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
                          double newSize = _epubController.currentFontSize - 2;
                          _epubController.setFontSize(newSize);
                          // setModalState(() {}); // Update modal state if displaying size here
                        },
                      ),
                      Text(
                        _epubController.currentFontSize.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.titleMedium
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          double newSize = _epubController.currentFontSize + 2;
                          _epubController.setFontSize(newSize);
                          // setModalState(() {}); // Update modal state
                        },
                      ),
                    ],
                  ),
                  // TODO: Add more settings like font family, themes, line spacing later
                  const SizedBox(height: kSmallPadding),
                  // Example for future themes:
                  // Text("Theme", style: Theme.of(context).textTheme.titleMedium),
                  // SegmentedButton(...)
                  const SizedBox(height: kDefaultPadding),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = widget.book.title; // Default title
    if (_isInitialized && widget.book.format == BookFormat.epub) {
      appBarTitle = _epubController.bookTitleFromEpub ?? widget.book.title;
      if (_epubController.isLoading && _epubController.currentChapterHtmlContent == null) {
         // Use book title if controller still loading metadata
      } else if (_epubController.loadingError != null) {
        appBarTitle = "Error Loading Book";
      }
    } else if (!_isInitialized && widget.book.format == BookFormat.epub) {
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
          title: Text(appBarTitle, overflow: TextOverflow.ellipsis),
          actions: _buildAppBarActions(),
        ),
        body: _buildReaderBody(),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (!_isInitialized || widget.book.format != BookFormat.epub) {
      return [
         if (_isInitialized && widget.book.format == BookFormat.epub && _epubController.isLoading)
          const Padding(
            padding: EdgeInsets.all(kDefaultPadding),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2,)),
          )
      ]; // Empty or minimal actions if not EPUB or not ready
    }

    // EPUB specific actions
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
        icon: const Icon(Icons.arrow_back_ios_new), // Using a more standard icon
        onPressed: () => _epubController.previousChapter().then((_) {
          if (_scrollController.hasClients) _scrollController.jumpTo(0);
        }),
        tooltip: 'Previous Chapter',
      ),
      IconButton(
        icon: const Icon(Icons.arrow_forward_ios),
        onPressed: () => _epubController.nextChapter().then((_) {
          if (_scrollController.hasClients) _scrollController.jumpTo(0);
        }),
        tooltip: 'Next Chapter',
      ),
    ];
  }

  Widget _buildReaderBody() {
    if (!_isInitialized && widget.book.format == BookFormat.epub) {
      // Show a loading indicator while the EpubController is initializing
      return const Center(child: CircularProgressIndicator());
    }
    
    if (widget.book.format == BookFormat.epub) {
        // EpubController's isLoading or loadingError will be handled by EpubViewerWidget
        return EpubViewerWidget(
            controller: _epubController,
            scrollController: _scrollController, // Pass the scroll controller
        );
    } else {
      // Placeholder for other formats or error message
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Text(
            "Unsupported book format: ${widget.book.format.toString()}.\nCannot display this book.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.orange),
          ),
        ),
      );
    }
  }
}
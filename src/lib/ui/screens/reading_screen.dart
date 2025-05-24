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
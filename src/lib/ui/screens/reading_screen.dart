// lib/ui/screens/reading_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:novelist/models/book.dart';
import 'package:novelist/services/library_service.dart';
import 'package:novelist/core/error_handler.dart';
import 'package:novelist/core/app_constants.dart';
import 'package:novelist/core/rendering/epub/epub_package_controller.dart';
import 'package:novelist/core/rendering/epub/epub_package_viewer_widget.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart' show EpubChapter, EpubTheme, EpubThemeType;
import 'package:novelist/services/settings_service.dart'; // For ReaderThemeSetting enum

class ReadingScreen extends StatefulWidget {
  final Book book;
  const ReadingScreen({super.key, required this.book});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final LibraryService _libraryService = LibraryService();
  late final EpubPackageController _epubController;

  bool _isControllerInitialized = false; 

  // Available font families for the reader settings dropdown
  final List<String> _readerFontFamilyOptions = const ['Default', 'Serif', 'Sans-Serif', 'Times New Roman', 'Arial', 'Georgia'];


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
    _epubController.addListener(_onEpubControllerUpdate);
    setState(() {
      _isControllerInitialized = true; 
    });
  }

  void _onEpubControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    if (widget.book.format == BookFormat.epub && _isControllerInitialized) {
      _saveReadingProgress(); 
      _epubController.removeListener(_onEpubControllerUpdate);
      _epubController.dispose(); 
    }
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

      final currentLocation = await _epubController.getCurrentViewerLocation();
      if (currentLocation != null) {
         bookToUpdate.lastLocation = currentLocation.startCfi;
      }
      
      bookToUpdate.lastRead = DateTime.now();
      await _libraryService.updateBook(bookToUpdate);
      // Log page info if available, otherwise just CFI
      String pageInfoForLog = "";
      // Assuming flutter_epub_viewer's EpubLocation has progress which could be mapped to page numbers later
      if (currentLocation != null && currentLocation.progress != null) {
        // This is a placeholder, actual page number from progress needs calculation based on total locations
        // pageInfoForLog = ", Progress: ${(currentLocation.progress! * 100).toStringAsFixed(1)}%";
      }

      ErrorHandler.logInfo(
          "Saved progress for ${widget.book.title} (CFI: ${bookToUpdate.lastLocation ?? 'N/A'})$pageInfoForLog",
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
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: kDefaultPadding + ( (chapter.subitems?.isNotEmpty ?? false) ? 0 : 16.0 ) ),
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
      isScrollControlled: true, // Allow more content if needed
      builder: (BuildContext context) {
        return StatefulBuilder( 
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: SingleChildScrollView(
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
                            _epubController.setFontSize(_epubController.currentFontSize - 2)
                              .then((_) => setModalState(() {}));
                          },
                        ),
                        Text(
                          _epubController.currentFontSize.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                             _epubController.setFontSize(_epubController.currentFontSize + 2)
                               .then((_) => setModalState(() {}));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: kDefaultPadding),
                    Text("Reader Theme", style: Theme.of(context).textTheme.titleMedium),
                    DropdownButton<ReaderThemeSetting>(
                      value: _epubController.currentReaderThemeSetting,
                      isExpanded: true,
                      items: ReaderThemeSetting.values.map((ReaderThemeSetting theme) {
                        return DropdownMenuItem<ReaderThemeSetting>(
                          value: theme,
                          child: Text(theme.name[0].toUpperCase() + theme.name.substring(1)),
                        );
                      }).toList(),
                      onChanged: (ReaderThemeSetting? newTheme) {
                        if (newTheme != null) {
                          _epubController.setReaderTheme(newTheme)
                            .then((_) => setModalState(() {}));
                        }
                      },
                    ),
                    const SizedBox(height: kDefaultPadding),
                    Text("Font Family", style: Theme.of(context).textTheme.titleMedium),
                    DropdownButton<String>(
                      value: _readerFontFamilyOptions.contains(_epubController.currentReaderFontFamily) 
                             ? _epubController.currentReaderFontFamily 
                             : 'Default',
                      isExpanded: true,
                      items: _readerFontFamilyOptions.map((String fontFamily) {
                        return DropdownMenuItem<String>(
                          value: fontFamily,
                          child: Text(fontFamily),
                        );
                      }).toList(),
                      onChanged: (String? newFontFamily) {
                        if (newFontFamily != null) {
                          _epubController.setReaderFontFamily(newFontFamily)
                            .then((_) => setModalState(() {}));
                        }
                      },
                    ),
                    const SizedBox(height: kDefaultPadding),
                  ],
                ),
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
    
    if (!_isControllerInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: const Center(child: CircularProgressIndicator(key: Key("reading_screen_controller_init_loader")))
      );
    }

    String appBarTitle = _isControllerInitialized ? _epubController.bookTitleFromEpub : widget.book.title;
    String pageInfo = "";

    // Attempt to get page info from EpubLocation (progress percentage)
    // This is a simplified representation. Actual page numbers are harder to get accurately.
    if (_isControllerInitialized && !_epubController.isLoading && _epubController.currentCfiLocation != null) {
      // Try to get progress from the controller if it updates it from onRelocated
      // For a more direct approach, we'd need to call getCurrentLocation() but that's async.
      // For now, let's assume _currentCfiLocation implies some progress.
      // A better way would be for _epubController to store and expose current progress.
      // For simplicity, we'll omit page numbers from AppBar for now, as flutter_epub_viewer doesn't directly give page X of Y easily.
    }
     if (_isControllerInitialized && _epubController.isLoading) {
       pageInfo = "Loading...";
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
          // If you want to add pageInfo to AppBar, uncomment and refine below:
          // bottom: pageInfo.isNotEmpty ? PreferredSize(
          //   preferredSize: Size.fromHeight(20.0),
          //   child: Text(pageInfo, style: TextStyle(fontSize: 12)),
          // ) : null,
          actions: _isControllerInitialized && !_epubController.isLoading 
                     ? _buildAppBarActions() 
                     : [ const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) ],
        ),
        body: EpubPackageViewerWidget(controller: _epubController),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
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
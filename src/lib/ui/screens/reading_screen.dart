// lib/ui/screens/reading_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:novelist/models/book.dart';
import 'package:novelist/core/error_handler.dart';
import 'package:novelist/services/library_service.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:novelist/core/app_constants.dart';

class TocEntry {
  final String title;
  final int chapterIndexForDisplayLogic;
  final int depth;
  final String? targetFileHref;

  TocEntry({
    required this.title,
    required this.chapterIndexForDisplayLogic,
    this.depth = 0,
    this.targetFileHref,
  });
}

class ReadingScreen extends StatefulWidget {
  final Book book;
  const ReadingScreen({super.key, required this.book});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final LibraryService _libraryService = LibraryService();
  epubx.EpubBook? _epubBookData;
  String? _currentChapterContent;
  bool _isLoading = true;
  String? _loadingError;

  int _currentChapterIndex = 0;
  double _currentFontSize = 16.0;
  final ScrollController _scrollController = ScrollController();
  List<TocEntry> _tocList = [];

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.book.currentChapterIndex ?? 0;
    _initialLoadEpub();
  }

  @override
  void dispose() {
    _saveReadingProgress();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initialLoadEpub() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _loadingError = null; });
    try {
      if (widget.book.format != BookFormat.epub) {
        throw Exception("Unsupported format: ${widget.book.format}");
      }
      File bookFile = File(widget.book.filePath);
      if (!await bookFile.exists()) {
        throw Exception("Book file not found: ${widget.book.filePath}");
      }
      Uint8List bytes = await bookFile.readAsBytes();
      epubx.EpubBook epub = await epubx.EpubReader.readBook(bytes);

      if (!mounted) return;
      setState(() {
        _epubBookData = epub;
        _buildTocList();
      });

      int chapterCount = _getChapterCount();
      if (chapterCount > 0 && _currentChapterIndex >= chapterCount) {
        _currentChapterIndex = 0;
      } else if (chapterCount == 0 && _currentChapterIndex != 0) {
         _currentChapterIndex = 0;
      }
      
      await _displayChapter(_currentChapterIndex, fromInit: true);

    } catch (e, s) {
      ErrorHandler.recordError(e, s, reason: "Failed to load EPUB for ${widget.book.title}");
      if (mounted) {
        setState(() { _loadingError = "Error loading book: $e"; _isLoading = false; });
      }
    }
  }

  int _getChapterCount() {
    return _epubBookData?.Schema?.Package?.Spine?.Items?.length ?? 
           _epubBookData?.Chapters?.length ?? 0;
  }

  Future<void> _displayChapter(int chapterIndex, {bool fromInit = false}) async {
    if (_epubBookData == null || !mounted) return;
    if (!fromInit) { await _saveReadingProgress(); }
    if (mounted) { setState(() { _isLoading = true; _currentChapterIndex = chapterIndex; });}

    String? chapterHtmlContent;
    final List<epubx.EpubSpineItemRef>? spineItems = _epubBookData!.Schema?.Package?.Spine?.Items;

    if (spineItems != null && spineItems.isNotEmpty) {
      if (chapterIndex >= 0 && chapterIndex < spineItems.length) {
        final epubx.EpubSpineItemRef spineItem = spineItems[chapterIndex];
        epubx.EpubManifestItem? manifestItem;
        try {
          manifestItem = _epubBookData!.Schema?.Package?.Manifest?.Items
              ?.firstWhere((item) => item.Id == spineItem.IdRef);
        } catch (_) {
          manifestItem = null;
        }
        final String? hrefKey = manifestItem?.Href;
        if (hrefKey != null && 
            _epubBookData!.Content?.Html?.containsKey(hrefKey) == true) {
          chapterHtmlContent = _epubBookData!.Content!.Html![hrefKey]!.Content;
        }
      }
    }

    if (chapterHtmlContent == null) {
      final List<epubx.EpubChapter>? chapters = _epubBookData!.Chapters;
      if (chapters != null && chapters.isNotEmpty && chapterIndex >= 0 && chapterIndex < chapters.length) {
        final epubx.EpubChapter chapter = chapters[chapterIndex];
        chapterHtmlContent = chapter.HtmlContent;
        if (chapterHtmlContent == null && chapter.ContentFileName != null) {
          final epubx.EpubTextContentFile? chapterFile = _epubBookData!.Content?.Html?[chapter.ContentFileName!];
          chapterHtmlContent = chapterFile?.Content;
        }
      }
    }
    
    if (!mounted) return;
    if (chapterHtmlContent != null) {
      setState(() { _currentChapterContent = chapterHtmlContent; _isLoading = false; });
      if (_scrollController.hasClients) { _scrollController.jumpTo(0.0); }
    } else {
      ErrorHandler.logWarning("Null content for chapter index $chapterIndex. Total chapters/spine items: ${_getChapterCount()}", scope: "ReadingScreen");
      setState(() { _currentChapterContent = "<p>Error: Could not load chapter content for index $chapterIndex.</p>"; _isLoading = false; });
    }
  }

  void _buildTocList() {
    _tocList = [];
    if (_epubBookData == null) return;

    final epubx.EpubNavigation? nav = _epubBookData!.Schema?.Navigation;
    // CORRECTED: NavMap is a single EpubNavigationMap?, not a List
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
                  targetFileHref: point.Content?.Source
                ));
            }
            if (point.ChildNavigationPoints != null && point.ChildNavigationPoints!.isNotEmpty) {
              addNavPointsRecursive(point.ChildNavigationPoints!, depth + 1);
            }
          }
       }
      addNavPointsRecursive(navMap.Points ?? [], 0);
    }
    
    if (_tocList.isEmpty && _epubBookData!.Chapters?.isNotEmpty == true) {
       ErrorHandler.logInfo("NAV TOC empty or not found, falling back to NCX Chapters for TOC.", scope: "ReadingScreen");
       for (var i = 0; i < _epubBookData!.Chapters!.length; i++) {
         var chapter = _epubBookData!.Chapters![i];
         if (chapter.Title != null) { 
            _tocList.add(TocEntry(
              title: chapter.Title!,
              chapterIndexForDisplayLogic: i, 
              depth: 0, 
              targetFileHref: chapter.ContentFileName 
            ));
         }
       }
    }
  }

  int _findSpineIndexForNavPoint(epubx.EpubNavigationPoint navPoint) {
    final String? targetFile = navPoint.Content?.Source?.split('#').first;
    if (targetFile == null) return -1;
    
    final List<epubx.EpubSpineItemRef>? spineItems = _epubBookData?.Schema?.Package?.Spine?.Items;
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
  
  void _goToChapterByTocEntry(TocEntry tocEntry) {
    if (mounted) Navigator.of(context).pop();
    if (_epubBookData == null) return;
    
    if (tocEntry.chapterIndexForDisplayLogic != -1) {
        _displayChapter(tocEntry.chapterIndexForDisplayLogic);
    } else if (tocEntry.targetFileHref != null) {
        int foundIndex = -1;
        final List<epubx.EpubSpineItemRef>? spineItems = _epubBookData!.Schema?.Package?.Spine?.Items;
        if (spineItems != null) {
            for (var i = 0; i < spineItems.length; i++) {
                epubx.EpubManifestItem? manifestItem;
                try {
                  manifestItem = _epubBookData!.Schema?.Package?.Manifest?.Items
                      ?.firstWhere((item) => item.Id == spineItems[i].IdRef);
                } catch (_) {
                  manifestItem = null;
                }
                if (manifestItem?.Href == tocEntry.targetFileHref) {
                    foundIndex = i;
                    break;
                }
            }
        }
        if (foundIndex != -1) {
            _displayChapter(foundIndex);
        } else {
            ErrorHandler.logWarning("Could not navigate to TOC item by targetFile: ${tocEntry.title}", scope: "ReadingScreen");
            if(mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Could not navigate to chapter: ${tocEntry.title}")),
                );
            }
        }
    } else {
         ErrorHandler.logWarning("Could not navigate to TOC item (no valid index/target): ${tocEntry.title}", scope: "ReadingScreen");
         if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Could not navigate to chapter: ${tocEntry.title}")),
            );
         }
    }
  }
  
  void _goToNextChapter() {
    if (_epubBookData == null) return;
    final int chapterCount = _getChapterCount();
    if (chapterCount > 0 && _currentChapterIndex < chapterCount - 1) {
      _displayChapter(_currentChapterIndex + 1);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are at the last chapter.')),
        );
      }
    }
  }

  void _goToPreviousChapter() {
    if (_currentChapterIndex > 0) {
      _displayChapter(_currentChapterIndex - 1);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are at the first chapter.')),
        );
      }
    }
  }

  Future<void> _saveReadingProgress() async {
     if (!mounted) return;
    try {
      Book? bookToUpdate = await _libraryService.getBookById(widget.book.id);
      if (bookToUpdate == null) {
        ErrorHandler.logWarning("Book not found for saving progress: ${widget.book.id}", scope: "ReadingScreen");
        return;
      }

      bookToUpdate.currentChapterIndex = _currentChapterIndex;
      bookToUpdate.lastRead = DateTime.now();
      await _libraryService.updateBook(bookToUpdate);
      ErrorHandler.logInfo("Saved progress for ${widget.book.title}", scope: "ReadingScreen");
    } catch (e,s) {
      ErrorHandler.recordError(e,s, reason: "Failed to save reading progress for ${widget.book.title}");
    }
  }

  void _changeFontSize(double delta) {
    if(mounted) {
      setState(() {
        _currentFontSize = (_currentFontSize + delta).clamp(10.0, 30.0);
      });
    }
  }

  void _showTocDialog() {
    if (_tocList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Table of Contents not available or empty.')),
        );
      }
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
              itemCount: _tocList.length,
              itemBuilder: (context, index) {
                final tocEntry = _tocList[index];
                return ListTile(
                  contentPadding: EdgeInsets.only(left: (tocEntry.depth * 16.0) + 16.0),
                  title: Text(tocEntry.title), 
                  onTap: () => _goToChapterByTocEntry(tocEntry),
                );
              },
            );
          }
        );
      },
    );
  }

 void _showReaderSettingsDialog() {
     showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("Font Size", style: Theme.of(context).textTheme.titleMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.remove), onPressed: () => _changeFontSize(-2)),
                  Text(_currentFontSize.toStringAsFixed(0), style: const TextStyle(fontSize: 18)),
                  IconButton(icon: const Icon(Icons.add), onPressed: () => _changeFontSize(2)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
     String appBarTitle = _isLoading ? "Loading..." : (_epubBookData?.Title ?? widget.book.title);
    if (_loadingError != null) appBarTitle = "Error";

    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) async { 
        if (didPop && mounted) {
          await _saveReadingProgress();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(appBarTitle, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              icon: const Icon(Icons.list_alt),
              onPressed: (_isLoading || _epubBookData == null) ? null : _showTocDialog,
              tooltip: 'Table of Contents',
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: _isLoading ? null : _showReaderSettingsDialog,
              tooltip: 'Reader Settings',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _isLoading ? null : _goToPreviousChapter,
              tooltip: 'Previous Chapter',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _isLoading ? null : _goToNextChapter,
              tooltip: 'Next Chapter',
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadingError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Text(_loadingError!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (_currentChapterContent == null) {
      return const Center(child: Text("No content to display for this chapter."));
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Html(
        data: _currentChapterContent!,
        style: {
          "body": Style(
            fontSize: FontSize(_currentFontSize),
            lineHeight: LineHeight.em(1.5),
          ),
          "p": Style(margin: Margins.only(bottom: _currentFontSize * 0.5)),
          "h1": Style(fontSize: FontSize(_currentFontSize * 1.8), fontWeight: FontWeight.bold),
          "h2": Style(fontSize: FontSize(_currentFontSize * 1.5), fontWeight: FontWeight.bold),
          "h3": Style(fontSize: FontSize(_currentFontSize * 1.3), fontWeight: FontWeight.bold),
        },
        onLinkTap: (url, attributes, element) async {
          ErrorHandler.logInfo("Link tapped: $url", scope: "ReadingScreen");
          if (url != null) {
            if (url.startsWith("http://") || url.startsWith("https://")) {
              final uri = Uri.parse(url);
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  throw 'Could not launch $url';
                }
              } catch(e) {
                if (mounted) { 
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not launch $url: $e')),
                  );
                }
              }
            } else {
              ErrorHandler.logInfo("Internal link: $url (not yet handled)", scope: "ReadingScreen");
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
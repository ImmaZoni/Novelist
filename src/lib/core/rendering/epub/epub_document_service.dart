// lib/core/rendering/epub/epub_document_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:epubx/epubx.dart' as epubx;
import 'package:novelist/core/error_handler.dart';
import 'package:novelist/core/rendering/epub/toc_entry.dart';

class EpubDocumentService {
  epubx.EpubBook? _epubBookData;
  List<TocEntry> _tocList = [];
  String? _bookTitle; // Store the title separately after parsing

  // Public getters
  epubx.EpubBook? get epubBookData => _epubBookData;
  List<TocEntry> get tableOfContents => _tocList;
  String? get bookTitle => _bookTitle;

  Future<bool> loadBook(String filePath) async {
    try {
      File bookFile = File(filePath);
      if (!await bookFile.exists()) {
        ErrorHandler.logWarning("EPUB file not found at path: $filePath", scope: "EpubDocumentService");
        return false;
      }
      Uint8List bytes = await bookFile.readAsBytes();
      _epubBookData = await epubx.EpubReader.readBook(bytes);
      _bookTitle = _epubBookData?.Title;

      _buildTocList();
      return true;
    } catch (e, s) {
      ErrorHandler.recordError(e, s, reason: "Failed to load EPUB for $filePath", scope: "EpubDocumentService");
      _epubBookData = null;
      _tocList = [];
      _bookTitle = null;
      return false;
    }
  }

  void _buildTocList() {
    _tocList = [];
    if (_epubBookData == null) return;

    final epubx.EpubNavigation? nav = _epubBookData!.Schema?.Navigation;
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
              targetFileHref: point.Content?.Source,
            ));
          }
          if (point.ChildNavigationPoints != null && point.ChildNavigationPoints!.isNotEmpty) {
            addNavPointsRecursive(point.ChildNavigationPoints!, depth + 1);
          }
        }
      }
      addNavPointsRecursive(navMap.Points!, 0); // Assuming Points is not null if navMap is not null and Points is not empty
    }

    // Fallback to NCX chapters if NAV map TOC is empty or not found
    if (_tocList.isEmpty && _epubBookData!.Chapters?.isNotEmpty == true) {
      ErrorHandler.logInfo("NAV TOC empty or not found, falling back to NCX Chapters for TOC.", scope: "EpubDocumentService");
      for (var i = 0; i < _epubBookData!.Chapters!.length; i++) {
        var chapter = _epubBookData!.Chapters![i];
        if (chapter.Title != null) {
          _tocList.add(TocEntry(
            title: chapter.Title!,
            chapterIndexForDisplayLogic: i, // This might need adjustment if NCX chapters don't align 1:1 with spine items used for display
            depth: 0,
            targetFileHref: chapter.ContentFileName,
          ));
        }
      }
    }
  }

  int _findSpineIndexForNavPoint(epubx.EpubNavigationPoint navPoint) {
    final String? targetFile = navPoint.Content?.Source?.split('#').first;
    if (targetFile == null || _epubBookData == null) return -1;

    final List<epubx.EpubSpineItemRef>? spineItems = _epubBookData!.Schema?.Package?.Spine?.Items;
    if (spineItems == null) return -1;

    for (var i = 0; i < spineItems.length; i++) {
      epubx.EpubManifestItem? manifestItem;
      try {
        manifestItem = _epubBookData!.Schema?.Package?.Manifest?.Items
            ?.firstWhere((item) => item.Id == spineItems[i].IdRef);
      } catch (_) {
        manifestItem = null; // Not found
      }
      if (manifestItem?.Href == targetFile) {
        return i;
      }
    }
    return -1; // Not found in spine
  }

  int getChapterCount() {
    if (_epubBookData == null) return 0;
    // Prefer spine items as they represent the linear reading order
    return _epubBookData!.Schema?.Package?.Spine?.Items?.length ??
           _epubBookData!.Chapters?.length ?? 0;
  }

  String? getChapterHtmlContent(int chapterIndex) {
    if (_epubBookData == null || chapterIndex < 0) return null;

    String? chapterHtmlContent;
    final List<epubx.EpubSpineItemRef>? spineItems = _epubBookData!.Schema?.Package?.Spine?.Items;

    // Try to get content based on spine (preferred)
    if (spineItems != null && chapterIndex < spineItems.length) {
      final epubx.EpubSpineItemRef spineItem = spineItems[chapterIndex];
      epubx.EpubManifestItem? manifestItem;
      try {
        manifestItem = _epubBookData!.Schema?.Package?.Manifest?.Items
            ?.firstWhere((item) => item.Id == spineItem.IdRef);
      } catch (_) {
        manifestItem = null;
      }

      final String? hrefKey = manifestItem?.Href;
      if (hrefKey != null && _epubBookData!.Content?.Html?.containsKey(hrefKey) == true) {
        chapterHtmlContent = _epubBookData!.Content!.Html![hrefKey]!.Content;
      }
    }

    // Fallback to legacy Chapters if spine method fails or content is null
    if (chapterHtmlContent == null) {
      ErrorHandler.logInfo("Could not get chapter $chapterIndex via spine, trying legacy Chapters.", scope: "EpubDocumentService");
      final List<epubx.EpubChapter>? chapters = _epubBookData!.Chapters;
      if (chapters != null && chapterIndex < chapters.length) {
        final epubx.EpubChapter chapter = chapters[chapterIndex];
        chapterHtmlContent = chapter.HtmlContent;
        if (chapterHtmlContent == null && chapter.ContentFileName != null) {
          // Try to get content from ContentFileName if HtmlContent is null
          final epubx.EpubTextContentFile? chapterFile = _epubBookData!.Content?.Html?[chapter.ContentFileName!];
          chapterHtmlContent = chapterFile?.Content;
        }
      }
    }
    
    if (chapterHtmlContent == null) {
      ErrorHandler.logWarning("Still null content for chapter index $chapterIndex after all attempts.", scope: "EpubDocumentService");
    }

    return chapterHtmlContent;
  }

  void dispose() {
    _epubBookData = null;
    _tocList = [];
    _bookTitle = null;
    ErrorHandler.logInfo("EpubDocumentService disposed.", scope: "EpubDocumentService");
  }
}
// lib/core/rendering/epub/epub_document_service.dart
import 'dart:convert'; // For base64Encode
import 'dart:io';
import 'dart:typed_data';
import 'package:epubx/epubx.dart' as epubx;
import 'package:novelist/core/error_handler.dart';
import 'package:novelist/core/rendering/epub/toc_entry.dart';
import 'package:html/parser.dart' as html_parser; // For parsing HTML
import 'package:html/dom.dart' as dom; // For DOM manipulation
import 'package:path/path.dart' as p; // For path normalization

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
      addNavPointsRecursive(navMap.Points!, 0);
    }

    // Fallback to NCX chapters if NAV map TOC is empty or not found
    if (_tocList.isEmpty && _epubBookData!.Chapters?.isNotEmpty == true) {
      ErrorHandler.logInfo("NAV TOC empty or not found, falling back to NCX Chapters for TOC.", scope: "EpubDocumentService");
      for (var i = 0; i < _epubBookData!.Chapters!.length; i++) {
        var chapter = _epubBookData!.Chapters![i];
        if (chapter.Title != null) {
          _tocList.add(TocEntry(
            title: chapter.Title!,
            chapterIndexForDisplayLogic: i,
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
        manifestItem = null;
      }
      if (manifestItem?.Href == targetFile) {
        return i;
      }
    }
    return -1;
  }

  int getChapterCount() {
    if (_epubBookData == null) return 0;
    return _epubBookData!.Schema?.Package?.Spine?.Items?.length ??
           _epubBookData!.Chapters?.length ?? 0;
  }

  String? getChapterHtmlContent(int chapterIndex) {
    if (_epubBookData == null || chapterIndex < 0) return null;

    String? rawChapterHtmlContent;
    String? currentChapterFilePath; // To resolve relative image paths

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
      if (hrefKey != null) {
        currentChapterFilePath = hrefKey; // Store the path of the current HTML file
        if (_epubBookData!.Content?.Html?.containsKey(hrefKey) == true) {
          rawChapterHtmlContent = _epubBookData!.Content!.Html![hrefKey]!.Content;
        }
      }
    }

    // Fallback to legacy Chapters if spine method fails or content is null
    if (rawChapterHtmlContent == null) {
      ErrorHandler.logInfo("Could not get chapter $chapterIndex via spine, trying legacy Chapters.", scope: "EpubDocumentService");
      final List<epubx.EpubChapter>? chapters = _epubBookData!.Chapters;
      if (chapters != null && chapterIndex < chapters.length) {
        final epubx.EpubChapter chapter = chapters[chapterIndex];
        rawChapterHtmlContent = chapter.HtmlContent;
        currentChapterFilePath = chapter.ContentFileName; // Path from legacy chapter
        if (rawChapterHtmlContent == null && chapter.ContentFileName != null) {
          // Try to get content from ContentFileName if HtmlContent is null
          final epubx.EpubTextContentFile? chapterFile = _epubBookData!.Content?.Html?[chapter.ContentFileName!];
          rawChapterHtmlContent = chapterFile?.Content;
        }
      }
    }
    
    if (rawChapterHtmlContent == null) {
      ErrorHandler.logWarning("Raw HTML content is null for chapter index $chapterIndex after all attempts.", scope: "EpubDocumentService");
      return "<p>Error: Could not load chapter content.</p>";
    }

    // Process HTML to embed images as Base64
    String processedHtml = _processHtmlContent(rawChapterHtmlContent, currentChapterFilePath, _epubBookData!);
    
    // For debugging the output (can be removed or commented out)
    // ErrorHandler.logInfo("Processed HTML for chapter $chapterIndex (first 500 chars): ${processedHtml.substring(0, processedHtml.length > 500 ? 500 : processedHtml.length)}", scope: "EpubDocumentService");

    return processedHtml;
  }

  String _processHtmlContent(String htmlContent, String? chapterFilePath, epubx.EpubBook bookData) {
    if (chapterFilePath == null) {
        ErrorHandler.logWarning("Chapter file path is null, cannot process relative image paths.", scope: "EpubDocumentService");
        return htmlContent; 
    }

    var document = html_parser.parse(htmlContent);
    List<dom.Element> imgElements = document.getElementsByTagName('img');
    List<dom.Element> svgImageElements = document.getElementsByTagName('image'); // For <image xlink:href="..."> within <svg>

    // Handle <img> tags
    for (var imgElement in imgElements) {
      String? src = imgElement.attributes['src'];
      _processImageSrc(src, imgElement, chapterFilePath, bookData, 'src');
    }

    // Handle <image xlink:href="..."> tags within SVGs
    for (var svgImageElement in svgImageElements) {
        String? src = svgImageElement.attributes['xlink:href'] ?? svgImageElement.attributes['href']; // Check both
         _processImageSrc(src, svgImageElement, chapterFilePath, bookData, 
            svgImageElement.attributes.containsKey('xlink:href') ? 'xlink:href' : 'href');
    }

    return document.outerHtml;
  }

  void _processImageSrc(String? src, dom.Element imgElement, String chapterFilePath, epubx.EpubBook bookData, String attributeName) {
     if (src != null && !src.startsWith('data:image')) { // Only process if not already a data URI
        try {
          String absoluteImgPath = p.normalize(p.join(p.dirname(chapterFilePath), src));
          
          if (absoluteImgPath.startsWith('/')) {
            absoluteImgPath = absoluteImgPath.substring(1);
          }

          epubx.EpubByteContentFile? imageFile;
          
          if (bookData.Content?.Images?.containsKey(absoluteImgPath) ?? false) {
            imageFile = bookData.Content!.Images![absoluteImgPath];
          } 
          else if (bookData.Content?.AllFiles?.containsKey(absoluteImgPath) ?? false) {
             var file = bookData.Content!.AllFiles![absoluteImgPath];
             if (file is epubx.EpubByteContentFile) {
                imageFile = file;
             }
          }

          if (imageFile != null && imageFile.Content != null) {
            Uint8List imageBytes = Uint8List.fromList(imageFile.Content!); 
            
            String? resolvedMimeType = imageFile.ContentType != null
                ? _epubContentTypeToMimeType(imageFile.ContentType!)
                : _getMimeType(absoluteImgPath);
            
            String base64Image = base64Encode(imageBytes);
            imgElement.attributes[attributeName] = 'data:$resolvedMimeType;base64,$base64Image';
            // ErrorHandler.logInfo("Successfully processed image: $absoluteImgPath -> data URI", scope: "EpubDocumentService");
          } else {
            if (imageFile == null) {
                ErrorHandler.logWarning("Image not found in EPUB content: $src (resolved to: $absoluteImgPath)", scope: "EpubDocumentService");
            } else {
                ErrorHandler.logWarning("Image content is null for: $src (resolved to: $absoluteImgPath)", scope: "EpubDocumentService");
            }
          }
        } catch (e, s) {
          ErrorHandler.recordError(e, s, reason: "Failed to process image with src: $src", scope: "EpubDocumentService");
        }
      }
  }

  String _epubContentTypeToMimeType(epubx.EpubContentType type) {
    switch (type) {
      case epubx.EpubContentType.IMAGE_GIF:
        return 'image/gif';
      case epubx.EpubContentType.IMAGE_JPEG:
        return 'image/jpeg';
      case epubx.EpubContentType.IMAGE_PNG:
        return 'image/png';
      case epubx.EpubContentType.IMAGE_SVG:
        return 'image/svg+xml';
      case epubx.EpubContentType.IMAGE_BMP:
        return 'image/bmp';
      case epubx.EpubContentType.CSS:
      case epubx.EpubContentType.OEB1_CSS:
        return 'text/css';
      case epubx.EpubContentType.XHTML_1_1:
        return 'application/xhtml+xml';
      case epubx.EpubContentType.DTBOOK:
        return 'application/x-dtbook+xml';
      case epubx.EpubContentType.DTBOOK_NCX:
        return 'application/x-dtbncx+xml';
      case epubx.EpubContentType.OEB1_DOCUMENT:
        return 'application/x-oeb1-document';
      case epubx.EpubContentType.XML:
        return 'application/xml';
      case epubx.EpubContentType.FONT_TRUETYPE:
        return 'font/ttf';
      case epubx.EpubContentType.FONT_OPENTYPE:
        return 'font/otf';
      case epubx.EpubContentType.OTHER:
        return 'application/octet-stream';
    }
  }

  String _getMimeType(String filePath) {
    String extension = p.extension(filePath).toLowerCase();
    if (extension == '.jpg' || extension == '.jpeg') return 'image/jpeg';
    if (extension == '.png') return 'image/png';
    if (extension == '.gif') return 'image/gif';
    if (extension == '.svg') return 'image/svg+xml';
    if (extension == '.webp') return 'image/webp';
    return 'application/octet-stream'; // Default MIME type
  }

  void dispose() {
    _epubBookData = null;
    _tocList = [];
    _bookTitle = null;
    ErrorHandler.logInfo("EpubDocumentService disposed.", scope: "EpubDocumentService");
  }
}
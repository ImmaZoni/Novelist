// lib/ui/screens/cover_search_screen.dart
import 'dart:async';
import 'dart:convert'; // For base64Decode
import 'dart:io'; // For File
import 'dart:typed_data'; // For Uint8List

import 'package:flutter/material.dart';
import 'package:novelist/models/book.dart';
import 'package:novelist/core/app_constants.dart';
import 'package:novelist/core/error_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:novelist/services/library_service.dart';
import 'package:image/image.dart' as img_lib;

class CoverSearchScreen extends StatefulWidget {
  final Book book;
  const CoverSearchScreen({super.key, required this.book});

  @override
  State<CoverSearchScreen> createState() => _CoverSearchScreenState();
}

class _CoverSearchScreenState extends State<CoverSearchScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? _webViewController;
  
  String? _selectedExternalImageUrl; 
  String? _selectedBase64MimeType; // To store MIME type from base64 URI
  Uint8List? _finalImageBytesForSaving; 

  bool _isLoadingPreview = false; 
  bool _isSettingCover = false;  

  late String _initialSearchUrl;

  final LibraryService _libraryService = LibraryService();

  final String _jsToExtractImageOnClick = """
    (function() {
      function isDirectImageUrl(url) {
        return url && (url.match(/\\.(jpeg|jpg|gif|png|webp)(\\?.*)?\$/i) != null);
      }

      function sendToFlutter(handlerName, data) {
        if (window.flutter_inappwebview) {
          window.flutter_inappwebview.callHandler(handlerName, data);
          // Shorten logged data if it's a long base64 string
          let logData = data;
          if (typeof data === 'string' && data.startsWith('data:image') && data.length > 200) {
            logData = data.substring(0, 100) + '...[TRUNCATED_BASE64]...';
          }
          console.log('[Novelist JS] Sent via ' + handlerName + '. Data: ' + logData);
          return true;
        }
        console.error('[Novelist JS] flutter_inappwebview not found!');
        return false;
      }

      function findMainPreviewImageSrc() {
        console.log('[Novelist JS] Attempting to find main preview image...');
        const selectors = [
          'img[jsname="kn3ccd"]',                   
          'img.sFlh5c.pT0Scc.iPVvYb',              
          'a[jsname][href*="imgurl="] img', 
          'div[role="dialog"] img[jsname="PWTBeb"]', // Common for lightbox main image
          'div[role="dialog"] img[src^="http"]:not([style*="display: none"])', // Visible image in dialog
          'div[role="dialog"] img[src^="data:"]:not([style*="display: none"])',
          'img[id^="dimg_"][data-src]',             
          'img[id^="dimg_"]',                       
          'img[alt][src^="http"]:not([data-src])', 
        ];

        for (let selector of selectors) {
          const elems = document.querySelectorAll(selector);
          for (let img of elems) {
            // Check if the image is likely visible and large enough (heuristic)
             if (img.offsetParent !== null && (img.naturalWidth === 0 || img.naturalWidth > 100) && (img.naturalHeight === 0 || img.naturalHeight > 100)) { 
              let srcToUse = img.dataset.src || img.src; 
              if (srcToUse) {
                console.log('[Novelist JS] Selector "' + selector + '" found img. Trying src: ' + (srcToUse.length > 100 ? srcToUse.substring(0,100) : srcToUse));
                if (srcToUse.startsWith('data:image')) return { type: 'base64', data: srcToUse };
                if (isDirectImageUrl(srcToUse)) return { type: 'url', data: srcToUse };
              }
            }
          }
        }
        
        const ogUrlDiv = document.querySelector('div[data-ogurl]');
        if (ogUrlDiv && ogUrlDiv.dataset.ogurl) {
            const ogUrl = ogUrlDiv.dataset.ogurl;
            console.log('[Novelist JS] Found data-ogurl: ' + ogUrl);
            if(isDirectImageUrl(ogUrl)) return { type: 'url', data: ogUrl };
        }

        console.log('[Novelist JS] No definitive main preview image found with current selectors.');
        return null;
      }
      
      document.body.addEventListener('click', function(event) {
        console.log('[Novelist JS] Click event triggered. Target:', event.target);
        let clickedElement = event.target;
        
        let potentialImageContainer = clickedElement.closest('div[role="link"], a[jsname][href*="imgurl="], div[jsdata], div[data-owc]'); // Added data-owc
        
        setTimeout(() => {
          let bestSource = findMainPreviewImageSrc();

          if (!bestSource && potentialImageContainer) { // If primary selectors fail, check container
            console.log('[Novelist JS] Primary selectors failed. Checking potential image container.');
            bestSource = findMainPreviewImageSrc(potentialImageContainer); // Pass container to function
          }
          
          if (!bestSource) { // If still no good source, try the clicked element
            console.log('[Novelist JS] Container check failed. Fallback to originally clicked element for source.');
            bestSource = findMainPreviewImageSrc(clickedElement);
          }


          if (bestSource) {
            if (bestSource.type === 'base64') {
              sendToFlutter('base64ImageSelected', bestSource.data);
            } else if (bestSource.type === 'url') {
              sendToFlutter('externalImageUrlSelected', bestSource.data);
            }
          } else {
            console.log('[Novelist JS] No image source successfully extracted after click and timeout. You may need to adjust selectors in findMainPreviewImageSrc().');
            // Last resort: find *any* large enough image (might not be the one user intended)
            const allImages = document.querySelectorAll('img[src^="data:image"], img[src^="http"]');
            for (let img of allImages) {
                if (img.offsetParent !== null && (img.naturalWidth === 0 || img.naturalWidth > 200) && (img.naturalHeight === 0 || img.naturalHeight > 200) ) {
                    if (img.src.startsWith('data:image')) {
                        sendToFlutter('base64ImageSelected', img.src); return;
                    } else if (isDirectImageUrl(img.src)) {
                        sendToFlutter('externalImageUrlSelected', img.src); return;
                    }
                }
            }
            console.log('[Novelist JS] Last resort scan for any large image also failed.');
          }
        }, 750); 

      }, true); 
      console.log('[Novelist JS] Advanced image click listener attached.');
    })();
  """;


  @override
  void initState() {
    super.initState();
    String searchTerm = "${widget.book.title} ${widget.book.author ?? ''} book cover";
    _initialSearchUrl = "https://www.google.com/search?tbm=isch&q=${Uri.encodeComponent(searchTerm)}";
    ErrorHandler.logInfo("Search URL: $_initialSearchUrl", scope: "CoverSearchScreen");
  }

  String _getMimeTypeFromBase64DataUri(String dataUri) {
    if (dataUri.startsWith("data:image/") && dataUri.contains(";base64,")) {
      try {
        // data:image/jpeg;base64,...
        return dataUri.substring(dataUri.indexOf('/') + 1, dataUri.indexOf(';'));
      } catch (e) {
        ErrorHandler.logWarning("Could not parse MIME type from Base64 URI: ${dataUri.substring(0, dataUri.length > 60 ? 60 : dataUri.length)}", scope: "CoverSearchScreen");
      }
    }
    ErrorHandler.logWarning("Base64 URI does not match expected format for MIME type parsing.", scope: "CoverSearchScreen");
    return 'jpeg'; // Fallback
  }

  Future<void> _processSelectedBase64(String base64DataUri) async {
    ErrorHandler.logInfo("Processing Base64...", scope: "CoverSearchScreen");
    setState(() { _isLoadingPreview = true; _selectedExternalImageUrl = null; _finalImageBytesForSaving = null; _selectedBase64MimeType = null;});
    try {
      final uriParts = base64DataUri.split(',');
      if (uriParts.length != 2 || !uriParts[0].startsWith("data:image")) {
        throw FormatException("Invalid Base64 URI format: ${base64DataUri.substring(0, base64DataUri.length > 60 ? 60 : base64DataUri.length)}");
      }
      
      _selectedBase64MimeType = _getMimeTypeFromBase64DataUri(uriParts[0]); // Store MIME from URI
      _finalImageBytesForSaving = base64Decode(uriParts[1]);
      
      if (mounted) {
        setState(() { _isLoadingPreview = false; });
      }
    } catch (e, s) {
      ErrorHandler.recordError(e, s, reason: "Failed to process Base64 image", scope: "CoverSearchScreen");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error with selected image data: $e")));
        setState(() { _isLoadingPreview = false; _finalImageBytesForSaving = null; });
      }
    }
  }

  Future<void> _processSelectedExternalUrl(String imageUrl) async {
    ErrorHandler.logInfo("Processing External URL: $imageUrl", scope: "CoverSearchScreen");
    setState(() { _isLoadingPreview = true; _finalImageBytesForSaving = null; _selectedExternalImageUrl = imageUrl; _selectedBase64MimeType = null;});
    try {
      final response = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        _finalImageBytesForSaving = response.bodyBytes;
      } else {
        throw Exception('Failed to download preview: ${response.statusCode}');
      }
    } catch (e, s) {
      ErrorHandler.recordError(e, s, reason: "Failed to download image preview from $imageUrl", scope: "CoverSearchScreen");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading image preview: $e")));
      }
      _finalImageBytesForSaving = null; 
    } finally {
      if (mounted) {
        setState(() { _isLoadingPreview = false; });
      }
    }
  }

  String _determineExtensionFromBytes(Uint8List bytes, {String? originalUrl, String? base64MimeType}) {
    String? determinedExtension;

    if (base64MimeType != null) {
        if (base64MimeType == 'jpeg') determinedExtension = 'jpg';
        else if (base64MimeType == 'png') determinedExtension = 'png';
        else if (base64MimeType == 'gif') determinedExtension = 'gif';
        else if (base64MimeType == 'webp') determinedExtension = 'webp';
        // Add other common image MIME types if needed
        else {
          ErrorHandler.logWarning("Unknown Base64 MIME type: $base64MimeType, defaulting extension.", scope: "CoverSearchScreen");
        }
    }

    if (determinedExtension == null && originalUrl != null) {
      try {
        final uri = Uri.parse(originalUrl);
        String pathExtension = p.extension(uri.path).toLowerCase().replaceAll('.', '');
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(pathExtension)) {
            determinedExtension = pathExtension == 'jpeg' ? 'jpg' : pathExtension;
        }
      } catch (_) {/* Malformed URL, ignore */}
    }
    
    if (determinedExtension == null) {
        try {
            final image = img_lib.decodeImage(bytes); // Use aliased import
            if (image != null) {
                // Default to PNG if we had to decode, as it's a good general purpose format
                determinedExtension = 'png'; 
            } else {
                determinedExtension = 'jpg'; // Fallback if decodeImage fails
            }
        } catch (e) {
            ErrorHandler.logWarning("Could not determine image type from bytes using image package, defaulting to jpg. Error: $e", scope: "CoverSearchScreen");
            determinedExtension = 'jpg'; 
        }
    }
    return determinedExtension;
  }

  Future<void> _setCoverFromBytes() async {
    if (_finalImageBytesForSaving == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No image selected or preview failed.")));
      return;
    }

    setState(() { _isSettingCover = true; });

    try {
      await _libraryService.init(); 

      String extension = _determineExtensionFromBytes(
        _finalImageBytesForSaving!, 
        originalUrl: _selectedExternalImageUrl, 
        base64MimeType: _selectedBase64MimeType // Pass the parsed MIME type
      );
      
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String coversDir = p.join(appDocDir.path, 'covers');
      await Directory(coversDir).create(recursive: true);

      if (widget.book.coverImagePath != null && widget.book.coverImagePath!.isNotEmpty) {
        final oldCoverFile = File(widget.book.coverImagePath!);
        if (await oldCoverFile.exists()) {
          try {
            await oldCoverFile.delete();
            ErrorHandler.logInfo("Deleted old cover: ${widget.book.coverImagePath}", scope: "CoverSearchScreen");
          } catch (e,s) {
            ErrorHandler.recordError(e,s, reason: "Failed to delete old cover", scope: "CoverSearchScreen");
          }
        }
      }
      
      final String coverFileName = '${const Uuid().v4()}.$extension';
      final String newCoverFilePath = p.join(coversDir, coverFileName);
      
      await File(newCoverFilePath).writeAsBytes(_finalImageBytesForSaving!);
      
      Book? bookToUpdate = await _libraryService.getBookById(widget.book.id);
      if (bookToUpdate == null) {
        ErrorHandler.logError("Book not found in database to update cover: ${widget.book.id}", scope: "CoverSearchScreen");
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Book not found to update.")));
        setState(() { _isSettingCover = false; });
        return;
      }
      
      bookToUpdate.coverImagePath = newCoverFilePath;
      await _libraryService.updateBook(bookToUpdate); 

      ErrorHandler.logInfo("New cover set: $newCoverFilePath", scope: "CoverSearchScreen");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cover updated!")));
        Navigator.pop(context, true); 
      }
    } catch (e, s) {
      ErrorHandler.recordError(e, s, reason: "Failed to save final cover", scope: "CoverSearchScreen");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving cover: $e")));
      }
    } finally {
      if (mounted) {
        setState(() { _isSettingCover = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Cover: ${widget.book.title}', overflow: TextOverflow.ellipsis),
        actions: [
          if (_finalImageBytesForSaving != null && !_isSettingCover)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: "Set as Cover",
              onPressed: _setCoverFromBytes,
            ),
          if (_isSettingCover)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,)),
            )
        ],
      ),
      body: Column(
        children: [
          if (_finalImageBytesForSaving != null && !_isSettingCover)
            Padding(
              padding: const EdgeInsets.all(kSmallPadding),
              child: Column(
                children: [
                  Text("Selected Image Preview${_selectedExternalImageUrl != null ? ' (from URL)' : _selectedBase64MimeType != null ? ' (from Base64 - ${_selectedBase64MimeType!})' : ''}:"),
                  const SizedBox(height: kSmallPadding),
                  Image.memory(_finalImageBytesForSaving!, height: 100, fit: BoxFit.contain,
                      errorBuilder: (ctx, err, st) => const Text("Error loading preview")),
                  const Divider(),
                ],
              ),
            )
          else if (_isLoadingPreview)
            const Padding(
              padding: EdgeInsets.all(kSmallPadding),
              child: Column(children: [Text("Loading preview..."), SizedBox(height: kSmallPadding), CircularProgressIndicator(), Divider()]),
            )
          else if (_selectedExternalImageUrl != null) 
             Padding(
              padding: const EdgeInsets.all(kSmallPadding),
              child: Column(
                children: [
                  Text("Selected Image URL: ${_selectedExternalImageUrl!.substring(0, _selectedExternalImageUrl!.length > 70 ? 70 : _selectedExternalImageUrl!.length)}..."),
                  const Divider(),
                ],
              ),
            ),

          Expanded(
            child: InAppWebView(
              key: webViewKey,
              initialUrlRequest: URLRequest(url: WebUri(_initialSearchUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useShouldOverrideUrlLoading: true,
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                builtInZoomControls: false, 
                supportZoom: false,
                transparentBackground: true, 
                // Consider setting a desktop user agent for more consistent results
                // userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36",
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                _webViewController?.addJavaScriptHandler(
                  handlerName: 'base64ImageSelected',
                  callback: (args) {
                    if (args.isNotEmpty && args[0] is String) {
                      _processSelectedBase64(args[0]);
                    }
                  },
                );
                _webViewController?.addJavaScriptHandler(
                  handlerName: 'externalImageUrlSelected',
                  callback: (args) {
                    if (args.isNotEmpty && args[0] is String) {
                       _processSelectedExternalUrl(args[0]);
                    }
                  },
                );
              },
              onLoadStop: (controller, url) async {
                await controller.evaluateJavascript(source: _jsToExtractImageOnClick);
                ErrorHandler.logInfo("Injected JS for image selection on $url", scope: "CoverSearchScreen");
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url!;
                if (uri.host.contains("google.com") || uri.host.contains("gstatic.com") || uri.host.contains("google.co")) { 
                  return NavigationActionPolicy.ALLOW;
                }
                // Attempt to open non-Google links externally, or cancel them if they are ads/etc.
                // For simplicity, let's cancel for now to keep user within image search flow.
                ErrorHandler.logInfo("WebView navigation to $uri CANCELLED (not a Google domain)", scope: "CoverSearchScreen");
                return NavigationActionPolicy.CANCEL; 
              },
              onConsoleMessage: (controller, consoleMessage) {
                String levelString = consoleMessage.messageLevel.toString().split('.').last.toUpperCase();
                ErrorHandler.logInfo("WebView CONSOLE: [$levelString] ${consoleMessage.message}", scope: "WebViewConsole");
              },
              onReceivedError: (controller, request, error) {
                 ErrorHandler.logError("WebView Error: type: ${error.type}, description: ${error.description} on URL ${request.url}", scope: "CoverSearchScreen");
              },
               onReceivedHttpError: (controller, request, errorResponse) {
                 ErrorHandler.logError("WebView HTTP Error: ${errorResponse.statusCode} for ${request.url}", scope: "CoverSearchScreen");
               },
            ),
          ),
        ],
      ),
    );
  }
}
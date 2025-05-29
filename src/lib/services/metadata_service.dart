// lib/services/metadata_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:epubx/epubx.dart' as epubx_lib;
import 'package:novelist/models/book.dart';
import 'package:novelist/core/error_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img; // Import the image package

class MetadataService {
  // Helper to determine image extension from img.Image (or fallback)
  // This is tricky without knowing the original format.
  // epubx might load it into a generic Image representation.
  // We'll default to PNG for saving if format isn't obvious.
  static String _getExtensionFromImage(img.Image? image) {
    if (image == null) return 'png';
    // The package:image/image.dart Image class itself doesn't store original mime type.
    // We might have to rely on epubx if it provides mime type separately, or just pick a common format.
    // For simplicity, let's default to PNG as it's lossless and widely supported.
    return 'png'; 
  }

  static Future<Map<String, String?>> extractMetadata(String filePath, BookFormat format) async {
    Map<String, String?> metadata = {'title': null, 'author': null, 'coverPath': null};

    if (format == BookFormat.epub) {
      try {
        File epubFile = File(filePath);
        if (!await epubFile.exists()) {
          ErrorHandler.logWarning("EPUB file not found at path: $filePath", scope: "MetadataService");
          return metadata;
        }
        Uint8List bytes = await epubFile.readAsBytes();
        epubx_lib.EpubBook epubBook = await epubx_lib.EpubReader.readBook(bytes);

        metadata['title'] = epubBook.Title;
        metadata['author'] = epubBook.Author ?? (epubBook.AuthorList?.isNotEmpty == true ? epubBook.AuthorList!.join(', ') : null);

        // --- Extract and save cover image ---
        img.Image? coverImage = epubBook.CoverImage; // This is of type image.Image?

        if (coverImage != null) {
          try {
            // Encode the image.Image to Uint8List (e.g., as PNG)
            Uint8List coverBytes;
            String extension;

            // Attempt to get original format if possible, otherwise default to PNG
            // epubx's EpubContentFile (which CoverImage might be derived from) has ContentType
            // but epubBook.CoverImage itself is just an image.Image.
            // For now, we'll encode as PNG.
            // If epubBook.CoverImageFileName or similar exists and has an extension, we could use that.
            
            // Let's check if epubx provides the original cover file name or mime type via another property
            // A common pattern in epubx is to access files via epubBook.Content.Images or AllFiles
            // For example: epubBook.Schema.Package.Manifest.Items for 'cover' id.
            // However, since epubx gives us an image.Image, we can just re-encode it.

            extension = 'png'; // Default to PNG for saving
            coverBytes = Uint8List.fromList(img.encodePng(coverImage));
            // If you prefer JPEG:
            // extension = 'jpg';
            // coverBytes = Uint8List.fromList(img.encodeJpg(coverImage));

            final Directory appDocDir = await getApplicationDocumentsDirectory();
            final String coversDir = p.join(appDocDir.path, 'covers');
            final Directory dir = Directory(coversDir);
            if (!await dir.exists()) {
              await dir.create(recursive: true);
            }

            final String coverFileName = '${const Uuid().v4()}.$extension';
            final String coverFilePath = p.join(coversDir, coverFileName);
            
            await File(coverFilePath).writeAsBytes(coverBytes);
            metadata['coverPath'] = coverFilePath;
            ErrorHandler.logInfo("Cover image saved to: $coverFilePath", scope: "MetadataService");

          } catch (e, s) {
            ErrorHandler.recordError(e, s, reason: "Error processing/saving cover image for $filePath", scope: "MetadataService");
            metadata['coverPath'] = null;
          }
        } else {
          ErrorHandler.logInfo("No cover image found (epubBook.CoverImage is null) for $filePath", scope: "MetadataService");
        }
        // --- End of cover image extraction ---

      } catch (e, s) {
        ErrorHandler.recordError(e, s, reason: "Error parsing EPUB metadata for $filePath", scope: "MetadataService");
        if (metadata['title'] == null) {
          metadata['title'] = p.basenameWithoutExtension(filePath);
        }
      }
    } else if (format == BookFormat.pdf) {
      // TODO: PDF metadata extraction
      metadata['title'] = p.basenameWithoutExtension(filePath);
    } else {
      metadata['title'] = p.basenameWithoutExtension(filePath);
    }

    return metadata;
  }
}
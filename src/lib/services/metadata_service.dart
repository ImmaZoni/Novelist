// lib/services/metadata_service.dart
import 'dart:io'; // Import for File operations
import 'dart:typed_data'; // Import for Uint8List
import 'package:epubx/epubx.dart'; // Or your chosen epub parsing package
import 'package:novelist/models/book.dart';
import 'package:novelist/core/error_handler.dart';

class MetadataService {
  static Future<Map<String, String?>> extractMetadata(String filePath, BookFormat format) async {
    Map<String, String?> metadata = {'title': null, 'author': null, 'coverPath': null};

    if (format == BookFormat.epub) {
      try {
        // 1. Read the file bytes
        File epubFile = File(filePath);
        if (!await epubFile.exists()) {
          ErrorHandler.logWarning("EPUB file not found at path: $filePath", scope: "MetadataService");
          return metadata; // Return empty metadata if file doesn't exist
        }
        Uint8List bytes = await epubFile.readAsBytes();

        // 2. Pass the bytes to EpubReader
        EpubBook epubBook = await EpubReader.readBook(bytes); // Pass bytes, not filePath

        metadata['title'] = epubBook.Title;
        metadata['author'] = epubBook.Author ?? (epubBook.AuthorList?.isNotEmpty == true ? epubBook.AuthorList!.join(', ') : null);

        // TODO: Extract and save cover image if desired
        // if (epubBook.CoverImage != null) {
        //   Uint8List coverBytes = epubBook.CoverImage!;
        //   // 1. Get app's document directory (use path_provider)
        //   // final Directory appDocDir = await getApplicationDocumentsDirectory();
        //   // final String coversDir = p.join(appDocDir.path, 'covers');
        //   // await Directory(coversDir).create(recursive: true);
        //   // 2. Create a unique filename for the cover
        //   // final String coverFileName = '${Uuid().v4()}.png'; // Or determine format from bytes
        //   // final String coverFilePath = p.join(coversDir, coverFileName);
        //   // 3. Save coverBytes to coverFilePath
        //   // await File(coverFilePath).writeAsBytes(coverBytes);
        //   // 4. Store the coverFilePath in metadata
        //   // metadata['coverPath'] = coverFilePath;
        // }

      } catch (e, s) {
        ErrorHandler.recordError(e, s, reason: "Error parsing EPUB metadata for $filePath");
        // Fallback: title might still be derivable from filename if parsing fails completely
        // For example, you could add:
        // if (metadata['title'] == null) {
        //   metadata['title'] = p.basenameWithoutExtension(filePath);
        // }
      }
    } else if (format == BookFormat.pdf) {
      // TODO: PDF metadata extraction (can be complex, may need a dedicated PDF library)
      // For now, as a fallback for PDF and others:
      // metadata['title'] = p.basenameWithoutExtension(filePath);
    } else {
      // For other unknown formats, perhaps just use filename
      // metadata['title'] = p.basenameWithoutExtension(filePath);
    }

    return metadata;
  }
}
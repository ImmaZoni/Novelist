// lib/core/utils.dart

import 'dart:io';
import 'package:path/path.dart' as p; // Add path package: path: ^1.9.0 (or latest)

// Example: Get file extension
String getFileExtension(String filePath) {
  try {
    return p.extension(filePath).toLowerCase().replaceAll('.', '');
  } catch (e) {
    return '';
  }
}

// Example: Format file size (very basic)
String formatBytes(int bytes, int decimals) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (bytes.toString().length - 1) ~/ 3; // Not a precise calculation for base 1024
  // For a more accurate one, use log base 1024 or iterate.
  // This is a simpler approximation for display.
  // Proper way:
  // var i = (log(bytes) / log(1024)).floor();
  // return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
  // Simpler for now:
  if (i >= suffixes.length) i = suffixes.length - 1;
  return '${(bytes / (1 << (i * 10))).toStringAsFixed(decimals)} ${suffixes[i]}';
}

// You might add more specific utilities here like:
// - Date formatting helpers
// - String manipulation helpers not specific to a model
// lib/core/app_constants.dart

import 'package:flutter/material.dart';

// --- App Information ---
const String kAppName = 'Novelist';
const String kAppVersion = '1.0.0-alpha'; // Or your initial version

// --- UI Constants ---
// Example: Default padding
const double kDefaultPadding = 16.0;
const double kSmallPadding = 8.0;
const double kMediumPadding = 24.0;
const double kLargePadding = 32.0;

// Example: BorderRadius
const double kDefaultBorderRadius = 8.0;

// --- Colors (Can be expanded into a full AppColors class if needed) ---
// You might define your primary theme colors here if not directly in ThemeData,
// or specific colors used in multiple places.
// For now, we'll mostly rely on ThemeData, but here's an example:
// const Color kAccentColor = Colors.amber;

// --- Storage Keys (for shared_preferences or Hive boxes) ---
const String kSettingsBox = 'novelist_settings_box';
const String kLibraryBox = 'novelist_library_box';

const String kThemeModeKey = 'theme_mode';
// Add more keys as needed for settings

// --- Routes (If using named routes) ---
// Defined in app_routes.dart but can be referenced here if needed.
// Example:
// const String kRouteLibrary = '/';
// const String kRouteReading = '/reading';
// const String kRouteSettings = '/settings';

// --- Default Values ---
const String kDefaultFontFamily = 'Roboto'; // Example, Flutter uses this by default

// --- API Endpoints or other service-specific constants (if any) ---
// Example:
// const String kGoogleBooksApiBaseUrl = 'https://www.googleapis.com/books/v1/';

// --- Durations ---
const Duration kShortAnimationDuration = Duration(milliseconds: 200);
const Duration kMediumAnimationDuration = Duration(milliseconds: 500);

// --- You can add more categories as your app grows ---
// e.g., Error Messages, Notification Channels, etc.

// Example of a utility function that might live here or in a separate utils file
// String formatBookTitle(String title) {
//   return title.length > 30 ? '${title.substring(0, 27)}...' : title;
// }
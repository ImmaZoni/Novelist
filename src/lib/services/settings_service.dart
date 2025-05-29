// lib/services/settings_service.dart
import 'package:flutter/material.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:novelist/core/app_constants.dart';
import 'package:novelist/core/error_handler.dart';

enum ReaderThemeSetting { light, dark, sepia, system }

class SettingsService {
  static const String _keyReaderTheme = 'reader_theme_v2'; // Added v2 for new enum
  static const String _keyDefaultFontSize = 'default_font_size_v2'; // Added v2
  static const String _keyReaderFontFamily = 'reader_font_family_v2'; // Added v2

  SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Reader Theme ---
  Future<void> saveReaderTheme(ReaderThemeSetting theme) async {
    await _initPrefs();
    await _prefs!.setString(_keyReaderTheme, theme.name); 
  }

  Future<ReaderThemeSetting> getReaderTheme() async {
    await _initPrefs();
    final String? themeName = _prefs!.getString(_keyReaderTheme);
    if (themeName != null) {
      try {
        return ReaderThemeSetting.values.byName(themeName);
      } catch (_) {
        ErrorHandler.logWarning("Invalid stored reader theme: $themeName, defaulting to system.", scope: "SettingsService");
        return ReaderThemeSetting.system; 
      }
    }
    return ReaderThemeSetting.system; 
  }

  // --- Default Font Size ---
  Future<void> saveDefaultFontSize(double size) async {
    await _initPrefs();
    await _prefs!.setDouble(_keyDefaultFontSize, size);
  }

  Future<double> getDefaultFontSize() async {
    await _initPrefs();
    return _prefs!.getDouble(_keyDefaultFontSize) ?? 16.0; 
  }

  // --- Reader Font Family ---
  Future<void> saveReaderFontFamily(String fontFamily) async {
    await _initPrefs();
    await _prefs!.setString(_keyReaderFontFamily, fontFamily);
  }

  Future<String> getReaderFontFamily() async {
    await _initPrefs();
    return _prefs!.getString(_keyReaderFontFamily) ?? 'Default'; 
  }
  
  // --- App Theme (controls MaterialApp light/dark/system) ---
  Future<void> saveAppThemeMode(ThemeMode themeMode) async {
    await _initPrefs();
    await _prefs!.setString(kThemeModeKey, themeMode.name);
  }

  Future<ThemeMode> getAppThemeMode() async {
    await _initPrefs();
    final String? themeName = _prefs!.getString(kThemeModeKey);
    if (themeName != null) {
      try {
        return ThemeMode.values.byName(themeName);
      } catch (_) {
        ErrorHandler.logWarning("Invalid stored app theme: $themeName, defaulting to system.", scope: "SettingsService");
        return ThemeMode.system; 
      }
    }
    return ThemeMode.system;
  }
}
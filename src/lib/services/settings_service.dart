// lib/services/settings_service.dart
import 'package:flutter/material.dart'; // For ThemeMode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:novelist/core/app_constants.dart'; // For keys

// Define an enum for our reader themes if not using ThemeMode directly for all
enum ReaderThemeSetting { light, dark, sepia, system }

class SettingsService {
  static const String _keyReaderTheme = 'reader_theme';
  static const String _keyDefaultFontSize = 'default_font_size';

  SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Reader Theme ---
  Future<void> saveReaderTheme(ReaderThemeSetting theme) async {
    await _initPrefs();
    await _prefs!.setString(_keyReaderTheme, theme.name); // Store enum by its name
  }

  Future<ReaderThemeSetting> getReaderTheme() async {
    await _initPrefs();
    final String? themeName = _prefs!.getString(_keyReaderTheme);
    if (themeName != null) {
      try {
        return ReaderThemeSetting.values.byName(themeName);
      } catch (_) {
        return ReaderThemeSetting.system; // Default if stored value is invalid
      }
    }
    return ReaderThemeSetting.system; // Default
  }

  // --- Default Font Size ---
  Future<void> saveDefaultFontSize(double size) async {
    await _initPrefs();
    await _prefs!.setDouble(_keyDefaultFontSize, size);
  }

  Future<double> getDefaultFontSize() async {
    await _initPrefs();
    return _prefs!.getDouble(_keyDefaultFontSize) ?? 16.0; // Default font size
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
        return ThemeMode.system; 
      }
    }
    return ThemeMode.system;
  }
}
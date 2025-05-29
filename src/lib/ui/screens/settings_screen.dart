// lib/ui/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:novelist/services/settings_service.dart';
import 'package:novelist/core/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  
  ReaderThemeSetting _currentReaderTheme = ReaderThemeSetting.system;
  double _currentDefaultFontSize = 16.0;
  String _currentReaderFontFamily = 'Default';
  ThemeMode _currentAppThemeMode = ThemeMode.system;

  bool _isLoading = true;

  final List<String> _fontFamilyOptions = const ['Default', 'Serif', 'Sans-Serif', 'Times New Roman', 'Arial', 'Georgia'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() { _isLoading = true; });
    _currentReaderTheme = await _settingsService.getReaderTheme();
    _currentDefaultFontSize = await _settingsService.getDefaultFontSize();
    _currentReaderFontFamily = await _settingsService.getReaderFontFamily();
    _currentAppThemeMode = await _settingsService.getAppThemeMode();
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _updateReaderTheme(ReaderThemeSetting? newTheme) async {
    if (newTheme != null && newTheme != _currentReaderTheme) {
      await _settingsService.saveReaderTheme(newTheme);
      if (mounted) {
        setState(() { _currentReaderTheme = newTheme; });
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reader theme saved. Changes apply when reader is opened/reopened.')),
        );
      }
    }
  }

  Future<void> _updateDefaultFontSize(double newSize) async {
    // This is called on onChangeEnd of slider
    if (newSize != _currentDefaultFontSize) {
      await _settingsService.saveDefaultFontSize(newSize);
      if (mounted) {
        // No need to call setState for _currentDefaultFontSize here as slider's onChanged does it.
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default font size saved.')),
        );
      }
    }
  }

  Future<void> _updateReaderFontFamily(String? newFontFamily) async {
    if (newFontFamily != null && newFontFamily != _currentReaderFontFamily) {
      await _settingsService.saveReaderFontFamily(newFontFamily);
      if (mounted) {
        setState(() { _currentReaderFontFamily = newFontFamily; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reader font family saved. Changes apply when reader is opened/reopened.')),
        );
      }
    }
  }
  
  Future<void> _updateAppThemeMode(ThemeMode? newMode) async {
    if (newMode != null && newMode != _currentAppThemeMode) {
      await _settingsService.saveAppThemeMode(newMode);
      if (mounted) {
        setState(() { _currentAppThemeMode = newMode; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App theme change will apply on next app start.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(kDefaultPadding),
              children: <Widget>[
                Text("Reader Settings", style: Theme.of(context).textTheme.titleLarge),
                const Divider(),
                
                ListTile(
                  title: const Text('Default Reader Theme'),
                  trailing: DropdownButton<ReaderThemeSetting>(
                    value: _currentReaderTheme,
                    items: ReaderThemeSetting.values.map((ReaderThemeSetting theme) {
                      return DropdownMenuItem<ReaderThemeSetting>(
                        value: theme,
                        child: Text(theme.name[0].toUpperCase() + theme.name.substring(1)),
                      );
                    }).toList(),
                    onChanged: _updateReaderTheme,
                  ),
                ),

                ListTile(
                  title: Text('Default Font Size: ${_currentDefaultFontSize.toStringAsFixed(0)}'),
                ),
                Slider(
                  value: _currentDefaultFontSize,
                  min: 10.0,
                  max: 30.0,
                  divisions: 20, 
                  label: _currentDefaultFontSize.round().toString(),
                  onChanged: (double value) { 
                    setState(() { _currentDefaultFontSize = value; }); 
                  },
                  onChangeEnd: _updateDefaultFontSize, 
                ),

                ListTile(
                  title: const Text('Reader Font Family'),
                  trailing: DropdownButton<String>(
                    value: _fontFamilyOptions.contains(_currentReaderFontFamily) 
                           ? _currentReaderFontFamily 
                           : 'Default', // Fallback if saved value is not in options
                    items: _fontFamilyOptions.map((String fontFamily) {
                      return DropdownMenuItem<String>(
                        value: fontFamily,
                        child: Text(fontFamily),
                      );
                    }).toList(),
                    onChanged: _updateReaderFontFamily,
                  ),
                ),

                const SizedBox(height: kMediumPadding),
                Text("Application Settings", style: Theme.of(context).textTheme.titleLarge),
                const Divider(),
                ListTile(
                  title: const Text('App Theme'),
                  trailing: DropdownButton<ThemeMode>(
                    value: _currentAppThemeMode,
                    items: ThemeMode.values.map((ThemeMode mode) {
                      return DropdownMenuItem<ThemeMode>(
                        value: mode,
                        child: Text(mode.name[0].toUpperCase() + mode.name.substring(1)),
                      );
                    }).toList(),
                    onChanged: _updateAppThemeMode,
                  ),
                ),
              ],
            ),
    );
  }
}
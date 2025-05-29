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
  ThemeMode _currentAppThemeMode = ThemeMode.system; // For overall app theme

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() { _isLoading = true; });
    _currentReaderTheme = await _settingsService.getReaderTheme();
    _currentDefaultFontSize = await _settingsService.getDefaultFontSize();
    _currentAppThemeMode = await _settingsService.getAppThemeMode();
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _updateReaderTheme(ReaderThemeSetting? newTheme) async {
    if (newTheme != null) {
      await _settingsService.saveReaderTheme(newTheme);
      if (mounted) {
        setState(() {
          _currentReaderTheme = newTheme;
        });
        // Optionally, provide immediate feedback or tell user to restart reader/app for some settings
      }
    }
  }

  Future<void> _updateDefaultFontSize(double newSize) async {
    await _settingsService.saveDefaultFontSize(newSize);
    if (mounted) {
      setState(() {
        _currentDefaultFontSize = newSize;
      });
    }
  }
  
  Future<void> _updateAppThemeMode(ThemeMode? newMode) async {
    if (newMode != null) {
      await _settingsService.saveAppThemeMode(newMode);
      if (mounted) {
        setState(() {
          _currentAppThemeMode = newMode;
        });
        // This change might require a way to notify MaterialApp to rebuild.
        // Often done via a ChangeNotifierProvider at the root or by restarting.
        // For now, saving it is the first step.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App theme change will apply on next app start (or with theme controller).')),
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
                
                // Default Reader Theme Setting
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

                // Default Font Size Setting
                ListTile(
                  title: Text('Default Font Size: ${_currentDefaultFontSize.toStringAsFixed(0)}'),
                ),
                Slider(
                  value: _currentDefaultFontSize,
                  min: 10.0,
                  max: 30.0,
                  divisions: 20, // (30-10) / 1.0
                  label: _currentDefaultFontSize.round().toString(),
                  onChanged: (double value) {
                    // setState is called within _updateDefaultFontSize after saving
                    _updateDefaultFontSize(value);
                  },
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

                // Add more settings here later
              ],
            ),
    );
  }
}
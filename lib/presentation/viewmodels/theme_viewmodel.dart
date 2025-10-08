import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/sync_service.dart';

class ThemeViewModel extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  final SyncService _syncService = SyncService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ThemeMode get themeMode => _themeMode;

  ThemeViewModel() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    _prefs = await SharedPreferences.getInstance();
    
    // First try to load from user_theme_preference (for AWS sync)
    String? savedTheme = _prefs.getString('user_theme_preference');
    
    // If not found, try the regular theme_mode key
    if (savedTheme == null) {
      savedTheme = _prefs.getString(_themeKey);
    }
    
    if (savedTheme != null) {
      // Convert string to ThemeMode
      if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedTheme == 'system') {
        _themeMode = ThemeMode.system;
      } else {
        // Fallback for old format (ThemeMode.light.toString() etc.)
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedTheme,
          orElse: () => ThemeMode.system,
        );
      }
    } else {
      // No theme preference found, use system as default
      _themeMode = ThemeMode.system;
      // Initialize the user_theme_preference key with default value
      await _prefs.setString('user_theme_preference', 'system');
    }
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final themeString = _themeModeToString(mode);
    
    // Save to both keys
    await Future.wait([
      _prefs.setString(_themeKey, mode.toString()),
      _prefs.setString('user_theme_preference', themeString),
    ]);
    
    // Sync theme preference to AWS if user is signed in
    if (_auth.currentUser != null) {
      await _syncService.updateUserProfileInAWS(
        themePreference: themeString,
      );
    }
    
    notifyListeners();
  }
  
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

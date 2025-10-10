import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/sync_service.dart';
import '../../data/services/sqlite_service.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final SyncService _syncService = SyncService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SQLiteService _sqliteService = SQLiteService();

  ThemeMode get themeMode => _themeMode;

  ThemeViewModel() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final savedTheme = await _sqliteService.getThemePreference();
    
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
      // Initialize the theme preference with default value
      await _sqliteService.setThemePreference('system');
    }
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final themeString = _themeModeToString(mode);
    
    // Save to SQLite
    await _sqliteService.setThemePreference(themeString);
    
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

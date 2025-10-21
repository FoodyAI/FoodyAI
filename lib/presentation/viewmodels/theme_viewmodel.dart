import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/sync_service.dart';
import '../../data/services/sqlite_service.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isChanging = false;
  final SyncService _syncService = SyncService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SQLiteService _sqliteService = SQLiteService();

  ThemeMode get themeMode => _themeMode;
  bool get isChanging => _isChanging;

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
          orElse: () => ThemeMode.light,
        );
      }
    } else {
      // No theme preference found, use light as default
      _themeMode = ThemeMode.light;
      // Initialize the theme preference with default value
      await _sqliteService.setThemePreference('light');
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode || _isChanging) return;

    _isChanging = true;
    notifyListeners();

    // Optimistic UI: Update immediately for instant feedback
    final previousMode = _themeMode;
    _themeMode = mode;
    _isChanging = false;
    notifyListeners(); // Notify immediately for instant UI update

    final themeString = _themeModeToString(mode);

    try {
      // Save to SQLite in background
      await _sqliteService.setThemePreference(themeString);

      // Sync theme preference to AWS if user is signed in
      // Uses new SyncService: tries immediate sync if online, marks for later if offline
      if (_auth.currentUser != null) {
        _syncService.trySyncTheme(themeString).catchError((error) {
          print('❌ ThemeViewModel: Failed to sync theme to AWS: $error');
          // Error is already logged by SyncService, theme will be marked for retry
          return false;
        });
      }
    } catch (e) {
      print('❌ ThemeViewModel: Failed to save theme preference: $e');
      // Rollback on error
      _themeMode = previousMode;
      notifyListeners();

      // Show error message to user
      _showThemeError();
    }
  }

  void _showThemeError() {
    // This could be improved with a proper error handling system
    print(
        '⚠️ ThemeViewModel: Theme change failed, rolled back to previous theme');
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

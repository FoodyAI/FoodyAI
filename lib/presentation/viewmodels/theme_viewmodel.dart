import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/sync_service.dart';
import '../../data/services/sqlite_service.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
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
      
      // Sync theme preference to AWS if user is signed in (in background)
      if (_auth.currentUser != null) {
        _syncService.updateUserProfileInAWS(
          themePreference: themeString,
        ).catchError((error) {
          print('❌ ThemeViewModel: Failed to sync theme to AWS: $error');
          // Could show a subtle error message here if needed
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
    print('⚠️ ThemeViewModel: Theme change failed, rolled back to previous theme');
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

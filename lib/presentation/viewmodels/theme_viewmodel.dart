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
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _prefs.setString(_themeKey, mode.toString());
    
    // Sync theme preference to AWS if user is signed in
    if (_auth.currentUser != null) {
      await _syncService.updateThemePreferenceInAWS(
        _themeModeToString(mode),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/viewmodels/theme_viewmodel.dart';

/// Optimized theme provider that minimizes rebuilds
class OptimizedThemeProvider extends StatelessWidget {
  final Widget child;

  const OptimizedThemeProvider({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeViewModel>(
      builder: (context, themeVM, _) {
        return AnimatedTheme(
          data: _getThemeData(themeVM.themeMode),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: child,
        );
      },
    );
  }

  ThemeData _getThemeData(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return _lightTheme;
      case ThemeMode.dark:
        return _darkTheme;
      case ThemeMode.system:
        // Use system theme - this will be handled by MaterialApp
        return _lightTheme; // Fallback
    }
  }

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    // Add your light theme properties here
  );

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    // Add your dark theme properties here
  );
}

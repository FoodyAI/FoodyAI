import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary =
      Color(0xFF2E7D32); // Deeper, more sophisticated green
  static const Color primaryDark = Color(0xFF1B5E20); // Deep forest green
  static const Color primaryLight = Color(0xFF81C784); // Light green

  // Accent Colors
  static const Color accent = Color(0xFFFF6B6B); // Warm coral for CTAs
  static const Color accentDark = Color(0xFFE53935); // Darker coral
  static const Color accentLight = Color(0xFFFF8A80); // Lighter coral

  // Background Colors
  static const Color background =
      Color(0xFFF8F9FA); // Slightly warmer background
  static const Color surface = Colors.white;

  // Text Colors
  static const Color textPrimary =
      Color(0xFF2C3E50); // Darker, more readable text
  static const Color textSecondary = Color(0xFF546E7A); // Softer secondary text
  static const Color textHint = Color(0xFF90A4AE); // Softer hint text

  // Status Colors
  static const Color success = Color(0xFF43A047); // Slightly softer green
  static const Color warning = Color(0xFFFFB300); // Warmer amber
  static const Color info = Color(0xFF1E88E5); // Deeper blue
  static const Color error = Color(0xFFD32F2F); // Brighter red

  // UI Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // Grey Shades
  static const Color grey100 = Color(0xFFF8F9FA); // Warmer light grey
  static const Color grey200 = Color(0xFFE9ECEF); // Softer grey
  static const Color grey300 = Color(0xFFDEE2E6); // Light grey
  static const Color grey400 = Color(0xFFCED4DA); // Medium grey
  static const Color grey500 = Color(0xFFADB5BD); // Standard grey
  static const Color grey600 = Color(0xFF6C757D); // Dark grey
  static const Color grey800 = Color(0xFF343A40); // Very dark grey

  // Feature Colors
  static const Color camera = Color(0xFF1E88E5); // Deeper blue
  static const Color nutrition = Color(0xFF43A047); // Matching success
  static const Color history = Color(0xFFFF9800); // Warm orange
  static const Color profile = Color(0xFFEC407A); // Softer pink

  // Additional Colors
  static const Color orange = Color(0xFFFF9800); // Warm orange
  static const Color blue = Color(0xFF1E88E5); // Deeper blue
  static const Color green = Color(0xFF43A047); // Matching success

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF1B5E20), // Deep forest green
    Color(0xFF43A047), // Fresh green
  ];

  // New Gradients
  static const List<Color> accentGradient = [
    Color(0xFFFF6B6B), // Warm coral
    Color(0xFFFF8A80), // Light coral
  ];

  static const List<Color> successGradient = [
    Color(0xFF2E7D32), // Deep green
    Color(0xFF66BB6A), // Light green
  ];

  static const List<Color> infoGradient = [
    Color(0xFF1565C0), // Deep blue
    Color(0xFF42A5F5), // Light blue
  ];

  // Opacity Helpers
  static Color withOpacity(Color color, double opacity) =>
      color.withOpacity(opacity);
}

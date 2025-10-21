import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors - Fresh, vibrant green (iOS Health inspired)
  static const Color primary = Color(0xFF34C759); // Vibrant iOS green
  static const Color primaryDark = Color(0xFF248A3D); // Rich forest green
  static const Color primaryLight = Color(0xFF5DD879); // Bright mint green

  // Accent Colors - Modern coral/peach for contrast
  static const Color accent = Color(0xFFFF6B6B); // Vibrant coral
  static const Color accentDark = Color(0xFFE85D5D); // Deep coral
  static const Color accentLight = Color(0xFFFF8F8F); // Soft peach

  // Background Colors - Subtle, modern
  static const Color background = Color(0xFFF5F7FA); // Soft blue-grey
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color darkBackground = Color(0xFF0D0D0D); // True dark
  static const Color darkSurface = Color(0xFF1C1C1E); // iOS dark surface

  // Text Colors - High contrast, readable
  static const Color textPrimary = Color(0xFF1C1C1E); // Near black
  static const Color textSecondary = Color(0xFF6C6C70); // Medium grey
  static const Color textHint = Color(0xFF999999); // Light grey
  static const Color darkTextPrimary = Color(0xFFF5F5F7); // Near white
  static const Color darkTextSecondary = Color(0xFFAEAEB2); // Light grey
  static const Color darkTextHint = Color(0xFF8E8E93); // Medium grey

  // Status Colors - Vibrant and clear
  static const Color success = Color(0xFF34C759); // iOS green
  static const Color warning = Color(0xFFFFCC00); // Vibrant amber
  static const Color info = Color(0xFF007AFF); // iOS blue
  static const Color error = Color(0xFFFF3B30); // iOS red

  // UI Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;
  static const Color darkCardBackground = Color(0xFF2C2C2E); // iOS card dark
  static const Color darkDivider = Color(0xFF38383A); // Subtle divider

  // Grey Shades - iOS System Grays
  static const Color grey100 = Color(0xFFF2F2F7); // System grey 6
  static const Color grey200 = Color(0xFFE5E5EA); // System grey 5
  static const Color grey300 = Color(0xFFD1D1D6); // System grey 4
  static const Color grey400 = Color(0xFFC7C7CC); // System grey 3
  static const Color grey500 = Color(0xFFAEAEB2); // System grey 2
  static const Color grey600 = Color(0xFF8E8E93); // System grey
  static const Color grey800 = Color(0xFF48484A); // Dark grey

  // Feature Colors - Vibrant, glassmorphic-friendly
  static const Color camera = Color(0xFF007AFF); // iOS blue
  static const Color nutrition = Color(0xFF34C759); // iOS green
  static const Color history = Color(0xFFFF9500); // iOS orange
  static const Color profile = Color(0xFFFF2D55); // iOS pink

  // Additional Colors - Modern, vibrant palette
  static const Color orange = Color(0xFFFF9500); // iOS orange
  static const Color blue = Color(0xFF007AFF); // iOS blue
  static const Color green = Color(0xFF34C759); // iOS green
  static const Color purple = Color(0xFFAF52DE); // iOS purple
  static const Color pink = Color(0xFFFF2D55); // iOS pink
  static const Color teal = Color(0xFF5AC8FA); // iOS teal
  static const Color indigo = Color(0xFF5856D6); // iOS indigo
  static const Color yellow = Color(0xFFFFCC00); // iOS yellow

  // Gradient Colors - Smooth, modern gradients
  static const List<Color> primaryGradient = [
    Color(0xFF34C759), // Vibrant green
    Color(0xFF30D158), // Bright green
  ];

  static const List<Color> accentGradient = [
    Color(0xFFFF6B6B), // Coral
    Color(0xFFFF8F8F), // Light coral
  ];

  static const List<Color> successGradient = [
    Color(0xFF34C759), // Green
    Color(0xFF32D74B), // Bright green
  ];

  static const List<Color> infoGradient = [
    Color(0xFF007AFF), // Blue
    Color(0xFF0A84FF), // Bright blue
  ];

  static const List<Color> warningGradient = [
    Color(0xFFFFCC00), // Yellow
    Color(0xFFFFD426), // Bright yellow
  ];

  static const List<Color> errorGradient = [
    Color(0xFFFF3B30), // Red
    Color(0xFFFF453A), // Bright red
  ];

  // Glassmorphic Colors - For frosted glass effects
  static const Color glassLight = Color(0x40FFFFFF); // 25% white
  static const Color glassDark = Color(0x30000000); // 19% black
  static const Color glassBorder = Color(0x30FFFFFF); // 19% white border

  // Nutrition Specific Colors - For food categories
  static const Color protein = Color(0xFFFF3B30); // Red
  static const Color carbs = Color(0xFFFFCC00); // Yellow
  static const Color fat = Color(0xFFFF9500); // Orange
  static const Color fiber = Color(0xFF34C759); // Green
  static const Color vitamins = Color(0xFFAF52DE); // Purple
  static const Color minerals = Color(0xFF007AFF); // Blue

  // Opacity Helpers
  static Color withOpacity(Color color, double opacity) =>
      color.withOpacity(opacity);
}

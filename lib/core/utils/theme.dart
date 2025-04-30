import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static final lightColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.primaryLight,
    error: AppColors.error,
    background: AppColors.background,
    surface: AppColors.surface,
  );

  static final darkColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.primaryLight,
    error: AppColors.error,
    brightness: Brightness.dark,
  );

  static final lightTheme = ThemeData(
    colorScheme: lightColorScheme,
    useMaterial3: true,
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: lightColorScheme.primaryContainer,
      foregroundColor: lightColorScheme.onPrimaryContainer,
    ),
  );

  static final darkTheme = ThemeData(
    colorScheme: darkColorScheme,
    useMaterial3: true,
    textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: darkColorScheme.primaryContainer,
      foregroundColor: darkColorScheme.onPrimaryContainer,
    ),
  );
}

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
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    onBackground: AppColors.darkTextPrimary,
    onSurface: AppColors.darkTextPrimary,
    brightness: Brightness.dark,
  );

  static final lightTheme = ThemeData(
    colorScheme: lightColorScheme,
    useMaterial3: true,
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.white),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 2,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.grey300,
    ),
  );

  static final darkTheme = ThemeData(
    colorScheme: darkColorScheme,
    useMaterial3: true,
    textTheme: GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.white),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.darkCardBackground,
      elevation: 2,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkDivider,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.darkTextSecondary,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      titleTextStyle: TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: AppColors.darkTextSecondary,
        fontSize: 16,
      ),
    ),
  );
}

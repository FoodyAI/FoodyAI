import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: MaterialColor(AppColors.primary.value, const {
        50: AppColors.primaryLight,
        100: AppColors.primaryLight,
        200: AppColors.primaryLight,
        300: AppColors.primaryLight,
        400: AppColors.primaryLight,
        500: AppColors.primary,
        600: AppColors.primary,
        700: AppColors.primary,
        800: AppColors.primaryDark,
        900: AppColors.primaryDark,
      }),
      brightness: Brightness.light,
      // Add your theme configurations here
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: MaterialColor(AppColors.primary.value, const {
        50: AppColors.primaryLight,
        100: AppColors.primaryLight,
        200: AppColors.primaryLight,
        300: AppColors.primaryLight,
        400: AppColors.primaryLight,
        500: AppColors.primary,
        600: AppColors.primary,
        700: AppColors.primary,
        800: AppColors.primaryDark,
        900: AppColors.primaryDark,
      }),
      brightness: Brightness.dark,
      // Add your theme configurations here
    );
  }
}

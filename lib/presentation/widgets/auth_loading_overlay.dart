import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';

/// Full-screen loading overlay with Lottie animation
/// Used during authentication operations (sign-in/sign-out)
class AuthLoadingOverlay extends StatelessWidget {
  final String? message;

  const AuthLoadingOverlay({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDarkMode
          ? Colors.black.withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie animation
            SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(
                'assets/animations/auth/loading.json',
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
            const SizedBox(height: 24),
            // Optional message
            if (message != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? AppColors.white : AppColors.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Show loading overlay as a dialog
  static void showLoading(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => PopScope(
        canPop: false, // Prevent back button
        child: AuthLoadingOverlay(message: message),
      ),
    );
  }

  /// Hide loading overlay
  static void hideLoading(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}

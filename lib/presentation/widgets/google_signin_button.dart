import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? label;
  final bool isFullWidth;
  final bool isCompact;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.label,
    this.isFullWidth = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final button = ElevatedButton.icon(
      onPressed: isLoading ? null : (onPressed ?? () => _handleSignIn(context)),
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            )
          : Image.asset(
              'assets/google_logo.png',
              height: isCompact ? 16 : 20,
            ),
      label: Text(
        label ?? 'Sign in with Google',
        style: TextStyle(
          fontSize: isCompact ? 13 : 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode
            ? Theme.of(context).colorScheme.surface
            : AppColors.white,
        foregroundColor: isDarkMode ? AppColors.white : AppColors.textPrimary,
        padding: isCompact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
          side: BorderSide(
            color: isDarkMode
                ? AppColors.withOpacity(AppColors.primary, 0.2)
                : AppColors.grey300,
            width: 1,
          ),
        ),
        elevation: 0,
      ),
    );

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  void _handleSignIn(BuildContext context) {
    // Show coming soon message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign-In coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Shared function to show Google Sign-In coming soon message
void showGoogleSignInComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Google Sign-In coming soon!'),
      duration: Duration(seconds: 2),
    ),
  );
}

/// Dialog to show sign-in benefits and prompt
class SignInDialog extends StatelessWidget {
  const SignInDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.rightToBracket,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text('Sign In to Foody'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sign in to:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildBenefit(isDark, FontAwesomeIcons.cloudArrowUp,
              'Sync data across devices'),
          const SizedBox(height: 8),
          _buildBenefit(isDark, FontAwesomeIcons.shieldHalved,
              'Backup your food history'),
          const SizedBox(height: 8),
          _buildBenefit(
              isDark, FontAwesomeIcons.chartLine, 'Access advanced analytics'),
          const SizedBox(height: 20),
          const GoogleSignInButton(isFullWidth: true),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Maybe Later',
            style: TextStyle(color: colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefit(bool isDark, IconData icon, String text) {
    return Row(
      children: [
        FaIcon(
          icon,
          size: 16,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

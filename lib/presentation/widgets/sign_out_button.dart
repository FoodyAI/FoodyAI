import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'auth_loading_overlay.dart';

class SignOutButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? label;
  final bool isFullWidth;
  final bool isCompact;

  const SignOutButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.label,
    this.isFullWidth = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: FaIcon(
        FontAwesomeIcons.rightFromBracket,
        size: isCompact ? 12 : 16,
      ),
      label: Text(
        label ?? 'Sign Out',
        style: TextStyle(
          fontSize: isCompact ? 13 : 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error.withValues(alpha: 0.1),
        foregroundColor: AppColors.error,
        padding: isCompact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
          side: BorderSide(
            color: AppColors.error.withValues(alpha: 0.3),
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
}

class SignOutButtonWithAuth extends StatelessWidget {
  final bool isFullWidth;
  final bool isCompact;
  final bool showConfirmation;

  const SignOutButtonWithAuth({
    super.key,
    this.isFullWidth = false,
    this.isCompact = false,
    this.showConfirmation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, child) {
        return SignOutButton(
          isFullWidth: isFullWidth,
          isCompact: isCompact,
          isLoading: authVM.isLoading,
          onPressed: () => _handleSignOut(context, authVM),
        );
      },
    );
  }

  Future<void> _handleSignOut(
      BuildContext context, AuthViewModel authVM) async {
    final messenger = ScaffoldMessenger.of(context);

    if (showConfirmation) {
      final shouldSignOut = await _showSignOutConfirmation(context);
      if (!shouldSignOut) return;
    }

    // Show loading overlay immediately after confirmation
    if (context.mounted) {
      AuthLoadingOverlay.showLoading(
        context,
        message: 'Signing out...',
      );
    }

    try {
      // ignore: use_build_context_synchronously
      await authVM.signOut(context);

      // Hide loading overlay - navigation will handle this in most cases
      // but we add it here as a safety net
      if (context.mounted) {
        AuthLoadingOverlay.hideLoading(context);
      }
    } catch (e) {
      // Hide loading overlay on error
      if (context.mounted) {
        AuthLoadingOverlay.hideLoading(context);
      }

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Sign out failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<bool> _showSignOutConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.rightFromBracket,
                    color: AppColors.error,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text('Sign Out'),
                ],
              ),
              content: const Text(
                'Are you sure you want to sign out? You can sign back in anytime.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDarkMode
                          ? AppColors.grey600
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Sign Out'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

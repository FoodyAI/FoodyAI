import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    Widget button = ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: isCompact ? 12 : 16,
              height: isCompact ? 12 : 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            )
          : FaIcon(
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
        backgroundColor: AppColors.error.withOpacity(0.1),
        foregroundColor: AppColors.error,
        padding: isCompact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
          side: BorderSide(
            color: AppColors.error.withOpacity(0.3),
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

  const SignOutButtonWithAuth({
    super.key,
    this.isFullWidth = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, child) {
        return SignOutButton(
          isFullWidth: isFullWidth,
          isCompact: isCompact,
          isLoading: authVM.isLoading,
          onPressed: () async {
            await authVM.signOut();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signed out successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
        );
      },
    );
  }
}

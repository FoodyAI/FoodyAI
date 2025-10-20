import 'package:flutter/material.dart';
import 'user_state_service.dart';
import '../core/constants/app_colors.dart';
import '../config/routes/navigation_service.dart';

class AuthenticationFlow {
  final UserStateService _userStateService = UserStateService();

  /// Handle post-authentication navigation based on user state
  /// Note: Loading overlay is now handled by the sign-in button, not here
  Future<void> handlePostAuthNavigation(
    BuildContext context, {
    required String userDisplayName,
    required String userEmail,
    bool showLoadingDialog = false, // Deprecated - loading is handled by caller
    bool useLocalCache = false,
  }) async {
    if (!context.mounted) return;

    try {
      // Determine user state
      final userStateResult = await _userStateService.determineUserState(
        useLocalCache: useLocalCache,
      );

      if (!context.mounted) return;

      // Simple navigation logic
      if (userStateResult.state == UserState.returningComplete) {
        // User exists in AWS with complete profile → Home
        await _navigateToHome(context,
            userDisplayName: userDisplayName, userEmail: userEmail);
      } else {
        // First time or incomplete → Onboarding
        await _navigateToOnboarding(context,
            userDisplayName: userDisplayName, userEmail: userEmail);
      }
    } catch (e) {
      if (context.mounted) {
        await _handleUnexpectedError(context, e);
      }
    }
  }

  /// Navigate to home with welcome message
  Future<void> _navigateToHome(
    BuildContext context, {
    required String userDisplayName,
    required String userEmail,
  }) async {
    _showSnackBar(
      context,
      'Welcome back, ${userDisplayName.isNotEmpty ? userDisplayName : userEmail}!',
      AppColors.success,
    );

    NavigationService.navigateToHome();
  }

  /// Navigate to onboarding
  Future<void> _navigateToOnboarding(
    BuildContext context, {
    required String userDisplayName,
    required String userEmail,
  }) async {
    final displayName =
        userDisplayName.isNotEmpty ? userDisplayName : userEmail;
    _showSnackBar(
        context, 'Welcome to Foody, $displayName!', AppColors.success);

    NavigationService.navigateToOnboarding(isFirstTimeUser: true);
  }

  /// Handle unexpected errors
  Future<void> _handleUnexpectedError(
      BuildContext context, dynamic error) async {
    _showSnackBar(
        context, 'An error occurred. Please try again.', AppColors.error);
  }

  /// Show snackbar with message
  void _showSnackBar(
      BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Quick check if user should go to home or onboarding (for app startup)
  Future<bool> shouldShowHome() async {
    try {
      final result = await _userStateService.determineUserState();
      return result.state == UserState.returningComplete;
    } catch (e) {
      print('⚠️ AuthenticationFlow: Error checking home state: $e');
      return false;
    }
  }

  /// Force refresh user state
  Future<UserStateResult> refreshUserState() async {
    return _userStateService.refreshUserState();
  }

  /// Handle post-logout navigation (sign out or account deletion)
  Future<void> handlePostLogoutNavigation(
    BuildContext context, {
    String? message,
    bool isAccountDeletion = false,
  }) async {
    if (!context.mounted) {
      return;
    }

    try {
      // Show appropriate message
      final logoutMessage = message ??
          (isAccountDeletion
              ? 'Account deleted successfully'
              : 'Signed out successfully');

      // Clear navigation stack and go to intro screen FIRST
      await NavigationService.navigateToIntro();

      // Show snackbar AFTER navigation completes on the new screen
      // Add a delay to ensure:
      // 1. Intro screen is fully rendered
      // 2. Any loading overlays are dismissed
      await Future.delayed(const Duration(milliseconds: 800));

      final newContext = NavigationService.currentContext;
      if (newContext != null && newContext.mounted) {
        _showSnackBar(
          newContext,
          logoutMessage,
          isAccountDeletion ? AppColors.success : AppColors.primary,
        );
      }
    } catch (e) {
      print('❌ AuthenticationFlow: Error in post-logout navigation: $e');

      // Fallback navigation
      if (context.mounted) {
        NavigationService.navigateToIntro();
      }
    }
  }

  /// Navigate to intro screen (used for sign out and account deletion)
  Future<void> navigateToIntro(BuildContext context, {String? message}) async {
    if (!context.mounted) return;

    if (message != null) {
      _showSnackBar(context, message, AppColors.primary);
    }

    NavigationService.navigateToIntro();
  }
}

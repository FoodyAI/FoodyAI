import 'package:flutter/material.dart';
import 'user_state_service.dart';
import '../core/constants/app_colors.dart';
import '../config/routes/navigation_service.dart';

class AuthenticationFlow {
  final UserStateService _userStateService = UserStateService();

  /// Handle post-authentication navigation based on user state
  Future<void> handlePostAuthNavigation(
    BuildContext context, {
    required String userDisplayName,
    required String userEmail,
    bool showLoadingDialog = true,
    bool useLocalCache = false,
  }) async {
    if (!context.mounted) return;

    OverlayEntry? loadingOverlay;

    try {
      // Show loading dialog
      if (showLoadingDialog) {
        loadingOverlay =
            _showLoadingOverlay(context, 'Checking your profile...');
      }

      // Determine user state
      final userStateResult = await _userStateService.determineUserState(
        useLocalCache: useLocalCache,
      );

      // Hide loading dialog
      loadingOverlay?.remove();
      loadingOverlay = null;

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
      loadingOverlay?.remove();
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

  /// Show loading overlay
  OverlayEntry _showLoadingOverlay(BuildContext context, String message) {
    final overlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
    return overlay;
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

  /// Create smooth slide transition
  PageRouteBuilder<T> _createSlideTransition<T extends Widget>(T page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 800),
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
    if (!context.mounted) return;

    try {
      // Show appropriate message
      final logoutMessage = message ??
          (isAccountDeletion
              ? 'Account deleted successfully'
              : 'Signed out successfully');

      _showSnackBar(
        context,
        logoutMessage,
        isAccountDeletion ? AppColors.success : AppColors.primary,
      );

      // Clear navigation stack and go to welcome screen
      NavigationService.navigateToWelcome();

      print(
          '✅ AuthenticationFlow: Navigated to welcome screen after ${isAccountDeletion ? 'account deletion' : 'sign out'}');
    } catch (e) {
      print('❌ AuthenticationFlow: Error in post-logout navigation: $e');

      // Fallback navigation
      if (context.mounted) {
        NavigationService.navigateToWelcome();
      }
    }
  }

  /// Navigate to welcome screen (used for sign out and account deletion)
  Future<void> navigateToWelcome(BuildContext context,
      {String? message}) async {
    if (!context.mounted) return;

    if (message != null) {
      _showSnackBar(context, message, AppColors.primary);
    }

    NavigationService.navigateToWelcome();
  }
}

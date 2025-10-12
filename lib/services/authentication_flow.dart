import 'package:flutter/material.dart';
import 'user_state_service.dart';
import '../presentation/pages/home_view.dart';
import '../presentation/pages/onboarding_view.dart';
import '../core/constants/app_colors.dart';

class AuthenticationFlow {
  final UserStateService _userStateService = UserStateService();

  /// Handle post-authentication navigation based on user state
  Future<void> handlePostAuthNavigation(
    BuildContext context, {
    required String userDisplayName,
    required String userEmail,
    bool showLoadingDialog = true,
  }) async {
    if (!context.mounted) return;

    OverlayEntry? loadingOverlay;

    try {
      // Show loading dialog
      if (showLoadingDialog) {
        loadingOverlay = _showLoadingOverlay(context, 'Checking your profile...');
      }

      // Determine user state
      final userStateResult = await _userStateService.determineUserState();

      // Hide loading dialog
      loadingOverlay?.remove();
      loadingOverlay = null;

      if (!context.mounted) return;

      // Handle different user states
      switch (userStateResult.state) {
        case UserState.returningComplete:
          await _navigateToHome(
            context,
            userDisplayName: userDisplayName,
            userEmail: userEmail,
            message: userStateResult.message ?? 'Welcome back!',
          );
          break;

        case UserState.firstTime:
          await _navigateToOnboarding(
            context,
            userDisplayName: userDisplayName,
            userEmail: userEmail,
            message: userStateResult.message ?? 'Welcome to Foody!',
            isFirstTime: true,
          );
          break;

        case UserState.returningIncomplete:
          await _navigateToOnboarding(
            context,
            userDisplayName: userDisplayName,
            userEmail: userEmail,
            message: userStateResult.message ?? 'Let\'s complete your profile.',
            isFirstTime: false,
          );
          break;

        case UserState.networkError:
          await _handleNetworkError(
            context,
            userDisplayName: userDisplayName,
            userEmail: userEmail,
            error: userStateResult.error,
            message: userStateResult.message,
          );
          break;

        case UserState.authError:
          await _handleAuthError(
            context,
            error: userStateResult.error,
            message: userStateResult.message,
          );
          break;
      }
    } catch (e) {
      // Hide loading dialog if still showing
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
    required String message,
  }) async {
    // Show success message
    _showSnackBar(
      context,
      'Welcome back, ${userDisplayName.isNotEmpty ? userDisplayName : userEmail}!',
      AppColors.success,
    );

    // Navigate to home with smooth transition
    Navigator.pushReplacement(
      context,
      _createSlideTransition(const HomeView()),
    );
  }

  /// Navigate to onboarding with appropriate message
  Future<void> _navigateToOnboarding(
    BuildContext context, {
    required String userDisplayName,
    required String userEmail,
    required String message,
    required bool isFirstTime,
  }) async {
    // Show welcome message
    final displayName = userDisplayName.isNotEmpty ? userDisplayName : userEmail;
    final welcomeMessage = isFirstTime 
        ? 'Welcome to Foody, $displayName!'
        : 'Welcome back, $displayName! Let\'s complete your profile.';

    _showSnackBar(context, welcomeMessage, AppColors.success);

    // Navigate to onboarding with smooth transition
    Navigator.pushReplacement(
      context,
      _createSlideTransition(const OnboardingView()),
    );
  }

  /// Handle network errors with retry option
  Future<void> _handleNetworkError(
    BuildContext context, {
    required String userDisplayName,
    required String userEmail,
    Exception? error,
    String? message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Connection Issue'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message ?? 'Unable to verify your profile due to a connection issue.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'You can:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Try again with a better connection'),
            const Text('• Continue offline (limited features)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue Offline'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (result == true) {
      // Retry authentication flow
      await handlePostAuthNavigation(
        context,
        userDisplayName: userDisplayName,
        userEmail: userEmail,
        showLoadingDialog: true,
      );
    } else {
      // Continue offline - navigate to onboarding as safe fallback
      await _navigateToOnboarding(
        context,
        userDisplayName: userDisplayName,
        userEmail: userEmail,
        message: 'Continuing offline. Some features may be limited.',
        isFirstTime: true,
      );
    }
  }

  /// Handle authentication errors
  Future<void> _handleAuthError(
    BuildContext context, {
    Exception? error,
    String? message,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: AppColors.error),
            SizedBox(width: 8),
            Text('Authentication Error'),
          ],
        ),
        content: Text(
          message ?? 'An authentication error occurred. Please try signing in again.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to sign-in screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Handle unexpected errors
  Future<void> _handleUnexpectedError(BuildContext context, dynamic error) async {
    print('❌ AuthenticationFlow: Unexpected error: $error');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            SizedBox(width: 8),
            Text('Unexpected Error'),
          ],
        ),
        content: const Text(
          'An unexpected error occurred. Please try again or contact support if the problem persists.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Retry the flow
              handlePostAuthNavigation(
                context,
                userDisplayName: '',
                userEmail: '',
                showLoadingDialog: true,
              );
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
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
  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
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
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
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
}

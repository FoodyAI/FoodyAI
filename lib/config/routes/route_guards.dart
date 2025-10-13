import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/user_profile_viewmodel.dart';
import 'app_routes.dart';

class RouteGuards {
  /// Check if user can access a specific route
  static Future<bool> canAccessRoute(
    BuildContext context,
    String routeName,
  ) async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final profileVM = Provider.of<UserProfileViewModel>(context, listen: false);

    // Check authentication requirement
    if (AppRoutes.requiresAuth(routeName) && !authVM.isSignedIn) {
      return false;
    }

    // Check onboarding requirement
    if (AppRoutes.requiresOnboarding(routeName) &&
        !profileVM.hasCompletedOnboarding) {
      return false;
    }

    return true;
  }

  /// Get the appropriate redirect route based on user state
  static String getRedirectRoute(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final profileVM = Provider.of<UserProfileViewModel>(context, listen: false);

    if (!authVM.isSignedIn) {
      return AppRoutes.welcome;
    }

    if (!profileVM.hasCompletedOnboarding) {
      return AppRoutes.onboarding;
    }

    return AppRoutes.home;
  }

  /// Handle route access denial
  static void handleAccessDenied(BuildContext context, String attemptedRoute) {
    final redirectRoute = getRedirectRoute(context);

    // Navigate to appropriate route
    Navigator.pushNamedAndRemoveUntil(
      context,
      redirectRoute,
      (route) => false,
    );
  }
}

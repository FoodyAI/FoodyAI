import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../../config/routes/navigation_service.dart';
import '../../config/routes/app_routes.dart';
import '../../core/constants/app_colors.dart';

/// Splash screen shown during app initialization
/// Handles authentication check and data loading before routing
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Initialize and route after data is loaded
    _initializeAndRoute();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Initialize app data and determine route
  Future<void> _initializeAndRoute() async {
    try {
      // Get ViewModels
      final authVM = context.read<AuthViewModel>();
      final userProfileVM = context.read<UserProfileViewModel>();

      // Wait minimum 1.5 seconds for splash animation + data loading
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 1500)), // Min splash time
        _waitForInitialization(authVM, userProfileVM),
      ]);

      if (!mounted) return;

      // Determine route based on loaded state
      _navigateToAppropriateScreen(authVM, userProfileVM);
    } catch (e) {
      print('❌ SplashScreen: Error during initialization: $e');
      // On error, go to welcome screen
      if (mounted) {
        NavigationService.pushNamedAndRemoveUntil(AppRoutes.welcome);
      }
    }
  }

  /// 🔧 FIX #2 + #5: Wait for Firebase Auth AND profile data
  Future<void> _waitForInitialization(
    AuthViewModel authVM,
    UserProfileViewModel userProfileVM,
  ) async {
    final startTime = DateTime.now();
    const maxWaitTime = Duration(seconds: 10);

    print('⏳ SplashScreen: Waiting for initialization...');

    // CRITICAL: Wait for AuthViewModel to finish checking Firebase session
    // AuthState.initial means Firebase is still restoring the session
    while (authVM.authState == AuthState.initial &&
        DateTime.now().difference(startTime) < maxWaitTime) {
      print('⏳ SplashScreen: Waiting for Firebase to restore session...');
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Now wait for profile loading to complete
    while (userProfileVM.isLoading &&
        DateTime.now().difference(startTime) < maxWaitTime) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Give extra time if we have a signed-in user but profile isn't loaded yet
    if (authVM.isSignedIn && userProfileVM.profile == null) {
      print(
          '⏳ SplashScreen: User signed in but profile loading, waiting extra 2s...');
      await Future.delayed(const Duration(seconds: 2));
    }

    final elapsed = DateTime.now().difference(startTime);
    print(
        '✅ SplashScreen: Initialization complete (${elapsed.inMilliseconds}ms)');
    print('   - Auth state: ${authVM.authState}');
    print('   - Auth signed in: ${authVM.isSignedIn}');
    print('   - Has profile: ${userProfileVM.profile != null}');
    print('   - Onboarding completed: ${userProfileVM.hasCompletedOnboarding}');
  }

  /// Navigate to appropriate screen based on state
  Future<void> _navigateToAppropriateScreen(
    AuthViewModel authVM,
    UserProfileViewModel userProfileVM,
  ) async {
    // Check if user has seen intro onboarding
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('intro_completed') ?? false;

    if (!hasSeenIntro) {
      // First time user -> Show intro onboarding
      print('🔀 SplashScreen: Routing to intro (first time user)');
      NavigationService.pushNamedAndRemoveUntil(AppRoutes.intro);
    } else if (!authVM.isSignedIn) {
      // Seen intro but not signed in -> Intro onboarding
      print('🔀 SplashScreen: Routing to intro (not signed in)');
      NavigationService.pushNamedAndRemoveUntil(AppRoutes.intro);
    } else if (!userProfileVM.hasCompletedOnboarding) {
      // Signed in but no profile -> Onboarding
      print('🔀 SplashScreen: Routing to onboarding (incomplete profile)');
      NavigationService.pushNamedAndRemoveUntil(
        AppRoutes.onboarding,
        arguments: {AppRoutes.isFirstTimeUser: true},
      );
    } else {
      // Signed in with complete profile -> Home
      print('🔀 SplashScreen: Routing to home (returning user)');
      NavigationService.pushNamedAndRemoveUntil(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo/icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                // App name
                const Text(
                  'Foody',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                // Tagline
                Text(
                  'Your Personal Nutrition Assistant',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../../config/routes/navigation_service.dart';
import '../../config/routes/app_routes.dart';
import '../../core/constants/app_colors.dart';

/// Beautiful splash screen with liquid text filling animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize and route
    _initializeAndRoute();
  }

  Future<void> _initializeAndRoute() async {
    try {
      final authVM = context.read<AuthViewModel>();
      final userProfileVM = context.read<UserProfileViewModel>();

      await Future.wait([
        Future.delayed(const Duration(milliseconds: 3500)),
        _waitForInitialization(authVM, userProfileVM),
      ]);

      if (!mounted) return;
      _navigateToAppropriateScreen(authVM, userProfileVM);
    } catch (e) {
      if (mounted) {
        NavigationService.pushNamedAndRemoveUntil(AppRoutes.intro);
      }
    }
  }

  Future<void> _waitForInitialization(
    AuthViewModel authVM,
    UserProfileViewModel userProfileVM,
  ) async {
    final startTime = DateTime.now();
    const maxWaitTime = Duration(seconds: 10);

    while (authVM.authState == AuthState.initial &&
        DateTime.now().difference(startTime) < maxWaitTime) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    while (userProfileVM.isLoading &&
        DateTime.now().difference(startTime) < maxWaitTime) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (authVM.isSignedIn && userProfileVM.profile == null) {
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> _navigateToAppropriateScreen(
    AuthViewModel authVM,
    UserProfileViewModel userProfileVM,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('intro_completed') ?? false;

    if (!hasSeenIntro) {
      NavigationService.pushNamedAndRemoveUntil(AppRoutes.intro);
    } else if (!authVM.isSignedIn) {
      NavigationService.pushNamedAndRemoveUntil(AppRoutes.intro);
    } else if (!userProfileVM.hasCompletedOnboarding) {
      NavigationService.pushNamedAndRemoveUntil(
        AppRoutes.onboarding,
        arguments: {AppRoutes.isFirstTimeUser: true},
      );
    } else {
      NavigationService.pushNamedAndRemoveUntil(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current theme brightness
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    AppColors.darkBackground,
                    const Color(0xFF1A1A1A),
                    AppColors.darkSurface,
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF8F9FA),
                    AppColors.grey100,
                  ],
          ),
        ),
        child: Center(
          child: _buildLiquidText(isDarkMode),
        ),
      ),
    );
  }

  Widget _buildLiquidText(bool isDarkMode) {
    return SizedBox(
      width: 300,
      height: 100,
      child: AnimatedTextKit(
        animatedTexts: [
          ColorizeAnimatedText(
            'Foody',
            textAlign: TextAlign.center,
            textStyle: const TextStyle(
              fontSize: 68,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
            colors: [
              isDarkMode
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.primary.withOpacity(0.2),
              AppColors.primaryLight,
              AppColors.primary,
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.primaryLight,
              AppColors.primary,
            ],
            speed: const Duration(milliseconds: 800),
          ),
        ],
        isRepeatingAnimation: false,
        totalRepeatCount: 1,
        pause: const Duration(milliseconds: 1000),
      ),
    );
  }
}

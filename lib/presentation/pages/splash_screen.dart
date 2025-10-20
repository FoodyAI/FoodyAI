import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../../config/routes/navigation_service.dart';
import '../../config/routes/app_routes.dart';
import 'dart:ui';

/// Modern splash screen with immersive design
/// Matches the onboarding design language
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
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
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

      // Wait minimum 1.8 seconds for splash animation + data loading
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 1800)), // Min splash time
        _waitForInitialization(authVM, userProfileVM),
      ]);

      if (!mounted) return;

      // Determine route based on loaded state
      _navigateToAppropriateScreen(authVM, userProfileVM);
    } catch (e) {
      print('❌ SplashScreen: Error during initialization: $e');
      // On error, go to intro screen
      if (mounted) {
        NavigationService.pushNamedAndRemoveUntil(AppRoutes.intro);
      }
    }
  }

  /// Wait for Firebase Auth AND profile data
  Future<void> _waitForInitialization(
    AuthViewModel authVM,
    UserProfileViewModel userProfileVM,
  ) async {
    final startTime = DateTime.now();
    const maxWaitTime = Duration(seconds: 10);

    // Wait for AuthViewModel to finish checking Firebase session
    while (authVM.authState == AuthState.initial &&
        DateTime.now().difference(startTime) < maxWaitTime) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Wait for profile loading to complete
    while (userProfileVM.isLoading &&
        DateTime.now().difference(startTime) < maxWaitTime) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Give extra time if we have a signed-in user but profile isn't loaded yet
    if (authVM.isSignedIn && userProfileVM.profile == null) {
      await Future.delayed(const Duration(seconds: 2));
    }
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
      NavigationService.pushNamedAndRemoveUntil(AppRoutes.intro);
    } else if (!authVM.isSignedIn) {
      // Seen intro but not signed in -> Intro onboarding
      NavigationService.pushNamedAndRemoveUntil(AppRoutes.intro);
    } else if (!userProfileVM.hasCompletedOnboarding) {
      // Signed in but no profile -> Onboarding
      NavigationService.pushNamedAndRemoveUntil(
        AppRoutes.onboarding,
        arguments: {AppRoutes.isFirstTimeUser: true},
      );
    } else {
      // Signed in with complete profile -> Home
      NavigationService.pushNamedAndRemoveUntil(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A1A),
              Colors.black,
              Colors.black,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle animated background pattern
            _buildBackgroundPattern(),

            // Main content - positioned better
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.25),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: AnimatedBuilder(
                        animation: _slideAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: child,
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // App icon with modern design
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF6B6B),
                                    Color(0xFFFF8E8E),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF6B6B).withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.restaurant_menu,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // App name with modern typography
                            const Text(
                              'Foody',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Tagline
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Your Personal Nutrition Assistant',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 60),

                            // Loading indicator
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFFFF6B6B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build subtle animated background pattern
  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _BackgroundPatternPainter(
              animationValue: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for background pattern
class _BackgroundPatternPainter extends CustomPainter {
  final double animationValue;

  _BackgroundPatternPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw subtle circles
    for (int i = 0; i < 5; i++) {
      final radius = (size.width / 2) * (0.3 + i * 0.2) * animationValue;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPatternPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:math' as math;
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../../config/routes/navigation_service.dart';
import '../../config/routes/app_routes.dart';

/// Beautiful splash screen with gradient background and floating animations
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutBack,
      ),
    );

    // Pulse animation for icon glow
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Floating animation for particles
    _floatController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _fadeController.forward();

    // Initialize and route
    _initializeAndRoute();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF000000),
              Color(0xFF1A1A1A),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Floating food particles
            _buildFloatingParticles(),

            // Main content
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Animated icon with pulse glow
                      _buildAnimatedIcon(),

                      const SizedBox(height: 32),

                      // App name
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'Foody',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Your AI Nutrition Assistant',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Animated text (black and white)
                      SizedBox(
                        height: 90,
                        child: Center(
                          child: AnimatedTextKit(
                            animatedTexts: [
                              ColorizeAnimatedText(
                                'Nourish your body',
                                textAlign: TextAlign.center,
                                textStyle: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                                colors: [
                                  Colors.white,
                                  Color(0xFFCCCCCC),
                                  Color(0xFF999999),
                                  Color(0xFFCCCCCC),
                                  Colors.white,
                                ],
                                speed: const Duration(milliseconds: 400),
                              ),
                              ColorizeAnimatedText(
                                'Track your journey',
                                textAlign: TextAlign.center,
                                textStyle: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                                colors: [
                                  Colors.white,
                                  Color(0xFFCCCCCC),
                                  Color(0xFF999999),
                                  Color(0xFFCCCCCC),
                                  Colors.white,
                                ],
                                speed: const Duration(milliseconds: 400),
                              ),
                              ColorizeAnimatedText(
                                'Achieve your goals',
                                textAlign: TextAlign.center,
                                textStyle: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                                colors: [
                                  Colors.white,
                                  Color(0xFFCCCCCC),
                                  Color(0xFF999999),
                                  Color(0xFFCCCCCC),
                                  Colors.white,
                                ],
                                speed: const Duration(milliseconds: 400),
                              ),
                            ],
                            totalRepeatCount: 100,
                            pause: const Duration(milliseconds: 1000),
                            displayFullTextOnTap: false,
                            stopPauseOnTap: false,
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Loading indicator
                      _buildLoadingIndicator(),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),

            // Decorative circles at corners
            _buildDecorativeCircles(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white
                        .withOpacity(0.3 * _pulseAnimation.value),
                    blurRadius: 30 * _pulseAnimation.value,
                    spreadRadius: 10 * _pulseAnimation.value,
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: 60,
                  color: Colors.black,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: const AlwaysStoppedAnimation<Color>(
              Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            'Preparing your experience...',
            textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Stack(
          children: List.generate(15, (index) {
            final random = math.Random(index);
            final x = random.nextDouble();
            final y = random.nextDouble();
            final size = random.nextDouble() * 40 + 20;
            final speed = random.nextDouble() * 0.5 + 0.3;

            final offsetX =
                math.sin(_floatController.value * 2 * math.pi * speed + index) *
                    30;
            final offsetY =
                math.cos(_floatController.value * 2 * math.pi * speed + index) *
                    30;

            return Positioned(
              left: MediaQuery.of(context).size.width * x + offsetX,
              top: MediaQuery.of(context).size.height * y + offsetY,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  _getFoodIcon(index),
                  size: size,
                  color: Colors.white,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  IconData _getFoodIcon(int index) {
    final icons = [
      Icons.restaurant,
      Icons.local_pizza,
      Icons.cake,
      Icons.lunch_dining,
      Icons.fastfood,
      Icons.local_cafe,
      Icons.restaurant_menu,
      Icons.dinner_dining,
      Icons.breakfast_dining,
      Icons.icecream,
    ];
    return icons[index % icons.length];
  }

  Widget _buildDecorativeCircles() {
    return Stack(
      children: [
        // Top left
        Positioned(
          top: -50,
          left: -50,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Bottom right
        Positioned(
          bottom: -80,
          right: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      ],
    );
  }
}

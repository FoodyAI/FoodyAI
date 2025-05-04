import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/welcome_viewmodel.dart';
import 'dart:math' as math;
import 'dart:math';
import '../../../core/constants/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WelcomeViewModel(),
      child: const _WelcomeScreenContent(),
    );
  }
}

class _WelcomeScreenContent extends StatelessWidget {
  const _WelcomeScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WelcomeViewModel>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.black : AppColors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Animated Background
          AnimatedBackground(isDarkMode: isDarkMode),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // App Logo with Animation
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? AppColors.withOpacity(AppColors.black, 0.1)
                                : AppColors.withOpacity(AppColors.white, 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.restaurant_menu,
                            size: 80,
                            color: isDarkMode
                                ? AppColors.green
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Welcome Text with Animation
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Foody',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: isDarkMode
                                        ? AppColors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 32,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'AI-Powered Food Analysis\nTrack Your Nutrition & Calories',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: isDarkMode
                                        ? AppColors.withOpacity(
                                            AppColors.white, 0.9)
                                        : AppColors.withOpacity(
                                            AppColors.textPrimary, 0.9),
                                    fontSize: 18,
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Sign In Button with Animation
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Center(
                          child: ElevatedButton(
                            onPressed: viewModel.isGoogleLoading
                                ? null
                                : viewModel.signInWithGoogle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? AppColors.green
                                  : AppColors.white,
                              foregroundColor: isDarkMode
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (viewModel.isGoogleLoading)
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          isDarkMode
                                              ? AppColors.white
                                              : AppColors.textPrimary),
                                    ),
                                  )
                                else ...[
                                  Image.asset(
                                    'assets/google_logo.png',
                                    height: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Skip Button with Animation
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Center(
                          child: TextButton(
                            onPressed: viewModel.isGuestLoading
                                ? null
                                : () {
                                    viewModel.continueAsGuest(context);
                                  },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              'Continue as Guest',
                              style: TextStyle(
                                color: isDarkMode
                                    ? AppColors.withOpacity(
                                        AppColors.white, 0.9)
                                    : AppColors.withOpacity(
                                        AppColors.textPrimary, 0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedBackground extends StatefulWidget {
  final bool isDarkMode;
  const AnimatedBackground({super.key, required this.isDarkMode});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<FloatingIcon> _icons = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Initialize floating icons
    for (int i = 0; i < 15; i++) {
      _icons.add(FloatingIcon(
        icon: _getRandomFoodIcon(),
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 30 + 20,
        speed: _random.nextDouble() * 0.5 + 0.2,
        rotation: _random.nextDouble() * 360,
      ));
    }
  }

  IconData _getRandomFoodIcon() {
    final icons = [
      Icons.restaurant,
      Icons.local_pizza,
      Icons.icecream,
      Icons.local_cafe,
      Icons.local_dining,
      Icons.fastfood,
      Icons.cake,
      Icons.wine_bar,
      Icons.local_bar,
      Icons.emoji_food_beverage,
    ];
    return icons[_random.nextInt(icons.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.black : AppColors.white,
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: _icons.map((icon) {
              final x = icon.x +
                  math.sin(_controller.value * 2 * math.pi * icon.speed) * 0.1;
              final y = icon.y +
                  math.cos(_controller.value * 2 * math.pi * icon.speed) * 0.1;
              final rotation =
                  icon.rotation + _controller.value * 360 * icon.speed;

              return Positioned(
                left: x * MediaQuery.of(context).size.width,
                top: y * MediaQuery.of(context).size.height,
                child: Transform.rotate(
                  angle: rotation * math.pi / 180,
                  child: Icon(
                    icon.icon,
                    size: icon.size,
                    color: widget.isDarkMode
                        ? AppColors.withOpacity(AppColors.green, 0.3)
                        : AppColors.withOpacity(AppColors.green, 0.3),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class FloatingIcon {
  final IconData icon;
  final double x;
  final double y;
  final double size;
  final double speed;
  final double rotation;

  FloatingIcon({
    required this.icon,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.rotation,
  });
}

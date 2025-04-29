import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/welcome_viewmodel.dart';
import 'dart:math' as math;
import 'dart:math';

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

    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          const AnimatedBackground(),

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
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            size: 80,
                            color: Colors.white,
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
                              'Welcome to Foody',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 32,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Discover, Cook, and Share\nYour Favorite Recipes',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
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
                            onPressed: viewModel.isLoading
                                ? null
                                : viewModel.signInWithGoogle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
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
                                if (viewModel.isLoading)
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.black87),
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
                            onPressed: viewModel.isLoading
                                ? null
                                : () => viewModel.continueAsGuest(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              'Continue as Guest',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
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
  const AnimatedBackground({super.key});

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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.indigo.shade900,
            Colors.purple.shade900,
          ],
        ),
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
                    color: Colors.white.withOpacity(0.3),
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

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../config/onboarding/onboarding_config.dart';

/// A widget that displays content inside an iPhone-style phone mockup
/// with a notch, bezels, and glowing shadow effect
class PhoneMockupWidget extends StatelessWidget {
  final Widget child;
  final PhoneMockupConfig config;

  const PhoneMockupWidget({
    super.key,
    required this.child,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.show) {
      return child;
    }

    final screenSize = MediaQuery.of(context).size;
    final mockupWidth = screenSize.width * 0.95;
    final mockupHeight = screenSize.height * 0.88;

    return Center(
      child: Container(
        width: mockupWidth,
        height: mockupHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(config.cornerRadius),
          boxShadow: [
            config.shadow.toBoxShadow(),
            // Additional subtle shadow for depth
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Phone border/bezel
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(config.cornerRadius),
                border: Border.all(
                  color: config.borderColor,
                  width: config.borderWidth,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
            ),

            // Phone screen content area
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(config.borderWidth),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    config.cornerRadius - config.borderWidth,
                  ),
                  child: Stack(
                    children: [
                      // Content
                      child,

                      // Notch overlay at the top
                      _buildNotch(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the iPhone-style notch at the top of the screen
  Widget _buildNotch() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: config.notchHeight + 10,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.0),
            ],
          ),
        ),
        child: Center(
          child: Container(
            width: config.notchWidth,
            height: config.notchHeight,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(config.notchHeight / 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Speaker grille
                Container(
                  width: config.notchWidth * 0.35,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(width: 8),
                // Camera
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    shape: BoxShape.circle,
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

/// A glassmorphism card widget for displaying content inside the phone mockup
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? backgroundColor;
  final double blur;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.backgroundColor,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Content widget to be displayed inside the phone mockup
/// Displays full-screen image with text overlay at bottom (like reference)
class PhoneMockupContent extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final bool showSkipButton;
  final VoidCallback? onSkip;

  const PhoneMockupContent({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.showSkipButton = false,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full-screen background image
        Positioned.fill(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(Icons.error, color: Colors.white),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[900],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),

        // Skip button at top right (inside phone)
        if (showSkipButton)
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: onSkip,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        // Bottom text overlay with gradient
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.9),
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

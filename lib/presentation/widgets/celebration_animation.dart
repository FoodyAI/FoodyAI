import 'dart:math';
import 'package:flutter/material.dart';

class CelebrationAnimation extends StatefulWidget {
  const CelebrationAnimation({super.key});

  @override
  State<CelebrationAnimation> createState() => _CelebrationAnimationState();
}

class _CelebrationAnimationState extends State<CelebrationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(() {
        setState(() {
          _updateParticles();
        });
      });

    // Create confetti particles
    _createParticles();
    _controller.forward();
  }

  void _createParticles() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];

    // Create 50 particles
    for (int i = 0; i < 50; i++) {
      _particles.add(
        Particle(
          color: colors[_random.nextInt(colors.length)],
          startX: 0.5, // Start from center
          startY: 0.5,
          endX: _random.nextDouble(), // Spread randomly
          endY: _random.nextDouble(),
          size: _random.nextDouble() * 8 + 4,
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 4,
        ),
      );
    }
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.update(_controller.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ParticlePainter(_particles, _controller.value),
        child: Container(),
      ),
    );
  }
}

class Particle {
  final Color color;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double size;
  final double rotation;
  final double rotationSpeed;

  double currentX = 0;
  double currentY = 0;
  double currentRotation = 0;
  double opacity = 1.0;

  Particle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  }) {
    currentX = startX;
    currentY = startY;
    currentRotation = rotation;
  }

  void update(double progress) {
    // Ease out cubic curve
    final easedProgress = 1 - pow(1 - progress, 3);

    // Move particle from center to edge
    currentX = startX + (endX - startX) * easedProgress;
    currentY = startY + (endY - startY) * easedProgress;

    // Rotate particle
    currentRotation = rotation + rotationSpeed * progress * 2 * pi;

    // Fade out towards the end
    opacity = 1.0 - progress;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  _ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      final x = particle.currentX * size.width;
      final y = particle.currentY * size.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.currentRotation);

      // Draw confetti as rectangles
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size,
        height: particle.size * 1.5,
      );
      canvas.drawRect(rect, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

import 'package:flutter/material.dart';
import '../../../config/onboarding/onboarding_config.dart';

/// Animated page indicator with expanding dots
/// Shows the current page in the onboarding flow
class AnimatedPageIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;
  final PageIndicatorConfig config;
  final ValueChanged<int>? onPageTap;

  const AnimatedPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    required this.config,
    this.onPageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        pageCount,
        (index) => _buildDot(index),
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = index == currentPage;

    return GestureDetector(
      onTap: onPageTap != null ? () => onPageTap!(index) : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: config.animationDurationMs),
        curve: Curves.easeInOut,
        width: isActive ? config.activeWidth : config.inactiveWidth,
        height: config.height,
        margin: EdgeInsets.symmetric(horizontal: config.spacing / 2),
        decoration: BoxDecoration(
          color: isActive ? config.activeColor : config.inactiveColor,
          borderRadius: BorderRadius.circular(config.height / 2),
        ),
      ),
    );
  }
}

/// Alternative smooth animated page indicator with more fluid animations
class SmoothPageIndicator extends StatefulWidget {
  final int pageCount;
  final double currentPage; // Can be fractional for smooth transitions
  final PageIndicatorConfig config;

  const SmoothPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    required this.config,
  });

  @override
  State<SmoothPageIndicator> createState() => _SmoothPageIndicatorState();
}

class _SmoothPageIndicatorState extends State<SmoothPageIndicator> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.config.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          widget.pageCount,
          (index) => _buildDot(index),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    // Calculate how close the current page is to this dot
    final distance = (widget.currentPage - index).abs();
    final scale = 1.0 - distance.clamp(0.0, 1.0);

    // Interpolate width based on proximity to current page
    final width = widget.config.inactiveWidth +
        (widget.config.activeWidth - widget.config.inactiveWidth) * scale;

    // Interpolate color based on proximity
    final color = Color.lerp(
      widget.config.inactiveColor,
      widget.config.activeColor,
      scale,
    )!;

    return AnimatedContainer(
      duration: Duration(milliseconds: widget.config.animationDurationMs),
      curve: Curves.easeInOut,
      width: width,
      height: widget.config.height,
      margin: EdgeInsets.symmetric(horizontal: widget.config.spacing / 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(widget.config.height / 2),
      ),
    );
  }
}

/// Worm-style page indicator that slides smoothly between pages
class WormPageIndicator extends StatelessWidget {
  final int pageCount;
  final double currentPage; // Can be fractional for smooth transitions
  final PageIndicatorConfig config;

  const WormPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: config.height,
      child: Stack(
        children: [
          // Inactive dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              pageCount,
              (index) => Container(
                width: config.inactiveWidth,
                height: config.height,
                margin: EdgeInsets.symmetric(horizontal: config.spacing / 2),
                decoration: BoxDecoration(
                  color: config.inactiveColor,
                  borderRadius: BorderRadius.circular(config.height / 2),
                ),
              ),
            ),
          ),
          // Active worm
          _buildWorm(),
        ],
      ),
    );
  }

  Widget _buildWorm() {
    final dotSpacing = config.inactiveWidth + config.spacing;
    final currentIndex = currentPage.floor();
    final progress = currentPage - currentIndex;

    // Calculate position and width for the worm
    final leftPosition = currentIndex * dotSpacing;
    final wormWidth = config.activeWidth + (dotSpacing * progress);

    return AnimatedPositioned(
      duration: Duration(milliseconds: config.animationDurationMs),
      curve: Curves.easeInOut,
      left: leftPosition,
      child: AnimatedContainer(
        duration: Duration(milliseconds: config.animationDurationMs),
        curve: Curves.easeInOut,
        width: wormWidth,
        height: config.height,
        margin: EdgeInsets.symmetric(horizontal: config.spacing / 2),
        decoration: BoxDecoration(
          color: config.activeColor,
          borderRadius: BorderRadius.circular(config.height / 2),
        ),
      ),
    );
  }
}

/// Jumping dot page indicator with a bounce effect
class JumpingDotIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;
  final PageIndicatorConfig config;

  const JumpingDotIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: config.height * 2, // Extra space for jumping
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          pageCount,
          (index) => _buildDot(index),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = index == currentPage;

    return AnimatedContainer(
      duration: Duration(milliseconds: config.animationDurationMs),
      curve: Curves.easeInOut,
      width: config.inactiveWidth,
      height: config.height,
      margin: EdgeInsets.symmetric(horizontal: config.spacing / 2),
      transform: Matrix4.translationValues(
        0,
        isActive ? -config.height : 0,
        0,
      ),
      decoration: BoxDecoration(
        color: isActive ? config.activeColor : config.inactiveColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Factory method to create the appropriate indicator based on config type
class PageIndicatorFactory {
  static Widget create({
    required int pageCount,
    required int currentPage,
    required PageIndicatorConfig config,
    double? currentPageFractional,
  }) {
    switch (config.type) {
      case 'expanding_dots':
        return AnimatedPageIndicator(
          pageCount: pageCount,
          currentPage: currentPage,
          config: config,
        );
      case 'smooth':
        return SmoothPageIndicator(
          pageCount: pageCount,
          currentPage: currentPageFractional ?? currentPage.toDouble(),
          config: config,
        );
      case 'worm':
        return WormPageIndicator(
          pageCount: pageCount,
          currentPage: currentPageFractional ?? currentPage.toDouble(),
          config: config,
        );
      case 'jumping':
        return JumpingDotIndicator(
          pageCount: pageCount,
          currentPage: currentPage,
          config: config,
        );
      default:
        return AnimatedPageIndicator(
          pageCount: pageCount,
          currentPage: currentPage,
          config: config,
        );
    }
  }
}

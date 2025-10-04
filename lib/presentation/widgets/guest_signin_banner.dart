import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import 'google_signin_button.dart';

class GuestSignInBanner extends StatefulWidget {
  final VoidCallback? onDismiss;
  final bool showAnimation;

  const GuestSignInBanner({
    Key? key,
    this.onDismiss,
    this.showAnimation = true,
  }) : super(key: key);

  @override
  State<GuestSignInBanner> createState() => _GuestSignInBannerState();
}

class _GuestSignInBannerState extends State<GuestSignInBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _animationInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationInitialized = true;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    if (widget.showAnimation) {
      await _animationController.forward();
    }
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    Widget banner = Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.withOpacity(colorScheme.primary, 0.1),
            AppColors.withOpacity(colorScheme.secondary, 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.withOpacity(colorScheme.primary, 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.withOpacity(colorScheme.primary, 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  FontAwesomeIcons.cloudArrowUp,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sign in to sync & backup your data',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                ),
              ),
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.xmark,
                  size: 16,
                ),
                onPressed: _handleDismiss,
                style: IconButton.styleFrom(
                  foregroundColor: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const GoogleSignInButton(
            isFullWidth: true,
            isCompact: true,
          ),
        ],
      ),
    );

    if (widget.showAnimation && _animationInitialized) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: Opacity(
              opacity: _animation.value,
              child: banner,
            ),
          );
        },
      );
    }

    return banner;
  }
}

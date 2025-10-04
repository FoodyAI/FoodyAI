import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ConnectionBanner extends StatefulWidget {
  final bool isConnected;

  const ConnectionBanner({
    super.key,
    required this.isConnected,
  });

  @override
  State<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends State<ConnectionBanner> {
  bool _showBanner = false;
  bool _wasDisconnected = false;
  bool _showBlackBanner = false;
  bool _isAnimatingOut = false;

  @override
  void didUpdateWidget(ConnectionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isConnected && widget.isConnected) {
      // Connection restored - show green banner briefly
      setState(() {
        _showBanner = true;
        _wasDisconnected = true;
        _showBlackBanner = false;
      });

      // Hide banner after 2 seconds with slide down animation
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isAnimatingOut = true;
          });
          // Complete hide after animation
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _showBanner = false;
                _isAnimatingOut = false;
              });
            }
          });
        }
      });
    } else if (!widget.isConnected) {
      // Connection lost - show red banner first
      setState(() {
        _showBanner = true;
        _wasDisconnected = false;
        _showBlackBanner = false;
      });

      // Change to black after 3 seconds with smooth transition
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !widget.isConnected) {
          setState(() {
            _showBlackBanner = true;
          });
        }
      });
    } else {
      // Connected and no previous disconnection - slide down and hide
      if (_showBanner) {
        setState(() {
          _isAnimatingOut = true;
        });
        // Complete hide after animation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _showBanner = false;
              _showBlackBanner = false;
              _isAnimatingOut = false;
            });
          }
        });
      } else {
        setState(() {
          _showBanner = false;
          _showBlackBanner = false;
          _isAnimatingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBanner) return const SizedBox.shrink();

    return AnimatedSlide(
      offset: _isAnimatingOut ? const Offset(0, 1) : Offset.zero,
      duration: const Duration(milliseconds: 500),
      curve: _isAnimatingOut ? Curves.easeInCubic : Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _isAnimatingOut ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 400),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _wasDisconnected 
                ? Colors.green 
                : (_showBlackBanner ? Colors.black : AppColors.error),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _wasDisconnected ? "You're back online" : "You're offline",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

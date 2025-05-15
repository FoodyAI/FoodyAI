import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../viewmodels/image_analysis_viewmodel.dart';
import '../../../core/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _rating = 0;
  bool _hasRated = false;
  late List<AnimationController> _starControllers;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();

    // Initialize star controllers
    _starControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    for (var controller in _starControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onStarTap(int index) {
    // If tapping the same star that's already selected, deselect it
    if (_rating == index + 1) {
      setState(() => _rating = 0);
      // Animate all stars back to empty state
      for (var controller in _starControllers) {
        controller.reverse();
      }
      return;
    }

    setState(() => _rating = index + 1);

    // Animate stars based on the new rating
    for (int i = 0; i < _starControllers.length; i++) {
      if (i <= index) {
        _starControllers[i].forward();
      } else {
        _starControllers[i].reverse();
      }
    }
  }

  Future<void> _submitRating() async {
    if (_rating > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('app_rating', _rating);
      await prefs.setBool('has_submitted_rating', true);
      setState(() => _hasRated = true);
    }
  }

  Future<void> _dontAskAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_submitted_rating', true);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: AppColors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.withOpacity(AppColors.black, 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.withOpacity(AppColors.primary, 0.1),
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(
                  FontAwesomeIcons.heart,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _hasRated ? 'Thank You!' : 'How was your experience?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _hasRated
                    ? 'We appreciate your feedback!'
                    : 'Your feedback helps us improve',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!_hasRated) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => _onStarTap(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: AnimatedBuilder(
                          animation: _starControllers[index],
                          builder: (context, child) {
                            return Transform.scale(
                              scale:
                                  1.0 + (_starControllers[index].value * 0.1),
                              child: FaIcon(
                                index < _rating
                                    ? FontAwesomeIcons.solidStar
                                    : FontAwesomeIcons.star,
                                size: 36,
                                color: index < _rating
                                    ? AppColors.warning
                                    : AppColors.grey400,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                // Primary action button (Submit)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _rating > 0 ? _submitRating : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Submit Rating',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Secondary actions in a row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        final viewModel = Provider.of<ImageAnalysisViewModel>(
                            context,
                            listen: false);
                        viewModel.handleMaybeLater();
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Maybe Later',
                        style: TextStyle(
                          color: AppColors.grey600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    TextButton(
                      onPressed: _dontAskAgain,
                      child: const Text(
                        'Don\'t Ask Again',
                        style: TextStyle(
                          color: AppColors.grey500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

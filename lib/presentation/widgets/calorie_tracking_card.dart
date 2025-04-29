import 'package:flutter/material.dart';
import '../../data/models/food_analysis.dart';

class CalorieTrackingCard extends StatefulWidget {
  final double totalCaloriesConsumed;
  final double recommendedCalories;
  final List<FoodAnalysis> savedAnalyses;

  const CalorieTrackingCard({
    super.key,
    required this.totalCaloriesConsumed,
    required this.recommendedCalories,
    required this.savedAnalyses,
  });

  @override
  State<CalorieTrackingCard> createState() => _CalorieTrackingCardState();
}

class _CalorieTrackingCardState extends State<CalorieTrackingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: (widget.totalCaloriesConsumed / widget.recommendedCalories)
          .clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(CalorieTrackingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalCaloriesConsumed != widget.totalCaloriesConsumed) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.totalCaloriesConsumed / widget.recommendedCalories,
        end: (widget.totalCaloriesConsumed / widget.recommendedCalories)
            .clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remainingCalories =
        widget.recommendedCalories - widget.totalCaloriesConsumed;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Calories',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${remainingCalories.toStringAsFixed(0)} left',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              // Background progress bar
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Animated progress indicator
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Container(
                    height: 12,
                    width: MediaQuery.of(context).size.width *
                        0.8 *
                        _progressAnimation.value,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCalorieInfo(
                'Consumed',
                widget.totalCaloriesConsumed.toStringAsFixed(0),
                Icons.local_fire_department,
              ),
              _buildCalorieInfo(
                'Goal',
                widget.recommendedCalories.toStringAsFixed(0),
                Icons.flag,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieInfo(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

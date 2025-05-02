import 'package:flutter/material.dart';
import '../../data/models/food_analysis.dart';
import '../../../core/constants/app_colors.dart';

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

    // Determine status color based on calorie consumption
    Color statusColor;
    if (remainingCalories < 0) {
      statusColor = AppColors.error;
    } else if (remainingCalories < widget.recommendedCalories * 0.2) {
      statusColor = AppColors.orange;
    } else if (remainingCalories < widget.recommendedCalories * 0.5) {
      statusColor = AppColors.blue;
    } else {
      statusColor = AppColors.green;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.withOpacity(statusColor, 0.1),
            AppColors.withOpacity(statusColor, 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.withOpacity(statusColor, 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Calories',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.withOpacity(statusColor, 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${remainingCalories.toStringAsFixed(0)} left',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
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
                  color: Theme.of(context).colorScheme.surface,
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
                      color: statusColor,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.withOpacity(statusColor, 0.3),
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
                statusColor,
              ),
              _buildCalorieInfo(
                'Goal',
                widget.recommendedCalories.toStringAsFixed(0),
                Icons.flag,
                statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieInfo(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.withOpacity(color, 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

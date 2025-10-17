import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/food_analysis.dart';
import '../../../core/constants/app_colors.dart';
import 'glassmorphism_calendar.dart';

class CalorieTrackingCard extends StatefulWidget {
  final double totalCaloriesConsumed;
  final double recommendedCalories;
  final List<FoodAnalysis> savedAnalyses;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const CalorieTrackingCard({
    super.key,
    required this.totalCaloriesConsumed,
    required this.recommendedCalories,
    required this.savedAnalyses,
    required this.selectedDate,
    required this.onDateSelected,
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
      statusColor = Colors.red; // Exceeded goal - Red for warning
    } else if (remainingCalories < widget.recommendedCalories * 0.2) {
      statusColor = Colors.orange; // Very close to limit - Orange for caution
    } else if (remainingCalories < widget.recommendedCalories * 0.5) {
      statusColor = Colors.amber; // Moderate consumption - Yellow for attention
    } else {
      statusColor = Colors.green; // Healthy consumption - Green for good
    }

    final isToday = widget.selectedDate.year == DateTime.now().year &&
        widget.selectedDate.month == DateTime.now().month &&
        widget.selectedDate.day == DateTime.now().day;

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
              Flexible(
                flex: 2,
                child: GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await GlassmorphismCalendar.showCalendarDialog(
                      context: context,
                      selectedDate: widget.selectedDate,
                    );
                    if (picked != null) {
                      widget.onDateSelected(picked);
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    isToday
                                        ? 'Today\'s Calories'
                                        : '${DateFormat('d MMM').format(widget.selectedDate)} Calories',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.chevron_right,
                                color: Theme.of(context).colorScheme.primary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: isToday
                            ? const SizedBox.shrink()
                            : Tooltip(
                                message: 'Go to Today',
                                child: IconButton(
                                  onPressed: () =>
                                      widget.onDateSelected(DateTime.now()),
                                  icon: Icon(
                                    Icons.replay_rounded,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    size: 20,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.withOpacity(statusColor, 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (remainingCalories <= 0)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Text(
                            '🎉',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            remainingCalories <= 0
                                ? 'Goal Reached!'
                                : '${remainingCalories.toStringAsFixed(0)} left',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
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
              LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Container(
                        height: 12,
                        width: constraints.maxWidth * _progressAnimation.value,
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
                FontAwesomeIcons.fire,
                statusColor,
              ),
              _buildCalorieInfo(
                'Goal',
                widget.recommendedCalories.toStringAsFixed(0),
                FontAwesomeIcons.flag,
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
              FaIcon(
                icon,
                color: color,
                size: 18,
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

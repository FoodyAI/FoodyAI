import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../../data/models/food_analysis.dart';
import '../../../core/constants/app_colors.dart';
import 'glassmorphism_calendar.dart';
import 'celebration_animation.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  bool _showCelebration = false;

  // Animation controllers for card entrance and interactions
  late AnimationController _scaleController;
  late AnimationController _fireController;
  late AnimationController _emojiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fireAnimation;
  late Animation<double> _emojiAnimation;

  @override
  void initState() {
    super.initState();

    // Progress animation
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

    // Card entrance animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    // Fire icon pulsing animation
    _fireController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _fireAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _fireController,
      curve: Curves.easeInOut,
    ));

    // Emoji rotation animation (will change based on status)
    _emojiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _emojiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _emojiController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _scaleController.forward();
    _controller.forward();
    _fireController.repeat(reverse: true);
    _emojiController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(CalorieTrackingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalCaloriesConsumed != widget.totalCaloriesConsumed) {
      final wasGoalNotReached = oldWidget.recommendedCalories - oldWidget.totalCaloriesConsumed > 0;
      final isGoalReached = widget.recommendedCalories - widget.totalCaloriesConsumed <= 0;

      // Show celebration every time user transitions from not reached to reached
      if (wasGoalNotReached && isGoalReached) {
        setState(() {
          _showCelebration = true;
        });

        // Hide celebration after 2 seconds
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() {
              _showCelebration = false;
            });
          }
        });
      }

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
    _scaleController.dispose();
    _fireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingCalories =
        widget.recommendedCalories - widget.totalCaloriesConsumed;

    // Determine status color based on calorie consumption with modern colors
    Color statusColor;
    Color gradientStart;
    Color gradientEnd;

    if (remainingCalories < 0) {
      statusColor = const Color(0xFFEF4444); // Modern red
      gradientStart = const Color(0xFFEF4444);
      gradientEnd = const Color(0xFFF87171);
    } else if (remainingCalories < widget.recommendedCalories * 0.2) {
      statusColor = const Color(0xFFF59E0B); // Modern orange
      gradientStart = const Color(0xFFF59E0B);
      gradientEnd = const Color(0xFFFBBF24);
    } else if (remainingCalories < widget.recommendedCalories * 0.5) {
      statusColor = const Color(0xFFFBBF24); // Modern amber
      gradientStart = const Color(0xFFFBBF24);
      gradientEnd = const Color(0xFFFDE047);
    } else {
      statusColor = const Color(0xFF10B981); // Modern green
      gradientStart = const Color(0xFF10B981);
      gradientEnd = const Color(0xFF34D399);
    }

    final isToday = widget.selectedDate.year == DateTime.now().year &&
        widget.selectedDate.month == DateTime.now().month &&
        widget.selectedDate.day == DateTime.now().day;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                // Exact same style as health analysis cards
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.grey[850]!.withOpacity(0.95),
                          Colors.grey[900]!.withOpacity(0.95),
                        ]
                      : [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.90),
                        ],
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.25)
                      : Colors.white.withOpacity(0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.grey.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row - Date Selector and Status
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
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primary.withValues(alpha: 0.2),
                                              AppColors.primary.withValues(alpha: 0.1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppColors.primary.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            FaIcon(
                                              FontAwesomeIcons.calendarDay,
                                              color: AppColors.primary,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  isToday
                                                      ? 'Today'
                                                      : DateFormat('d MMM').format(widget.selectedDate),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              color: AppColors.primary,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!isToday)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.1)
                                              : Colors.white.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.15)
                                                : Colors.white.withValues(alpha: 0.6),
                                            width: 1,
                                          ),
                                        ),
                                        child: IconButton(
                                          onPressed: () => widget.onDateSelected(DateTime.now()),
                                          padding: EdgeInsets.zero,
                                          icon: Icon(
                                            Icons.today_rounded,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                            size: 20,
                                          ),
                                          tooltip: 'Go to Today',
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Status Badge
                        Flexible(
                          flex: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      statusColor.withValues(alpha: 0.25),
                                      statusColor.withValues(alpha: 0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (remainingCalories <= 0)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Text(
                                          '🎉',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          remainingCalories <= 0
                                              ? 'Goal!'
                                              : '${remainingCalories.toStringAsFixed(0)} left',
                                          style: GoogleFonts.inter(
                                            color: statusColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
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
                    const SizedBox(height: 16),

                    // Horizontal Layout: Circle Left, Stats Right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Circular Progress Indicator - Smooth animation with status color
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return CircularPercentIndicator(
                              radius: 55.0,
                              lineWidth: 10.0,
                              percent: _progressAnimation.value.clamp(0.0, 1.0),
                              center: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      statusColor.withValues(alpha: 0.2),
                                      statusColor.withValues(alpha: 0.08),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: AnimatedBuilder(
                                  animation: _fireAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _fireAnimation.value,
                                      child: Icon(
                                        Icons.local_fire_department_rounded,
                                        color: statusColor,
                                        size: 36,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              circularStrokeCap: CircularStrokeCap.round,
                              backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                              progressColor: statusColor,
                              animation: false, // Disable built-in animation, use AnimatedBuilder instead
                            );
                          },
                        ),
                        const SizedBox(width: 12),

                        // Stats Cards Stacked Vertically (Right Side)
                        Expanded(
                          child: Column(
                            children: [
                              _buildCompactStatCard(
                                icon: FontAwesomeIcons.fire,
                                label: 'Consumed',
                                value: widget.totalCaloriesConsumed.toStringAsFixed(0),
                                color: statusColor,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 8),
                              _buildCompactStatCard(
                                icon: FontAwesomeIcons.bullseye,
                                label: 'Remaining',
                                value: remainingCalories > 0
                                    ? remainingCalories.toStringAsFixed(0)
                                    : '0',
                                color: statusColor,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Show celebration animation when goal is reached
          if (_showCelebration)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: CelebrationAnimation(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Exact same style as health analysis cards
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[850]!.withValues(alpha: 0.95),
                  Colors.grey[900]!.withValues(alpha: 0.95),
                ]
              : [
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.90),
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon on left
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          // Label and value stacked
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

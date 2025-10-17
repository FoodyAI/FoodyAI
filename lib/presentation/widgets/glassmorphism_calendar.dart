import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';

class GlassmorphismCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const GlassmorphismCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  /// Show the glassmorphism calendar as a dialog
  static Future<DateTime?> showCalendarDialog({
    required BuildContext context,
    required DateTime selectedDate,
  }) async {
    return showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) {
        return GlassmorphismCalendar(
          selectedDate: selectedDate,
          onDateSelected: (date) {
            Navigator.of(context).pop(date);
          },
        );
      },
    );
  }

  @override
  State<GlassmorphismCalendar> createState() => _GlassmorphismCalendarState();
}

class _GlassmorphismCalendarState extends State<GlassmorphismCalendar> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _previousYear() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year - 1, _currentMonth.month);
    });
  }

  void _nextYear() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year + 1, _currentMonth.month);
    });
  }

  List<DateTime?> _getDaysInMonth() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // Get the weekday of the first day (1 = Monday, 7 = Sunday)
    final firstWeekday = firstDayOfMonth.weekday;

    // Calculate number of days to show from previous month
    final daysFromPrevMonth = firstWeekday % 7;

    // Build the days list - always fill 42 slots (6 rows x 7 days)
    List<DateTime?> days = [];

    // Add empty spaces for days before the first day of the month
    for (int i = 0; i < daysFromPrevMonth; i++) {
      days.add(null);
    }

    // Add all days of the current month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, day));
    }

    // Fill remaining slots with nulls to always have 42 cells (6 rows)
    while (days.length < 42) {
      days.add(null);
    }

    return days;
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  bool _isSelected(DateTime? date) {
    if (date == null) return false;
    return date.year == widget.selectedDate.year &&
           date.month == widget.selectedDate.month &&
           date.day == widget.selectedDate.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = _getDaysInMonth();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Year Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previousYear,
                      icon: FaIcon(
                        FontAwesomeIcons.anglesLeft,
                        size: 16,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Previous Year',
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${_currentMonth.year}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _nextYear,
                      icon: FaIcon(
                        FontAwesomeIcons.anglesRight,
                        size: 16,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Next Year',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Month Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previousMonth,
                      icon: FaIcon(
                        FontAwesomeIcons.chevronLeft,
                        size: 18,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Previous Month',
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _getMonthString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: FaIcon(
                        FontAwesomeIcons.chevronRight,
                        size: 18,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Next Month',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Weekday Headers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Calendar Grid - Fixed height with 42 cells (6 rows)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: 42, // Always 6 rows x 7 days = 42 cells
                  itemBuilder: (context, index) {
                    final date = days[index];
                    if (date == null) {
                      return const SizedBox.shrink();
                    }

                    final isToday = _isToday(date);
                    final isSelected = _isSelected(date);

                    return GestureDetector(
                      onTap: () => widget.onDateSelected(date),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.primary
                              : (isToday
                                  ? (isDark
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : AppColors.primary.withValues(alpha: 0.1))
                                  : Colors.transparent),
                          border: isToday && !isSelected
                              ? Border.all(
                                  color: AppColors.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthString() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[_currentMonth.month - 1];
  }
}

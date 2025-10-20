import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../domain/entities/user_profile.dart';
import '../viewmodels/image_analysis_viewmodel.dart';

class HealthInfoCard extends StatelessWidget {
  final UserProfile profile;
  final bool isMetric;

  const HealthInfoCard({
    Key? key,
    required this.profile,
    required this.isMetric,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final analysisVM = Provider.of<ImageAnalysisViewModel>(context);
    final todayAnalyses = analysisVM.filteredAnalyses;
    
    // Calculate total macros consumed today
    final totalCalories = todayAnalyses.fold<double>(
      0,
      (sum, analysis) => sum + analysis.calories,
    );
    final totalProtein = todayAnalyses.fold<double>(
      0,
      (sum, analysis) => sum + analysis.protein,
    );
    final totalFat = todayAnalyses.fold<double>(
      0,
      (sum, analysis) => sum + analysis.fat,
    );
    final totalCarbs = todayAnalyses.fold<double>(
      0,
      (sum, analysis) => sum + analysis.carbs,
    );
    
    // Calculate percentages based on calories
    // Protein: 4 cal/g, Fat: 9 cal/g, Carbs: 4 cal/g
    final proteinCalories = totalProtein * 4;
    final fatCalories = totalFat * 9;
    final carbsCalories = totalCarbs * 4;
    final totalMacroCalories = proteinCalories + fatCalories + carbsCalories;
    
    final proteinPercentage = totalMacroCalories > 0 
        ? (proteinCalories / totalMacroCalories * 100) 
        : 0.0;
    final fatPercentage = totalMacroCalories > 0 
        ? (fatCalories / totalMacroCalories * 100) 
        : 0.0;
    final carbsPercentage = totalMacroCalories > 0 
        ? (carbsCalories / totalMacroCalories * 100) 
        : 0.0;
    
    // Get BMI and health data
    final bmiValue = profile.bmi;
    final recommendedCalories = profile.dailyCalories;
    final caloriePercentage = recommendedCalories > 0 
        ? (totalCalories / recommendedCalories * 100).clamp(0, 100)
        : 0.0;
    
    // Determine health status and color
    String healthStatus;
    Color statusColor;
    if (bmiValue < 18.5) {
      healthStatus = 'Underweight';
      statusColor = const Color(0xFF4A90E2); // Blue
    } else if (bmiValue < 25.0) {
      healthStatus = 'Normal';
      statusColor = const Color(0xFF88D66C); // Green
    } else if (bmiValue < 30.0) {
      healthStatus = 'Overweight';
      statusColor = const Color(0xFFFF9F43); // Orange
    } else {
      healthStatus = 'Obesity';
      statusColor = const Color(0xFFE74C3C); // Red
    }

    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Calories Card
          _buildGlassmorphicCard(
            context,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Calories',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              totalCalories.toInt().toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.0,
                                letterSpacing: -1.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Kcal',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Circular Progress Indicator with Gradient
                CircularPercentIndicator(
                  radius: 55.0,
                  lineWidth: 10.0,
                  percent: (caloriePercentage / 100).clamp(0.0, 1.0),
                  center: Container(
                    padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
                          const Color(0xFFFF6B35).withOpacity(0.2),
                          const Color(0xFFFF6B35).withOpacity(0.08),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFF6B35),
                      size: 36,
                    ),
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                  linearGradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF4A90E2),
                      Color(0xFFFF9F43),
                      Color(0xFF88D66C),
                    ],
                  ),
                  animation: true,
                  animationDuration: 1200,
                  curve: Curves.easeInOutCubic,
          ),
        ],
      ),
          ),
          const SizedBox(height: 16),
          
          // BMI and Daily Calories Row
          Row(
              children: [
                Expanded(
                child: _buildInfoCard(
                  context,
                  'BMI',
                  bmiValue.toStringAsFixed(1),
                  healthStatus,
                  statusColor,
                  Icons.monitor_weight_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  context,
                  'Daily Calories',
                  recommendedCalories.toInt().toString(),
                  'Recommended',
                  const Color(0xFFFF6B35),
                  Icons.restaurant_outlined,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          
          // Macronutrient Cards
          Row(
                children: [
                  Expanded(
                child: _buildMacroCard(
                  context,
                  'Protein',
                  proteinPercentage,
                  totalProtein,
                  const Color(0xFF4A90E2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroCard(
                      context,
                  'Fat',
                  fatPercentage,
                  totalFat,
                  const Color(0xFFFF9F43),
                ),
              ),
              const SizedBox(width: 12),
                  Expanded(
                child: _buildMacroCard(
                      context,
                  'Carbs',
                  carbsPercentage,
                  totalCarbs,
                  const Color(0xFF88D66C),
                    ),
                  ),
                ],
              ),
          const SizedBox(height: 16),
          
          // Health Status Card at Bottom
          _buildGlassmorphicCard(
            context,
            padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                  ),
                const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Based on your profile, we recommend maintaining a balanced diet and regular exercise routine.',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildGlassmorphicCard(
    BuildContext context, {
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(24),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.08),
                      ]
                    : [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.85),
                      ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.25) 
                    : Colors.white.withOpacity(0.8),
                width: 2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return _buildGlassmorphicCard(
      context,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                icon,
                color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                    title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
              value,
            style: GoogleFonts.poppins(
              fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
                subtitle,
            style: GoogleFonts.inter(
                  fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(
    BuildContext context,
    String label,
    double percentage,
    double grams,
    Color color,
  ) {
    return _buildGlassmorphicCard(
      context,
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Progress with Percent Indicator
          CircularPercentIndicator(
            radius: 42.0,
            lineWidth: 8.0,
            percent: (percentage / 100).clamp(0.0, 1.0),
            center: Text(
              '${percentage.toInt()}%',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
            progressColor: color,
            animation: true,
            animationDuration: 1000,
            curve: Curves.easeInOutCubic,
          ),
          const SizedBox(height: 14),
          // Grams
          Text(
            '${grams.toInt()}g',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          // Label
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

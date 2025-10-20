import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../config/routes/navigation_service.dart';

class ErrorPage extends StatelessWidget {
  final String? errorMessage;
  final String? routeName;

  const ErrorPage({
    super.key,
    this.errorMessage,
    this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.triangleExclamation,
                    size: 50,
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Error Title
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Error Message
              Text(
                errorMessage ?? 'The page you\'re looking for doesn\'t exist.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? AppColors.white.withOpacity(0.7)
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              if (routeName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Route: $routeName',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.white.withOpacity(0.5)
                        : AppColors.textSecondary.withOpacity(0.7),
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 48),

              // Action Buttons
              Column(
                children: [
                  // Go Home Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        NavigationService.navigateToHome();
                      },
                      icon: const FaIcon(FontAwesomeIcons.house),
                      label: const Text('Go Home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Go Back Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          NavigationService.navigateToIntro();
                        }
                      },
                      icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                      label: const Text('Go Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

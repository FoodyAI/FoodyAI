import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../pages/onboarding_view.dart';
import '../pages/home_view.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? label;
  final bool isFullWidth;
  final bool isCompact;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.label,
    this.isFullWidth = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final button = ElevatedButton.icon(
      onPressed: isLoading ? null : (onPressed ?? () => _handleSignIn(context)),
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            )
          : Image.asset(
              'assets/google_logo.png',
              height: isCompact ? 16 : 20,
            ),
      label: Text(
        label ?? 'Sign in with Google',
        style: TextStyle(
          fontSize: isCompact ? 13 : 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode
            ? Theme.of(context).colorScheme.surface
            : AppColors.white,
        foregroundColor: isDarkMode ? AppColors.white : AppColors.textPrimary,
        padding: isCompact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
          side: BorderSide(
            color: isDarkMode
                ? AppColors.withOpacity(AppColors.primary, 0.2)
                : AppColors.grey300,
            width: 1,
          ),
        ),
        elevation: 0,
      ),
    );

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  Future<void> _handleSignIn(BuildContext context) async {
    try {
      print('Starting Google Sign-In...');
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      final profileVM = Provider.of<UserProfileViewModel>(context, listen: false);
      
      // Call the sign-in method through AuthViewModel
      final success = await authVM.signInWithGoogle();
      
      if (success) {
        print('Sign-in successful, determining user flow...');
        
        // Wait for initial sync to complete
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Force reload profile to ensure we have the latest data
        print('Forcing profile reload to check user status...');
        await profileVM.refreshProfile();
        
        // Check if we have profile data now
        bool hasProfile = profileVM.profile != null;
        bool hasCompletedOnboarding = profileVM.hasCompletedOnboarding;
        
        print('First check - hasProfile: $hasProfile, hasCompletedOnboarding: $hasCompletedOnboarding');
        
        // If no profile yet, try to load from AWS and wait longer
        if (!hasProfile) {
          print('No profile found locally, checking AWS...');
          
          // Wait longer for AWS sync to complete
          await Future.delayed(const Duration(milliseconds: 2000));
          await profileVM.refreshProfile();
          
          hasProfile = profileVM.profile != null;
          hasCompletedOnboarding = profileVM.hasCompletedOnboarding;
          print('After AWS sync - hasProfile: $hasProfile, hasCompletedOnboarding: $hasCompletedOnboarding');
        }
        
        if (context.mounted) {
          // Use the variables we already calculated
          print('Final user status: hasCompletedOnboarding=$hasCompletedOnboarding, hasProfile=$hasProfile');
          
          if (hasCompletedOnboarding && hasProfile) {
            // Existing user with complete profile - navigate to home page
            print('Existing user with profile detected - navigating to home');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome back, ${authVM.userDisplayName ?? authVM.userEmail}!'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
            
            // Explicitly navigate to home page
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const HomeView(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOutCubic;
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);
                  return SlideTransition(
                    position: offsetAnimation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 800),
              ),
            );
            
          } else {
            // First-time user OR user without profile - navigate to onboarding
            if (!hasProfile) {
              print('User signed in but no profile found in AWS - treating as first-time user');
              print('This could be: 1) First-time user, 2) AWS sync failed, 3) Profile not created yet');
            } else if (!hasCompletedOnboarding) {
              print('User has profile but onboarding not completed - continuing onboarding');
            } else {
              print('First-time user detected - navigating to onboarding');
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome to Foody, ${authVM.userDisplayName ?? authVM.userEmail}!'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
            
            // Navigate to onboarding with smooth transition
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const OnboardingView(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOutCubic;
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);
                  return SlideTransition(
                    position: offsetAnimation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 800),
              ),
            );
          }
        }
      } else {
        // User cancelled or error occurred
        print('Sign-in cancelled or failed');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-in cancelled'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Handle error
      print('Sign-in error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// Shared function to show Google Sign-In coming soon message
void showGoogleSignInComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Google Sign-In coming soon!'),
      duration: Duration(seconds: 2),
    ),
  );
}

/// Dialog to show sign-in benefits and prompt
class SignInDialog extends StatelessWidget {
  const SignInDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.rightToBracket,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text('Sign In to Foody'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sign in to:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildBenefit(isDark, FontAwesomeIcons.cloudArrowUp,
              'Sync data across devices'),
          const SizedBox(height: 8),
          _buildBenefit(isDark, FontAwesomeIcons.shieldHalved,
              'Backup your food history'),
          const SizedBox(height: 8),
          _buildBenefit(
              isDark, FontAwesomeIcons.chartLine, 'Access advanced analytics'),
          const SizedBox(height: 20),
          GoogleSignInButton(
            isFullWidth: true,
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              await _handleSignInFromDialog(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Maybe Later',
            style: TextStyle(color: colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefit(bool isDark, IconData icon, String text) {
    return Row(
      children: [
        FaIcon(
          icon,
          size: 16,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignInFromDialog(BuildContext context) async {
    try {
      print('Starting Google Sign-In from dialog...');
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      
      // Call the sign-in method through AuthViewModel
      final success = await authVM.signInWithGoogle();
      
      if (success) {
        // Successfully signed in - UI will update automatically via Provider
        print('Dialog sign-in successful, showing success message');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome, ${authVM.userDisplayName ?? authVM.userEmail}!'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // User cancelled or error occurred
        print('Dialog sign-in cancelled or failed');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-in cancelled'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Handle error
      print('Dialog sign-in error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

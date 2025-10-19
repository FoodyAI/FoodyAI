/// Example usage of the IntroOnboardingScreen
///
/// This file demonstrates different ways to use and customize
/// the onboarding screen in your app.

import 'package:flutter/material.dart';
import 'intro_onboarding_screen.dart';

/// Example 1: Basic Usage
/// Navigate to the intro screen from anywhere in your app
class NavigationExample {
  static void navigateToIntro(BuildContext context) {
    Navigator.pushNamed(context, '/intro');
  }

  static void navigateToIntroReplacement(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/intro');
  }
}

/// Example 2: Custom Configuration Path
/// Use a different configuration file
class CustomConfigExample extends StatelessWidget {
  const CustomConfigExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const IntroOnboardingScreen(
      // Use a custom configuration file
      configPath: 'assets/config/custom_onboarding.json',
    );
  }
}

/// Example 3: Integration with Splash Screen
/// Determine which screen to show based on user state
class SplashScreenExample extends StatelessWidget {
  const SplashScreenExample({super.key});

  void _navigateToAppropriateScreen(BuildContext context) {
    // Simulated user state checks
    final isFirstTimeUser = true;
    final isAuthenticated = false;
    final hasCompletedOnboarding = false;

    if (isFirstTimeUser && !hasCompletedOnboarding) {
      // Show intro onboarding first
      Navigator.pushReplacementNamed(context, '/intro');
    } else if (!isAuthenticated) {
      // Show welcome/auth screen
      Navigator.pushReplacementNamed(context, '/welcome');
    } else {
      // Go directly to home
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simulate loading and navigation
    Future.delayed(const Duration(seconds: 2), () {
      _navigateToAppropriateScreen(context);
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Example 4: Programmatic Navigation Flow
/// Handle onboarding completion in your app
class OnboardingFlowExample {
  /// After user completes intro onboarding
  static void onIntroComplete(BuildContext context, {required bool isAuthenticated}) {
    if (isAuthenticated) {
      // User is authenticated, go to profile onboarding
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      // User needs to authenticate first
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  /// After user skips intro onboarding
  static void onIntroSkipped(BuildContext context) {
    // Take user to welcome screen to sign in
    Navigator.pushReplacementNamed(context, '/welcome');
  }
}

/// Example 5: Testing Different Configurations
/// Test screen with different config files
class ConfigTestScreen extends StatelessWidget {
  const ConfigTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Onboarding Configs')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildConfigButton(
            context,
            'Default Config',
            'assets/config/onboarding_config.json',
          ),
          _buildConfigButton(
            context,
            'Health Focus',
            'assets/config/onboarding_health.json',
          ),
          _buildConfigButton(
            context,
            'Nutrition Focus',
            'assets/config/onboarding_nutrition.json',
          ),
        ],
      ),
    );
  }

  Widget _buildConfigButton(BuildContext context, String label, String configPath) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IntroOnboardingScreen(
                configPath: configPath,
              ),
            ),
          );
        },
        child: Text(label),
      ),
    );
  }
}

/// Example 6: Custom Navigation Routes
/// Customize where users go after onboarding
///
/// To customize routes, edit the JSON configuration:
/// ```json
/// {
///   "navigation": {
///     "on_complete_route": "/custom-complete",
///     "on_skip_route": "/custom-skip",
///     "allow_back_navigation": true
///   }
/// }
/// ```

/// Example 7: Conditional Onboarding
/// Show different onboarding based on user type
class ConditionalOnboardingExample {
  static void showOnboarding(
    BuildContext context, {
    required String userType,
  }) {
    String configPath;

    switch (userType) {
      case 'nutritionist':
        configPath = 'assets/config/onboarding_nutritionist.json';
        break;
      case 'athlete':
        configPath = 'assets/config/onboarding_athlete.json';
        break;
      case 'general':
      default:
        configPath = 'assets/config/onboarding_config.json';
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntroOnboardingScreen(
          configPath: configPath,
        ),
      ),
    );
  }
}

/// Example 8: A/B Testing Different Onboarding Flows
/// Show different versions to different users
class ABTestingExample {
  static void showOnboardingVariant(BuildContext context, {required int variant}) {
    final configPath = variant == 1
        ? 'assets/config/onboarding_variant_a.json'
        : 'assets/config/onboarding_variant_b.json';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntroOnboardingScreen(
          configPath: configPath,
        ),
      ),
    );
  }
}

/// Example 9: Integration with State Management
/// Using Provider, Riverpod, or Bloc
class StateManagementExample {
  // Using Provider
  static void navigateWithProvider(BuildContext context) {
    // final userState = context.read<UserStateProvider>();
    //
    // if (userState.shouldShowOnboarding) {
    //   Navigator.pushNamed(context, '/intro');
    // } else {
    //   Navigator.pushNamed(context, '/home');
    // }
  }

  // Using shared preferences to track if onboarding was shown
  static Future<void> markOnboardingComplete() async {
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool('onboarding_completed', true);
  }

  static Future<bool> hasCompletedOnboarding() async {
    // final prefs = await SharedPreferences.getInstance();
    // return prefs.getBool('onboarding_completed') ?? false;
    return false;
  }
}

/// Example 10: Customizing the Onboarding Screen
/// Extend or wrap the screen with additional functionality
class CustomOnboardingWrapper extends StatelessWidget {
  const CustomOnboardingWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent back button during onboarding
      onWillPop: () async => false,
      child: const IntroOnboardingScreen(),
    );
  }
}

/*
 * QUICK START GUIDE
 *
 * 1. Navigate to onboarding:
 *    Navigator.pushNamed(context, '/intro');
 *
 * 2. Customize in JSON:
 *    Edit assets/config/onboarding_config.json
 *
 * 3. Add new pages:
 *    Add objects to "onboarding_pages" array in JSON
 *
 * 4. Change colors:
 *    Update "theme" section in JSON
 *
 * 5. Modify navigation:
 *    Update "navigation" section in JSON
 *
 * For more details, see ONBOARDING_README.md
 */

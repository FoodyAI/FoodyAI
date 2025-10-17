import 'package:flutter/material.dart';
import '../../presentation/pages/splash_screen.dart';
import '../../presentation/pages/welcome_view.dart';
import '../../presentation/pages/onboarding_view.dart';
import '../../presentation/pages/home_view.dart';
import '../../presentation/pages/analyze_view.dart';
import '../../presentation/pages/profile_view.dart';
import '../../presentation/pages/barcode_scanner_view.dart';
import '../../presentation/pages/analysis_loading_view.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String analyze = '/analyze';
  static const String profile = '/profile';
  static const String barcodeScanner = '/barcode-scanner';
  static const String analysisLoading = '/analysis-loading';

  // Route arguments
  static const String isFirstTimeUser = 'isFirstTimeUser';
  static const String connectionBanner = 'connectionBanner';

  /// Get all route definitions
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      welcome: (context) => const WelcomeScreen(),
      onboarding: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return OnboardingView(
          isFirstTimeUser: args?[isFirstTimeUser] ?? false,
        );
      },
      home: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return HomeView(
          connectionBanner: args?[connectionBanner],
        );
      },
      analyze: (context) => const AnalyzeView(),
      profile: (context) => const ProfileView(),
      barcodeScanner: (context) => const BarcodeScannerView(),
      analysisLoading: (context) => const AnalysisLoadingView(),
    };
  }

  /// Check if route requires authentication
  static bool requiresAuth(String routeName) {
    const protectedRoutes = {
      home,
      analyze,
      profile,
      barcodeScanner,
      analysisLoading,
    };
    return protectedRoutes.contains(routeName);
  }

  /// Check if route requires onboarding completion
  static bool requiresOnboarding(String routeName) {
    const onboardingRequiredRoutes = {
      home,
      analyze,
      profile,
      barcodeScanner,
    };
    return onboardingRequiredRoutes.contains(routeName);
  }
}

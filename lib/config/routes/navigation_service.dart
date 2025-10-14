import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'route_transitions.dart';
import 'route_guards.dart';
import '../../presentation/widgets/connection_banner.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Get current context
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Navigate to a named route
  static Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate to a named route and remove all previous routes
  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  /// Navigate to a named route and replace current route
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return navigatorKey.currentState!.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  /// Pop current route
  static void pop<T extends Object?>([T? result]) {
    navigatorKey.currentState!.pop<T>(result);
  }

  /// Pop until a specific route
  static void popUntil(String routeName) {
    navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
  }

  /// Check if can pop
  static bool canPop() {
    return navigatorKey.currentState!.canPop();
  }

  /// Navigate with custom transition
  static Future<T?> pushWithTransition<T extends Widget>(
    T page, {
    String? routeName,
    PageRouteBuilder<T> Function(Widget)? transition,
  }) {
    final routeTransition = transition ??
        (widget) => RouteTransitions.slideFromRight<T>(widget as T);
    return navigatorKey.currentState!.push<T>(
      routeTransition(page),
    );
  }

  /// Navigate to home with connection banner
  static Future<void> navigateToHome({
    ConnectionBanner? connectionBanner,
  }) {
    return pushNamedAndRemoveUntil(
      AppRoutes.home,
      arguments: {
        AppRoutes.connectionBanner: connectionBanner,
      },
    );
  }

  /// Navigate to onboarding
  static Future<void> navigateToOnboarding({bool isFirstTimeUser = false}) {
    return pushNamedAndRemoveUntil(
      AppRoutes.onboarding,
      arguments: {
        AppRoutes.isFirstTimeUser: isFirstTimeUser,
      },
    );
  }

  /// Navigate to welcome screen
  static Future<void> navigateToWelcome() {
    return pushNamedAndRemoveUntil(AppRoutes.welcome);
  }

  /// Navigate to profile
  static Future<void> navigateToProfile() {
    return pushNamed(AppRoutes.profile);
  }

  /// Navigate to analyze
  static Future<void> navigateToAnalyze() {
    return pushNamed(AppRoutes.analyze);
  }

  /// Navigate to barcode scanner
  static Future<void> navigateToBarcodeScanner() {
    return pushNamed(AppRoutes.barcodeScanner);
  }

  /// Navigate to analysis loading
  static Future<void> navigateToAnalysisLoading() {
    return pushNamedAndRemoveUntil(AppRoutes.analysisLoading);
  }

  /// Navigate with route guard check
  static Future<T?> pushNamedWithGuard<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) async {
    final context = currentContext;
    if (context == null) return null;

    // Check if user can access the route
    final canAccess = await RouteGuards.canAccessRoute(context, routeName);

    if (!canAccess) {
      // Handle access denied
      RouteGuards.handleAccessDenied(context, routeName);
      return null;
    }

    // Navigate to the route
    return pushNamed<T>(routeName, arguments: arguments);
  }
}

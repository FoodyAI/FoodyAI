import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'di/service_locator.dart';
import 'data/services/migration_service.dart';
import 'presentation/viewmodels/user_profile_viewmodel.dart';
import 'presentation/viewmodels/image_analysis_viewmodel.dart';
import 'presentation/viewmodels/theme_viewmodel.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/pages/welcome_view.dart';
import 'presentation/pages/error_page.dart';
import 'core/utils/theme.dart';
import 'presentation/widgets/connection_banner.dart';
import 'config/routes/app_routes.dart';
import 'config/routes/route_transitions.dart';
import 'config/routes/navigation_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  print('Firebase initialized successfully!');

  // Set background message handler for FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  print('FCM background message handler registered');

  await dotenv.load(fileName: ".env");
  setupServiceLocator();

  // Initialize migration from SharedPreferences to SQLite
  final migrationService = MigrationService();
  await migrationService.migrateFromSharedPreferences();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<UserProfileViewModel>()),
        ChangeNotifierProvider(create: (_) => ImageAnalysisViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => getIt<AuthViewModel>()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVM, _) {
          return MaterialApp(
            title: 'foody',
            debugShowCheckedModeBanner: false,
            navigatorKey: NavigationService.navigatorKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeVM.themeMode,
            initialRoute: AppRoutes.welcome,
            onGenerateRoute: _generateRoute,
            onUnknownRoute: _unknownRoute,
          );
        },
      ),
    );
  }

  /// Generate routes dynamically with authentication and onboarding checks
  static Route<dynamic>? _generateRoute(RouteSettings settings) {
    final routeName = settings.name ?? AppRoutes.welcome;

    // Handle initial route - determine where to go based on user state
    if (routeName == AppRoutes.welcome) {
      return _handleInitialRoute(settings);
    }

    // Get the route builder
    final routes = AppRoutes.getRoutes();
    final routeBuilder = routes[routeName];

    if (routeBuilder == null) {
      return RouteTransitions.slideFromRight(
        ErrorPage(
          errorMessage: 'Route not found: $routeName',
          routeName: routeName,
        ),
      );
    }

    // Create the page with arguments
    final page = routeBuilder(NavigationService.navigatorKey.currentContext!);

    // Return route with custom transition
    return RouteTransitions.getTransitionForRoute(routeName, page);
  }

  /// Handle initial route determination
  static Route<dynamic> _handleInitialRoute(RouteSettings settings) {
    final context = NavigationService.navigatorKey.currentContext!;

    // Get ViewModels
    final userProfileVM = context.read<UserProfileViewModel>();
    final authVM = context.read<AuthViewModel>();

    // Determine the correct initial route
    String targetRoute;
    Map<String, dynamic>? arguments;

    if (!authVM.isSignedIn) {
      targetRoute = AppRoutes.welcome;
    } else if (!userProfileVM.hasCompletedOnboarding) {
      targetRoute = AppRoutes.onboarding;
      arguments = {AppRoutes.isFirstTimeUser: true};
    } else {
      targetRoute = AppRoutes.home;
      arguments = {
        AppRoutes.connectionBanner: ConnectionBanner(isConnected: true),
      };
    }

    // If we need to redirect, do it after the current route is built
    if (targetRoute != AppRoutes.welcome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NavigationService.pushNamedAndRemoveUntil(
          targetRoute,
          arguments: arguments,
        );
      });
    }

    // Return the welcome screen as the initial route
    return RouteTransitions.slideFromRight(const WelcomeScreen());
  }

  /// Handle unknown routes
  static Route<dynamic> _unknownRoute(RouteSettings settings) {
    return RouteTransitions.slideFromRight(
      ErrorPage(
        errorMessage: 'Page not found',
        routeName: settings.name,
      ),
    );
  }
}

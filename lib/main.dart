import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'presentation/pages/error_page.dart';
import 'core/utils/theme.dart';
import 'config/routes/app_routes.dart';
import 'config/routes/route_transitions.dart';
import 'config/routes/navigation_service.dart';
import 'services/notification_service.dart';
import 'core/services/connection_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock app to portrait mode only (disable rotation)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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

  // Initialize and start monitoring network connection
  final connectionService = ConnectionService();
  connectionService.startMonitoring();
  print('🌐 ConnectionService: Started monitoring network status');

  runApp(MyApp(connectionService: connectionService));
}

class MyApp extends StatelessWidget {
  final ConnectionService connectionService;

  const MyApp({super.key, required this.connectionService});

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
          return AnimatedTheme(
            data: themeVM.themeMode == ThemeMode.dark
                ? AppTheme.darkTheme
                : AppTheme.lightTheme,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: MaterialApp(
              title: 'foody',
              debugShowCheckedModeBanner: false,
              navigatorKey: NavigationService.navigatorKey,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeVM.themeMode,
              initialRoute: AppRoutes.splash,
              onGenerateRoute: _generateRoute,
              onUnknownRoute: _unknownRoute,
            ),
          );
        },
      ),
    );
  }

  /// Generate routes dynamically
  static Route<dynamic>? _generateRoute(RouteSettings settings) {
    final routeName = settings.name ?? AppRoutes.splash;

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

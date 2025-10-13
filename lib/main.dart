import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'di/service_locator.dart';
import 'data/services/migration_service.dart';
import 'presentation/viewmodels/user_profile_viewmodel.dart';
import 'presentation/viewmodels/image_analysis_viewmodel.dart';
import 'presentation/viewmodels/theme_viewmodel.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/pages/home_view.dart';
import 'presentation/pages/onboarding_view.dart';
import 'core/utils/theme.dart';
import 'core/services/connection_service.dart';
import 'presentation/widgets/connection_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  print('Firebase initialized successfully!');
  
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
            navigatorKey: navigatorKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeVM.themeMode,
            home: const AppNavigator(),
          );
        },
      ),
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  final ConnectionService _connectionService = ConnectionService();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _connectionService.startMonitoring();
    _connectionService.connectionStream.listen((isConnected) {
      setState(() {
        _isConnected = isConnected;
      });
    });
  }

  @override
  void dispose() {
    _connectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileVM = context.watch<UserProfileViewModel>();

    // Show loading indicator while checking user state
    if (userProfileVM.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If onboarding is not completed, show onboarding screen (not welcome screen)
    if (!userProfileVM.hasCompletedOnboarding) {
      return const OnboardingView(isFirstTimeUser: true);
    }

    // If onboarding is completed, show home with connection banner
    return HomeView(
      connectionBanner: ConnectionBanner(
        isConnected: _isConnected,
      ),
    );
  }
}

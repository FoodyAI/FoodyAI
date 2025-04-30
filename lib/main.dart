import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'di/service_locator.dart';
import 'presentation/viewmodels/user_profile_viewmodel.dart';
import 'presentation/viewmodels/image_analysis_viewmodel.dart';
import 'presentation/pages/welcome_view.dart';
import 'presentation/pages/home_view.dart';
import 'core/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  setupServiceLocator();
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
      ],
      child: MaterialApp(
        title: 'Foody',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const AppNavigator(),
      ),
    );
  }
}

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

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

    // If onboarding is not completed, show welcome screen
    if (!userProfileVM.hasCompletedOnboarding) {
      return const WelcomeScreen();
    }

    // If onboarding is completed, show home
    return const HomeView();
  }
}

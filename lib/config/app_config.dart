import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/viewmodels/user_profile_viewmodel.dart';
import '../presentation/viewmodels/image_analysis_viewmodel.dart';
import '../presentation/pages/onboarding_view.dart';
import '../presentation/pages/home_view.dart';
import '../core/utils/theme.dart';
import '../di/service_locator.dart';

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
        title: 'AI Image Analysis',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: Consumer<UserProfileViewModel>(
          builder: (ctx, profileVM, _) {
            if (profileVM.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return profileVM.profile == null
                ? const OnboardingView()
                : const HomeView();
          },
        ),
      ),
    );
  }
}

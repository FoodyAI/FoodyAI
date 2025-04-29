import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_profile_viewmodel.dart';
import '../../domain/entities/user_profile.dart';
import '../pages/onboarding_view.dart';

class WelcomeViewModel extends ChangeNotifier {
  bool _isGoogleLoading = false;
  bool _isGuestLoading = false;
  bool get isLoading => _isGoogleLoading || _isGuestLoading;
  bool get isGoogleLoading => _isGoogleLoading;
  bool get isGuestLoading => _isGuestLoading;

  Future<void> signInWithGoogle() async {
    _isGoogleLoading = true;
    notifyListeners();

    // TODO: Implement Google Sign In
    await Future.delayed(const Duration(seconds: 1)); // Simulated delay

    _isGoogleLoading = false;
    notifyListeners();
  }

  void continueAsGuest(BuildContext context) async {
    _isGuestLoading = true;
    notifyListeners();

    // Get the UserProfileViewModel and create an empty profile for guest
    final userProfileVM =
        Provider.of<UserProfileViewModel>(context, listen: false);
    await userProfileVM.saveProfile(
      gender: 'Not specified',
      age: 25,
      weight: 70,
      weightUnit: 'kg',
      height: 170,
      heightUnit: 'cm',
      activityLevel: ActivityLevel.moderatelyActive,
      isMetric: true,
    );

    _isGuestLoading = false;
    notifyListeners();

    // Navigate to onboarding view with a smooth transition
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
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

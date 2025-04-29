import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_profile_viewmodel.dart';
import '../../domain/entities/user_profile.dart';
import '../pages/onboarding_view.dart';

class WelcomeViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    // TODO: Implement Google Sign In
    await Future.delayed(const Duration(seconds: 1)); // Simulated delay

    _isLoading = false;
    notifyListeners();
  }

  void continueAsGuest(BuildContext context) async {
    _isLoading = true;
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

    _isLoading = false;
    notifyListeners();

    // Navigate to onboarding view
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingView()),
    );
  }
}

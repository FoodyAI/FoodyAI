import 'package:flutter/material.dart';

class WelcomeViewModel extends ChangeNotifier {
  final bool _isGoogleLoading = false;
  bool get isLoading => _isGoogleLoading;
  bool get isGoogleLoading => _isGoogleLoading;

  // This method is no longer used - Google sign-in is handled by GoogleSignInButton widget
}

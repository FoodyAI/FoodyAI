import 'package:flutter/material.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/usecases/user_profile_usecase.dart';

class UserProfileViewModel extends ChangeNotifier {
  final UserProfileUseCase _useCase;
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isMetric = true;
  bool _hasCompletedOnboarding = false;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isMetric => _isMetric;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isGuest => _profile?.isGuest ?? false;

  UserProfileViewModel(this._useCase) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final profile = await _useCase.getProfile();
      final isMetric = await _useCase.getIsMetric();
      final hasCompletedOnboarding = await _useCase.getHasCompletedOnboarding();
      _profile = profile;
      _isMetric = isMetric;
      _hasCompletedOnboarding = hasCompletedOnboarding;
    } catch (e) {
      // Handle error silently
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile({
    required String gender,
    required int age,
    required double weight,
    required String weightUnit,
    required double height,
    required String heightUnit,
    required ActivityLevel activityLevel,
    required bool isMetric,
    WeightGoal? weightGoal,
    AIProvider? aiProvider,
    bool? isGuest,
  }) async {
    _isMetric = isMetric;
    final weightKg = weightUnit == 'lbs' ? weight * 0.453592 : weight;
    final heightCm = heightUnit == 'inch' ? height * 2.54 : height;

    _profile = UserProfile(
      gender: gender,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
      activityLevel: activityLevel,
      weightGoal: weightGoal ?? _profile?.weightGoal ?? WeightGoal.maintain,
      aiProvider: aiProvider ?? _profile?.aiProvider ?? AIProvider.openai,
      isGuest: isGuest ?? _profile?.isGuest ?? true,
    );

    await _useCase.saveProfile(_profile!, isMetric);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await _useCase.setHasCompletedOnboarding(true);
    notifyListeners();
  }

  Future<void> clearProfile() async {
    await _useCase.clearProfile();
    _profile = null;
    _hasCompletedOnboarding = false;
    notifyListeners();
  }

  // Helper methods for unit conversion
  String get weightUnit => _isMetric ? 'kg' : 'lbs';
  String get heightUnit => _isMetric ? 'cm' : 'inch';

  double get displayWeight => _profile == null
      ? 0
      : _isMetric
          ? _profile!.weightKg
          : _profile!.weightKg * 2.20462;

  double get displayHeight => _profile == null
      ? 0
      : _isMetric
          ? _profile!.heightCm
          : _profile!.heightCm / 2.54;
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/usecases/user_profile_usecase.dart';
import '../../core/events/profile_update_event.dart';
import '../../services/sync_service.dart';
import '../../data/services/sqlite_service.dart';
import 'dart:async';

class UserProfileViewModel extends ChangeNotifier {
  final UserProfileUseCase _useCase;
  final SyncService _syncService = SyncService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SQLiteService _sqliteService = SQLiteService();
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isMetric = true;
  bool _hasCompletedOnboarding = false;
  StreamSubscription? _profileUpdateSubscription;
  bool _isLoadingProfile = false; // Flag to prevent duplicate profile loading

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isMetric => _isMetric;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  UserProfileViewModel(this._useCase) {
    // Initialize: Load onboarding status first (critical for routing)
    // Then load full profile
    _initializeUserData();
    _profileUpdateSubscription = ProfileUpdateEvent.stream.listen((_) {
      _loadProfile();
    });
  }

  /// Initialize user data - loads onboarding status immediately
  Future<void> _initializeUserData() async {
    try {
      // Load onboarding status FIRST (critical for routing decisions)
      final hasCompleted = await _useCase.getHasCompletedOnboarding();
      _hasCompletedOnboarding = hasCompleted;
      print('✅ UserProfileViewModel: Onboarding status: $hasCompleted');
      notifyListeners();

      // Then load full profile
      await _loadProfile();
    } catch (e) {
      print('⚠️ UserProfileViewModel: Error initializing user data: $e');
    }
  }

  Future<void> _loadProfile() async {
    // 🔧 FIX #3: Add timeout to prevent deadlock with retry logic
    if (_isLoadingProfile) {
      print('⏭️ UserProfileViewModel: Already loading, waiting for completion...');
      // Wait max 5 seconds for current load to complete, then force retry
      await Future.delayed(const Duration(seconds: 5));
      if (_isLoadingProfile) {
        print('⚠️ UserProfileViewModel: Load timeout detected, forcing reset');
        _isLoadingProfile = false; // Reset stuck flag
      }
    }

    _isLoadingProfile = true;
    _isLoading = true;
    notifyListeners();

    int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        print('📥 UserProfileViewModel: Loading profile (attempt ${retryCount + 1}/$maxRetries)...');
        final userId = _auth.currentUser?.uid;
        final profile = await _useCase.getProfile(userId: userId);
        final isMetric = await _useCase.getIsMetric();
        final hasCompletedOnboarding = await _useCase.getHasCompletedOnboarding();

        _profile = profile;
        _isMetric = isMetric;
        _hasCompletedOnboarding = hasCompletedOnboarding;

        print('✅ UserProfileViewModel: Profile loaded successfully');
        print('   - Has profile: ${profile != null}');
        print('   - Onboarding complete: $hasCompletedOnboarding');

        // Success - exit retry loop
        break;
      } catch (e) {
        retryCount++;
        print('⚠️ UserProfileViewModel: Error loading profile (attempt $retryCount/$maxRetries): $e');

        if (retryCount >= maxRetries) {
          print('❌ UserProfileViewModel: All retry attempts failed');
          // Don't throw - let app continue with empty profile
          break;
        }

        // Exponential backoff: 100ms, 500ms, 1000ms
        final delayMs = retryCount == 1 ? 100 : (retryCount == 2 ? 500 : 1000);
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    // Always reset flags in finally block
    _isLoading = false;
    _isLoadingProfile = false;
    notifyListeners();
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
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('❌ UserProfileViewModel: No authenticated user');
      throw Exception('User must be authenticated to save profile');
    }

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
      aiProvider: aiProvider ?? _profile?.aiProvider ?? AIProvider.gemini,
    );

    await _useCase.saveProfile(_profile!, isMetric, userId: userId);

    // Sync with AWS since user is authenticated
    // Get actual theme preference from SQLite
    final themePreference =
        await _sqliteService.getThemePreference() ?? 'system';

    await _syncService.updateUserProfileInAWS(
      gender: gender,
      age: age,
      weight: weightKg,
      height: heightCm,
      activityLevel: activityLevel.name,
      goal: weightGoal?.name,
      themePreference: themePreference,
      aiProvider: aiProvider?.name,
      measurementUnit: isMetric ? 'metric' : 'imperial',
    );

    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await _useCase.setHasCompletedOnboarding(true);
    notifyListeners();
  }

  Future<void> clearProfile() async {
    final userId = _auth.currentUser?.uid;
    await _useCase.clearProfile(userId: userId);
    _profile = null;
    _hasCompletedOnboarding = false;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    await _loadProfile();
  }

  @override
  void dispose() {
    _profileUpdateSubscription?.cancel();
    super.dispose();
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

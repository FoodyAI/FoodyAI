import 'package:firebase_auth/firebase_auth.dart';
import 'aws_service.dart';
import '../domain/entities/user_profile.dart';
import '../domain/entities/ai_provider.dart';
import '../data/repositories/user_profile_repository_impl.dart';
import '../data/services/sqlite_service.dart';

enum UserState {
  firstTime,           // New user, no AWS profile
  returningComplete,   // Existing user with complete profile
  returningIncomplete, // User with partial profile/onboarding
  networkError,        // Cannot determine due to network issues
  authError,          // Authentication issues
}

class UserStateResult {
  final UserState state;
  final String? message;
  final UserProfile? profile;
  final bool hasCompletedOnboarding;
  final Exception? error;

  UserStateResult({
    required this.state,
    this.message,
    this.profile,
    this.hasCompletedOnboarding = false,
    this.error,
  });

  bool get isSuccess => error == null && state != UserState.networkError && state != UserState.authError;
}

class UserStateService {
  final AWSService _awsService = AWSService();
  final UserProfileRepositoryImpl _userProfileRepository = UserProfileRepositoryImpl();
  final SQLiteService _sqliteService = SQLiteService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _awsTimeout = Duration(seconds: 10);

  /// Intelligently determines the user's state after authentication
  Future<UserStateResult> determineUserState({
    bool forceRefresh = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return UserStateResult(
          state: UserState.authError,
          message: 'User not authenticated',
        );
      }

      print('🔍 UserStateService: Determining state for user: ${user.email}');

      // Step 1: ALWAYS check AWS first (source of truth)
      // Don't rely on local data as it might be stale after account deletion
      print('☁️ UserStateService: Checking AWS first (source of truth)...');
      final awsResult = await _checkAWSProfileWithRetry(user.uid);
      
      if (awsResult.error != null) {
        // Network error - fall back to local data only if AWS is unreachable
        print('⚠️ UserStateService: AWS unreachable, checking local data as fallback');
        
        UserProfile? localProfile;
        bool localOnboardingComplete = false;
        
        try {
          localProfile = await _userProfileRepository.getProfile();
          localOnboardingComplete = await _userProfileRepository.getHasCompletedOnboarding();
          
          if (localProfile != null) {
            print('📱 UserStateService: Using local fallback data');
            return UserStateResult(
              state: localOnboardingComplete ? UserState.returningComplete : UserState.returningIncomplete,
              profile: localProfile,
              hasCompletedOnboarding: localOnboardingComplete,
              message: 'Using offline profile. Will sync when connection improves.',
            );
          }
        } catch (e) {
          print('⚠️ UserStateService: Error reading local fallback data: $e');
        }
        
        return UserStateResult(
          state: UserState.networkError,
          message: 'Cannot verify profile. Please check your connection and try again.',
          error: awsResult.error,
        );
      }

      // Step 2: Analyze AWS profile data (definitive source)
      final awsProfile = awsResult.profile;
      final awsOnboardingComplete = awsResult.hasCompletedOnboarding;

      print('☁️ UserStateService: AWS profile found: ${awsProfile != null}');
      print('☁️ UserStateService: AWS onboarding complete: $awsOnboardingComplete');

      if (awsProfile == null) {
        // No AWS profile - definitely a first-time user
        // Clear any stale local data that might exist
        print('🧹 UserStateService: No AWS profile found - clearing any stale local data');
        await _clearStaleLocalData();
        
        return UserStateResult(
          state: UserState.firstTime,
          message: 'Welcome to Foody! Let\'s set up your profile.',
        );
      }

      // Step 3: AWS profile exists - sync to local storage
      await _syncAWSToLocal(awsProfile, awsOnboardingComplete);

      // Step 4: Determine final state based on AWS data
      if (awsOnboardingComplete && _isProfileComplete(awsProfile)) {
        return UserStateResult(
          state: UserState.returningComplete,
          profile: awsProfile,
          hasCompletedOnboarding: true,
          message: 'Welcome back!',
        );
      } else {
        return UserStateResult(
          state: UserState.returningIncomplete,
          profile: awsProfile,
          hasCompletedOnboarding: awsOnboardingComplete,
          message: 'Let\'s continue setting up your profile.',
        );
      }

    } catch (e) {
      print('❌ UserStateService: Unexpected error determining user state: $e');
      return UserStateResult(
        state: UserState.authError,
        message: 'An unexpected error occurred. Please try again.',
        error: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Check AWS profile with retry logic and timeout
  Future<UserStateResult> _checkAWSProfileWithRetry(String userId) async {
    Exception? lastError;
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        print('🔄 UserStateService: AWS attempt $attempt/$_maxRetries');
        
        final profileData = await _awsService.getUserProfile(userId)
            .timeout(_awsTimeout);

        if (profileData != null && profileData['success'] == true) {
          final userData = profileData['user'];
          final profile = _parseAWSProfile(userData);
          final onboardingComplete = _isOnboardingComplete(userData);
          
          return UserStateResult(
            state: UserState.returningComplete, // Will be refined later
            profile: profile,
            hasCompletedOnboarding: onboardingComplete,
          );
        } else if (profileData != null && profileData['success'] == false) {
          // User doesn't exist in AWS
          print('✅ UserStateService: User not found in AWS - first-time user');
          return UserStateResult(
            state: UserState.firstTime,
          );
        } else {
          throw Exception('Invalid AWS response');
        }
        
      } catch (e) {
        // Check if this is a 404 error (user doesn't exist)
        if (e.toString().contains('404') || e.toString().contains('bad response')) {
          print('✅ UserStateService: 404 response - user not found in AWS, treating as first-time user');
          return UserStateResult(
            state: UserState.firstTime,
            message: 'Welcome to Foody! Let\'s set up your profile.',
          );
        }
        
        lastError = e is Exception ? e : Exception(e.toString());
        print('⚠️ UserStateService: AWS attempt $attempt failed: $e');
        
        // Only retry for actual network/server errors, not 404s
        if (attempt < _maxRetries && !e.toString().contains('404')) {
          await Future.delayed(_retryDelay * attempt); // Exponential backoff
        } else if (e.toString().contains('404')) {
          // Don't retry 404s - user simply doesn't exist
          break;
        }
      }
    }

    // If we get here and it wasn't a 404, it's a real network error
    if (lastError != null && lastError.toString().contains('404')) {
      return UserStateResult(
        state: UserState.firstTime,
        message: 'Welcome to Foody! Let\'s set up your profile.',
      );
    }

    return UserStateResult(
      state: UserState.networkError,
      error: lastError ?? Exception('Failed to connect to AWS after $_maxRetries attempts'),
    );
  }

  /// Parse AWS profile data into UserProfile entity
  UserProfile? _parseAWSProfile(Map<String, dynamic>? userData) {
    if (userData == null) return null;

    try {
      return UserProfile(
        gender: userData['gender'] ?? 'Male',
        age: userData['age'] ?? 25,
        weightKg: (userData['weight'] ?? 70.0).toDouble(),
        heightCm: (userData['height'] ?? 170.0).toDouble(),
        activityLevel: _parseActivityLevel(userData['activity_level']),
        weightGoal: _parseWeightGoal(userData['goal']),
        aiProvider: _parseAIProvider(userData['ai_provider']),
        isGuest: false, // AWS users are not guests
      );
    } catch (e) {
      print('⚠️ UserStateService: Error parsing AWS profile: $e');
      return null;
    }
  }

  /// Check if onboarding is complete based on AWS data
  bool _isOnboardingComplete(Map<String, dynamic>? userData) {
    if (userData == null) return false;
    
    // Check if all required fields are present and valid
    return userData['gender'] != null &&
           userData['age'] != null &&
           userData['weight'] != null &&
           userData['height'] != null &&
           userData['activity_level'] != null &&
           userData['goal'] != null;
  }

  /// Check if profile is complete (has all required data)
  bool _isProfileComplete(UserProfile? profile) {
    if (profile == null) return false;
    
    return profile.gender.isNotEmpty &&
           profile.age > 0 &&
           profile.weightKg > 0 &&
           profile.heightCm > 0;
  }

  /// Clear stale local data when AWS says user doesn't exist
  Future<void> _clearStaleLocalData() async {
    try {
      print('🧹 UserStateService: Clearing ALL stale local data');
      
      // Clear user profile from repository (this should clear the ViewModel cache too)
      await _userProfileRepository.clearProfile();
      print('✅ UserStateService: Cleared user profile from repository');
      
      // CRITICAL: Also clear the SQLite user profile directly to ensure complete cleanup
      await _sqliteService.clearUserProfile();
      print('✅ UserStateService: Cleared SQLite user profile directly');
      
      // Clear onboarding completion status
      await _sqliteService.setHasCompletedOnboarding(false);
      print('✅ UserStateService: Reset onboarding completion status');
      
      // Reset measurement unit to default
      await _sqliteService.setIsMetric(true);
      print('✅ UserStateService: Reset measurement unit to metric');
      
      print('✅ UserStateService: All stale local data cleared successfully');
    } catch (e) {
      print('⚠️ UserStateService: Error clearing stale local data: $e');
      // Don't throw - this is cleanup, not critical
    }
  }

  /// Sync AWS data to local storage
  Future<void> _syncAWSToLocal(UserProfile profile, bool onboardingComplete) async {
    try {
      await _userProfileRepository.saveProfile(profile, true); // Assume metric for now
      await _userProfileRepository.setHasCompletedOnboarding(onboardingComplete);
      print('✅ UserStateService: Synced AWS data to local storage');
    } catch (e) {
      print('⚠️ UserStateService: Error syncing AWS to local: $e');
    }
  }

  /// Parse activity level from string
  ActivityLevel _parseActivityLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'sedentary':
        return ActivityLevel.sedentary;
      case 'lightlyactive':
        return ActivityLevel.lightlyActive;
      case 'moderatelyactive':
        return ActivityLevel.moderatelyActive;
      case 'veryactive':
        return ActivityLevel.veryActive;
      case 'extraactive':
        return ActivityLevel.extraActive;
      default:
        return ActivityLevel.sedentary;
    }
  }

  /// Parse weight goal from string
  WeightGoal _parseWeightGoal(String? goal) {
    switch (goal?.toLowerCase()) {
      case 'lose':
        return WeightGoal.lose;
      case 'maintain':
        return WeightGoal.maintain;
      case 'gain':
        return WeightGoal.gain;
      default:
        return WeightGoal.maintain;
    }
  }

  /// Parse AI provider from string
  AIProvider _parseAIProvider(String? provider) {
    switch (provider?.toLowerCase()) {
      case 'openai':
        return AIProvider.openai;
      case 'gemini':
        return AIProvider.gemini;
      default:
        return AIProvider.openai;
    }
  }

  /// Force refresh user state (ignores cache)
  Future<UserStateResult> refreshUserState() async {
    return determineUserState(forceRefresh: true);
  }

  /// Check if user exists in AWS (lightweight check)
  Future<bool> userExistsInAWS(String userId) async {
    try {
      final profileData = await _awsService.getUserProfile(userId)
          .timeout(_awsTimeout);
      
      // Check the new response format
      if (profileData != null) {
        return profileData['success'] == true;
      }
      
      return false;
    } catch (e) {
      print('⚠️ UserStateService: Error checking user existence: $e');
      
      // If it's a 404, user doesn't exist (which is fine)
      if (e.toString().contains('404')) {
        return false;
      }
      
      // For other errors, assume user might exist (to be safe)
      return false;
    }
  }
}

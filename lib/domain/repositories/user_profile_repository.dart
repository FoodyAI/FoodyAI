import '../entities/user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile?> getProfile({String? userId});
  Future<void> saveProfile(UserProfile profile, bool isMetric,
      {required String userId});
  Future<void> clearProfile({String? userId});
  Future<bool> getIsMetric();
  Future<bool> getHasCompletedOnboarding();
  Future<void> setHasCompletedOnboarding(bool value);
}

import '../entities/user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile?> getProfile();
  Future<void> saveProfile(UserProfile profile, bool isMetric);
  Future<void> clearProfile();
  Future<bool> getIsMetric();
  Future<bool> getHasCompletedOnboarding();
  Future<void> setHasCompletedOnboarding(bool value);
}

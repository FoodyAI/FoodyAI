import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../services/sqlite_service.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final SQLiteService _sqliteService = SQLiteService();

  @override
  Future<UserProfile?> getProfile() async {
    return await _sqliteService.getUserProfile();
  }

  @override
  Future<void> saveProfile(UserProfile profile, bool isMetric) async {
    await _sqliteService.saveUserProfile(profile, isMetric);
    await _sqliteService.setIsMetric(isMetric);
  }

  @override
  Future<void> clearProfile() async {
    await _sqliteService.clearUserProfile();
  }

  @override
  Future<bool> getIsMetric() async {
    return await _sqliteService.getIsMetric();
  }

  @override
  Future<bool> getHasCompletedOnboarding() async {
    return await _sqliteService.getHasCompletedOnboarding();
  }

  @override
  Future<void> setHasCompletedOnboarding(bool value) async {
    await _sqliteService.setHasCompletedOnboarding(value);
  }
}

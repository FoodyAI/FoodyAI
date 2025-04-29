import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

class UserProfileUseCase {
  final UserProfileRepository _repository;

  UserProfileUseCase(this._repository);

  Future<UserProfile?> getProfile() => _repository.getProfile();

  Future<void> saveProfile(UserProfile profile, bool isMetric) =>
      _repository.saveProfile(profile, isMetric);

  Future<void> clearProfile() => _repository.clearProfile();

  Future<bool> getIsMetric() => _repository.getIsMetric();

  Future<bool> getHasCompletedOnboarding() =>
      _repository.getHasCompletedOnboarding();

  Future<void> setHasCompletedOnboarding(bool value) =>
      _repository.setHasCompletedOnboarding(value);
}

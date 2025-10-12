import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

class UserProfileUseCase {
  final UserProfileRepository _repository;

  UserProfileUseCase(this._repository);

  Future<UserProfile?> getProfile({String? userId}) =>
      _repository.getProfile(userId: userId);

  Future<void> saveProfile(UserProfile profile, bool isMetric,
          {required String userId}) =>
      _repository.saveProfile(profile, isMetric, userId: userId);

  Future<void> clearProfile({String? userId}) =>
      _repository.clearProfile(userId: userId);

  Future<bool> getIsMetric() => _repository.getIsMetric();

  Future<bool> getHasCompletedOnboarding() =>
      _repository.getHasCompletedOnboarding();

  Future<void> setHasCompletedOnboarding(bool value) =>
      _repository.setHasCompletedOnboarding(value);
}

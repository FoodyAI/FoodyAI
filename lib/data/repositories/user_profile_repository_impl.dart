import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<UserProfile?> getProfile() async {
    final prefs = await _preferences;
    if (prefs.containsKey('weightKg')) {
      final gender = prefs.getString('gender')!;
      final age = prefs.getInt('age')!;
      final weightKg = prefs.getDouble('weightKg')!;
      final heightCm = prefs.getDouble('heightCm')!;
      final activityLevelIndex = prefs.getInt('activityLevel')!;
      final activityLevel = ActivityLevel.values[activityLevelIndex];

      return UserProfile(
        gender: gender,
        age: age,
        weightKg: weightKg,
        heightCm: heightCm,
        activityLevel: activityLevel,
      );
    }
    return null;
  }

  @override
  Future<void> saveProfile(UserProfile profile, bool isMetric) async {
    final prefs = await _preferences;
    await Future.wait([
      prefs.setBool('isMetric', isMetric),
      prefs.setString('gender', profile.gender),
      prefs.setInt('age', profile.age),
      prefs.setDouble('weightKg', profile.weightKg),
      prefs.setDouble('heightCm', profile.heightCm),
      prefs.setInt('activityLevel', profile.activityLevel.index),
    ]);
  }

  @override
  Future<void> clearProfile() async {
    final prefs = await _preferences;
    await Future.wait([
      prefs.remove('isMetric'),
      prefs.remove('gender'),
      prefs.remove('age'),
      prefs.remove('weightKg'),
      prefs.remove('heightCm'),
      prefs.remove('activityLevel'),
      prefs.remove('hasCompletedOnboarding'),
    ]);
  }

  @override
  Future<bool> getIsMetric() async {
    final prefs = await _preferences;
    return prefs.getBool('isMetric') ?? true;
  }

  @override
  Future<bool> getHasCompletedOnboarding() async {
    final prefs = await _preferences;
    return prefs.getBool('hasCompletedOnboarding') ?? false;
  }

  @override
  Future<void> setHasCompletedOnboarding(bool value) async {
    final prefs = await _preferences;
    await prefs.setBool('hasCompletedOnboarding', value);
  }
}

import '../database/database_helper.dart';
import '../models/food_analysis.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/ai_provider.dart';

class SQLiteService {
  static final SQLiteService _instance = SQLiteService._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  SQLiteService._internal();

  factory SQLiteService() => _instance;

  // User Profile Operations
  Future<UserProfile?> getUserProfile({String? userId}) async {
    final profileData = userId != null
        ? await _dbHelper.getUserProfile(userId)
        : await _dbHelper.getFirstUserProfile();
    if (profileData == null) return null;

    return UserProfile(
      gender: profileData['gender'] as String,
      age: profileData['age'] as int,
      weightKg: profileData['weight_kg'] as double,
      heightCm: profileData['height_cm'] as double,
      activityLevel: ActivityLevel.values.firstWhere(
        (level) => level.name == profileData['activity_level'],
        orElse: () => ActivityLevel.moderatelyActive,
      ),
      weightGoal: WeightGoal.values.firstWhere(
        (goal) => goal.name == profileData['weight_goal'],
        orElse: () => WeightGoal.maintain,
      ),
      aiProvider: AIProvider.values.firstWhere(
        (provider) => provider.name == profileData['ai_provider'],
        orElse: () => AIProvider.openai,
      ),
    );
  }

  Future<void> saveUserProfile(UserProfile profile, bool isMetric,
      {required String userId}) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final profileData = {
      'user_id': userId,
      'gender': profile.gender,
      'age': profile.age,
      'weight_kg': profile.weightKg,
      'height_cm': profile.heightCm,
      'activity_level': profile.activityLevel.name,
      'weight_goal': profile.weightGoal.name,
      'ai_provider': profile.aiProvider.name,
      'measurement_unit': isMetric ? 'metric' : 'imperial',
      'bmi': profile.bmi,
      'daily_calories': profile.dailyCalories.round(),
      'created_at': now,
      'updated_at': now,
    };

    // Check if user exists
    final existingProfile = await _dbHelper.getUserProfile(userId);
    if (existingProfile != null) {
      await _dbHelper.updateUserProfile(userId, profileData);
    } else {
      await _dbHelper.insertUserProfile(profileData);
    }
  }

  Future<void> clearUserProfile({String? userId}) async {
    if (userId != null) {
      await _dbHelper.deleteUserProfile(userId);
    } else {
      // Clear all user profiles if no userId specified
      await _dbHelper.clearAllUserProfiles();
    }
  }

  Future<bool> getIsMetric() async {
    return await _dbHelper.getBoolAppSetting('is_metric', defaultValue: true);
  }

  Future<void> setIsMetric(bool isMetric) async {
    await _dbHelper.setAppSetting('is_metric', isMetric.toString());
  }

  Future<bool> getHasCompletedOnboarding() async {
    return await _dbHelper.getBoolAppSetting('has_completed_onboarding',
        defaultValue: false);
  }

  Future<void> setHasCompletedOnboarding(bool value) async {
    await _dbHelper.setAppSetting('has_completed_onboarding', value.toString());
  }

  // Food Analysis Operations
  Future<List<FoodAnalysis>> getFoodAnalyses({required String userId}) async {
    final analysesData = await _dbHelper.getFoods(userId);
    return analysesData.map((data) => FoodAnalysis.fromMap(data)).toList();
  }

  Future<List<FoodAnalysis>> getFoodAnalysesByDate(DateTime date,
      {required String userId}) async {
    final dateString = date.toIso8601String().split('T')[0];
    final analysesData = await _dbHelper.getFoodsByDate(userId, dateString);
    return analysesData.map((data) => FoodAnalysis.fromMap(data)).toList();
  }

  // Get only unsynced food analyses
  Future<List<FoodAnalysis>> getUnsyncedFoodAnalyses(
      {required String userId}) async {
    final analysesData = await _dbHelper.getUnsyncedFoods(userId);
    return analysesData.map((data) => FoodAnalysis.fromMap(data)).toList();
  }

  // Mark food analysis as synced
  Future<void> markFoodAnalysisAsSynced(String foodName, DateTime analysisDate,
      {required String userId}) async {
    await _dbHelper.markFoodAsSynced(
        userId, foodName, analysisDate.toIso8601String().split('T')[0]);
  }

  Future<void> saveFoodAnalyses(List<FoodAnalysis> analyses,
      {required String userId}) async {
    print(
        '🔄 SQLite: Saving ${analyses.length} food analyses for user $userId...');

    // Clear existing analyses for this user
    await _dbHelper.deleteAllFoods(userId);
    print('🗑️ SQLite: Cleared existing analyses for user $userId');

    // Insert new analyses
    for (final analysis in analyses) {
      final analysisMap = analysis.toMap();
      analysisMap['user_id'] = userId; // Set the correct user_id
      print(
          '📝 SQLite: Inserting analysis: ${analysis.name} (${analysis.calories} cal)');
      await _dbHelper.insertFood(analysisMap);
    }
    print('✅ SQLite: All analyses saved successfully');
  }

  Future<void> addFoodAnalysis(FoodAnalysis analysis,
      {required String userId}) async {
    print(
        '➕ SQLite: Adding single analysis: ${analysis.name} (${analysis.calories} cal)');
    final analysisMap = analysis.toMap();
    analysisMap['user_id'] = userId; // Set the correct user_id
    print('📝 SQLite: Analysis map: $analysisMap');
    await _dbHelper.insertFood(analysisMap);
    print('✅ SQLite: Single analysis added successfully');
  }

  Future<void> removeFoodAnalysis(String id) async {
    await _dbHelper.deleteFood(id);
  }

  // App Settings Operations
  Future<String?> getThemePreference() async {
    return await _dbHelper.getAppSetting('theme_preference');
  }

  Future<void> setThemePreference(String theme) async {
    await _dbHelper.setAppSetting('theme_preference', theme);
  }

  Future<bool> getGuestBannerDismissed() async {
    return await _dbHelper.getBoolAppSetting('guest_banner_dismissed',
        defaultValue: false);
  }

  Future<void> setGuestBannerDismissed(bool dismissed) async {
    await _dbHelper.setAppSetting(
        'guest_banner_dismissed', dismissed.toString());
  }

  Future<int?> getFirstUseDate() async {
    return await _dbHelper.getIntAppSetting('first_use_date');
  }

  Future<void> setFirstUseDate(int timestamp) async {
    await _dbHelper.setAppSetting('first_use_date', timestamp.toString());
  }

  Future<bool> getHasSubmittedRating() async {
    return await _dbHelper.getBoolAppSetting('has_submitted_rating',
        defaultValue: false);
  }

  Future<void> setHasSubmittedRating(bool submitted) async {
    await _dbHelper.setAppSetting('has_submitted_rating', submitted.toString());
  }

  Future<int?> getMaybeLaterTimestamp() async {
    return await _dbHelper.getIntAppSetting('maybe_later_timestamp');
  }

  Future<void> setMaybeLaterTimestamp(int timestamp) async {
    await _dbHelper.setAppSetting(
        'maybe_later_timestamp', timestamp.toString());
  }

  // Migration from SharedPreferences
  Future<void> migrateFromSharedPreferences() async {
    // This will be implemented to migrate existing SharedPreferences data
    // For now, we'll start fresh with SQLite
  }

  // App Settings Methods (for migration compatibility)
  Future<bool> getBoolAppSetting(String key,
      {bool defaultValue = false}) async {
    return await _dbHelper.getBoolAppSetting(key, defaultValue: defaultValue);
  }

  Future<void> setAppSetting(String key, String value) async {
    await _dbHelper.setAppSetting(key, value);
  }

  // Debug Methods
  Future<void> debugPrintFoodAnalyses({required String userId}) async {
    print(
        '🔍 SQLite Debug: Checking food analyses in database for user $userId...');
    final analyses = await getFoodAnalyses(userId: userId);
    print('📊 SQLite Debug: Found ${analyses.length} food analyses');

    for (int i = 0; i < analyses.length; i++) {
      final analysis = analyses[i];
      print('🍎 SQLite Debug: Analysis ${i + 1}:');
      print('   - Name: ${analysis.name}');
      print('   - Calories: ${analysis.calories}');
      print('   - Date: ${analysis.date}');
      print('   - Order: ${analysis.orderNumber}');
    }
  }

  // Utility Methods
  Future<void> clearAllData() async {
    await _dbHelper.clearAllData();
  }

  Future<void> close() async {
    await _dbHelper.close();
  }
}

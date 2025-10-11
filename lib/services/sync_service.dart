import 'package:firebase_auth/firebase_auth.dart';
import 'aws_service.dart';
import '../data/models/food_analysis.dart';
import '../data/services/sqlite_service.dart';

class SyncService {
  final AWSService _awsService = AWSService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SQLiteService _sqliteService = SQLiteService();

  // Sync user profile when signing in
  Future<void> syncUserProfileOnSignIn() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userId = user.uid;
      final email = user.email ?? '';
      final displayName = user.displayName;
      final photoUrl = user.photoURL;

      // Get local profile data from SQLite
      final profile = await _sqliteService.getUserProfile();
      if (profile == null) return;

      final gender = profile.gender;
      final age = profile.age;
      final weight = profile.weightKg;
      final height = profile.heightCm;
      final activityLevel = profile.activityLevel.name;
      final goal = profile.weightGoal.name;
      final dailyCalories = profile.dailyCalories.round();
      final bmi = profile.bmi;
      final themePreference =
          await _sqliteService.getThemePreference() ?? 'system';
      final aiProvider = profile.aiProvider.name;
      final measurementUnit =
          await _sqliteService.getIsMetric() ? 'metric' : 'imperial';

      // Save to AWS
      await _awsService.saveUserProfile(
        userId: userId,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        gender: gender,
        age: age,
        weight: weight,
        height: height,
        activityLevel: activityLevel,
        goal: goal,
        dailyCalories: dailyCalories,
        bmi: bmi,
        themePreference: themePreference,
        aiProvider: aiProvider,
        measurementUnit: measurementUnit,
      );

      print('User profile synced to AWS successfully');
    } catch (e) {
      print('Error syncing user profile: $e');
    }
  }

  // Note: Food analyses are now synced individually when added, not bulk synced on sign-in

  // Load user profile from AWS when signing in
  Future<void> loadUserProfileFromAWS() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userId = user.uid;
      final profileData = await _awsService.getUserProfile(userId);

      if (profileData != null && profileData['success'] == true) {
        final userData = profileData['user'];

        // Save to SQLite
        if (userData['gender'] != null) {
          await _sqliteService.setAppSetting('user_gender', userData['gender']);
        }
        if (userData['age'] != null) {
          await _sqliteService.setAppSetting(
              'user_age', userData['age'].toString());
        }
        if (userData['weight'] != null) {
          await _sqliteService.setAppSetting(
              'user_weight', userData['weight'].toString());
        }
        if (userData['height'] != null) {
          await _sqliteService.setAppSetting(
              'user_height', userData['height'].toString());
        }
        if (userData['activity_level'] != null) {
          await _sqliteService.setAppSetting(
              'user_activity_level', userData['activity_level']);
        }
        if (userData['goal'] != null) {
          await _sqliteService.setAppSetting('user_goal', userData['goal']);
        }
        if (userData['daily_calories'] != null) {
          await _sqliteService.setAppSetting(
              'user_daily_calories', userData['daily_calories'].toString());
        }
        if (userData['bmi'] != null) {
          await _sqliteService.setAppSetting(
              'user_bmi', userData['bmi'].toString());
        }
        if (userData['theme_preference'] != null) {
          await _sqliteService.setThemePreference(userData['theme_preference']);
        }
        if (userData['ai_provider'] != null) {
          await _sqliteService.setAppSetting(
              'user_ai_provider', userData['ai_provider']);
        }

        print('User profile loaded from AWS successfully');
      }
    } catch (e) {
      print('Error loading user profile from AWS: $e');
    }
  }

  // Save food analysis to AWS when user is signed in
  Future<void> saveFoodAnalysisToAWS(FoodAnalysis analysis) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ AWS: No authenticated user, skipping food analysis sync');
        return;
      }

      final userId = user.uid;
      print('🔄 AWS: Syncing food analysis to AWS for user: $userId');
      print(
          '📝 AWS: Analysis data - ${analysis.name} (${analysis.calories} cal)');

      await _awsService.saveFoodAnalysis(
        userId: userId,
        imageUrl: analysis.imagePath ?? '',
        foodName: analysis.name,
        calories: analysis.calories.toInt(),
        protein: analysis.protein,
        carbs: analysis.carbs,
        fat: analysis.fat,
        healthScore: analysis.healthScore.toInt(),
      );

      print('✅ AWS: Food analysis saved to AWS successfully');
    } catch (e) {
      print('❌ AWS: Error saving food analysis to AWS: $e');
    }
  }

  // Update user profile in AWS when user is signed in
  Future<void> updateUserProfileInAWS({
    String? gender,
    int? age,
    double? weight,
    double? height,
    String? activityLevel,
    String? goal,
    int? dailyCalories,
    double? bmi,
    String? themePreference,
    String? aiProvider,
    String? measurementUnit,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userId = user.uid;
      final email = user.email ?? '';
      final displayName = user.displayName;
      final photoUrl = user.photoURL;

      // Build request data with only provided fields
      final Map<String, dynamic> requestData = {
        'userId': userId,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
      };

      // Only add fields that are not null
      if (gender != null) requestData['gender'] = gender;
      if (age != null) requestData['age'] = age;
      if (weight != null) requestData['weight'] = weight;
      if (height != null) requestData['height'] = height;
      if (activityLevel != null) requestData['activityLevel'] = activityLevel;
      if (goal != null) requestData['goal'] = goal;
      if (dailyCalories != null) requestData['dailyCalories'] = dailyCalories;
      if (bmi != null) requestData['bmi'] = bmi;
      if (themePreference != null)
        requestData['themePreference'] = themePreference;
      if (aiProvider != null) requestData['aiProvider'] = aiProvider;
      if (measurementUnit != null)
        requestData['measurementUnit'] = measurementUnit;

      await _awsService.saveUserProfileWithData(requestData);

      print('User profile updated in AWS successfully');
    } catch (e) {
      print('Error updating user profile in AWS: $e');
    }
  }
}

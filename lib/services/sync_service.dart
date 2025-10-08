import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'aws_service.dart';
import '../data/models/food_analysis.dart';

class SyncService {
  final AWSService _awsService = AWSService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sync user profile when signing in
  Future<void> syncUserProfileOnSignIn() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userId = user.uid;
      final email = user.email ?? '';
      final displayName = user.displayName;
      final photoUrl = user.photoURL;

      // Get local profile data
      final prefs = await SharedPreferences.getInstance();
      final gender = prefs.getString('user_gender');
      final age = prefs.getInt('user_age');
      final weight = prefs.getDouble('user_weight');
      final height = prefs.getDouble('user_height');
      final activityLevel = prefs.getString('user_activity_level');
      final goal = prefs.getString('user_goal');
      final dailyCalories = prefs.getInt('user_daily_calories');
      final bmi = prefs.getDouble('user_bmi');
      final themePreference =
          prefs.getString('user_theme_preference') ?? 'system';
      final aiProvider = prefs.getString('user_ai_provider') ?? 'openai';
      final measurementUnit = prefs.getString('user_measurement_unit') ?? 'metric';

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

  // Sync food analyses when signing in
  Future<void> syncFoodAnalysesOnSignIn() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userId = user.uid;
      final prefs = await SharedPreferences.getInstance();

      // Get local food analyses
      final analysesJson = prefs.getString('food_analyses');
      if (analysesJson != null) {
        final List<dynamic> analysesList = jsonDecode(analysesJson);

        for (final analysisData in analysesList) {
          final analysis = FoodAnalysis.fromJson(analysisData);

          // Save to AWS
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
        }

        print('Food analyses synced to AWS successfully');
      }
    } catch (e) {
      print('Error syncing food analyses: $e');
    }
  }

  // Load user profile from AWS when signing in
  Future<void> loadUserProfileFromAWS() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userId = user.uid;
      final profileData = await _awsService.getUserProfile(userId);

      if (profileData != null && profileData['success'] == true) {
        final user = profileData['user'];
        final prefs = await SharedPreferences.getInstance();

        // Save to local storage
        if (user['gender'] != null) {
          prefs.setString('user_gender', user['gender']);
        }
        if (user['age'] != null) prefs.setInt('user_age', user['age']);
        if (user['weight'] != null) {
          prefs.setDouble('user_weight', user['weight']);
        }
        if (user['height'] != null) {
          prefs.setDouble('user_height', user['height']);
        }
        if (user['activity_level'] != null) {
          prefs.setString('user_activity_level', user['activity_level']);
        }
        if (user['goal'] != null) prefs.setString('user_goal', user['goal']);
        if (user['daily_calories'] != null) {
          prefs.setInt('user_daily_calories', user['daily_calories']);
        }
        if (user['bmi'] != null) prefs.setDouble('user_bmi', user['bmi']);
        if (user['theme_preference'] != null) {
          prefs.setString('user_theme_preference', user['theme_preference']);
        }
        if (user['ai_provider'] != null) {
          prefs.setString('user_ai_provider', user['ai_provider']);
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
      if (user == null) return;

      final userId = user.uid;

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

      print('Food analysis saved to AWS successfully');
    } catch (e) {
      print('Error saving food analysis to AWS: $e');
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
      if (themePreference != null) requestData['themePreference'] = themePreference;
      if (aiProvider != null) requestData['aiProvider'] = aiProvider;
      if (measurementUnit != null) requestData['measurementUnit'] = measurementUnit;

      await _awsService.saveUserProfileWithData(requestData);

      print('User profile updated in AWS successfully');
    } catch (e) {
      print('Error updating user profile in AWS: $e');
    }
  }
}

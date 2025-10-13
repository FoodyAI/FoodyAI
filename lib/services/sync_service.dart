import 'package:firebase_auth/firebase_auth.dart';
import 'aws_service.dart';
import '../data/models/food_analysis.dart';
import '../data/services/sqlite_service.dart';
import '../domain/entities/user_profile.dart';
import '../domain/entities/ai_provider.dart';

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
      final profile = await _sqliteService.getUserProfile(userId: userId);
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

  // Sync food analyses when signing in
  Future<void> syncFoodAnalysesOnSignIn() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userId = user.uid;

      // Get ONLY unsynced food analyses from SQLite
      final unsyncedAnalyses =
          await _sqliteService.getUnsyncedFoodAnalyses(userId: userId);

      if (unsyncedAnalyses.isEmpty) {
        print('📋 AWS: No unsynced food analyses to sync');
        return;
      }

      print(
          '🔄 AWS: Found ${unsyncedAnalyses.length} unsynced food analyses to sync');

      for (final analysis in unsyncedAnalyses) {
        try {
          // Save to AWS
          final result = await _awsService.saveFoodAnalysis(
            userId: userId,
            imageUrl: analysis.imagePath ?? '',
            foodName: analysis.name,
            calories: analysis.calories.toInt(),
            protein: analysis.protein,
            carbs: analysis.carbs,
            fat: analysis.fat,
            healthScore: analysis.healthScore.toInt(),
            foodId: analysis.id ?? '',
            analysisDate: analysis.date
                .toIso8601String()
                .split('T')[0], // Format: YYYY-MM-DD
          );

          // If successful, mark as synced
          if (result != null) {
            await _sqliteService.markFoodAnalysisAsSynced(
                analysis.name, analysis.date,
                userId: userId);
            print('✅ AWS: Synced and marked: ${analysis.name}');
          } else {
            print('❌ AWS: Failed to sync: ${analysis.name}');
          }
        } catch (e) {
          print('❌ AWS: Error syncing ${analysis.name}: $e');
        }
      }

      print('✅ AWS: Food analyses sync completed');
    } catch (e) {
      print('❌ AWS: Error syncing food analyses: $e');
    }
  }

  // Load ALL user data from AWS when signing in (profile + food analyses)
  Future<void> loadUserDataFromAWS() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ AWS: No authenticated user');
        return;
      }

      final userId = user.uid;
      print('📥 AWS: Loading user data for user: $userId');

      // Step 1: Load user profile from AWS
      final profileData = await _awsService.getUserProfile(userId);

      // If user doesn't exist in AWS (deleted account), clear local data and return
      if (profileData == null || profileData['success'] == false) {
        print('ℹ️ AWS: User not found in AWS - clearing local data');
        await _sqliteService.clearAllData();
        return;
      }

      if (profileData['success'] == true) {
        final userData = profileData['user'];
        print('✅ AWS: User profile found in AWS');
        print('📋 AWS: Full user data received:');
        print('   - user_id: ${userData['user_id']}');
        print('   - email: ${userData['email']}');
        print('   - gender: ${userData['gender']}');
        print('   - age: ${userData['age']}');
        print('   - weight: ${userData['weight']}');
        print('   - height: ${userData['height']}');
        print('   - activity_level: ${userData['activity_level']}');
        print('   - goal: ${userData['goal']}');
        print('   - ai_provider: ${userData['ai_provider']}');
        print('   - measurement_unit: ${userData['measurement_unit']}');
        print('   - theme_preference: ${userData['theme_preference']}');

        // Save profile to SQLite
        if (userData['gender'] != null &&
            userData['age'] != null &&
            userData['weight'] != null &&
            userData['height'] != null &&
            userData['activity_level'] != null &&
            userData['goal'] != null) {
          // Construct UserProfile object
          // PostgreSQL returns numbers as strings, so we need to parse them
          final age = userData['age'] is String
              ? int.parse(userData['age'])
              : userData['age'] as int;
          final weight = userData['weight'] is String
              ? double.parse(userData['weight'])
              : (userData['weight'] as num).toDouble();
          final height = userData['height'] is String
              ? double.parse(userData['height'])
              : (userData['height'] as num).toDouble();

          final profile = UserProfile(
            gender: userData['gender'],
            age: age,
            weightKg: weight,
            heightCm: height,
            activityLevel: ActivityLevel.values.firstWhere(
              (level) => level.name == userData['activity_level'],
              orElse: () => ActivityLevel.moderatelyActive,
            ),
            weightGoal: WeightGoal.values.firstWhere(
              (goal) => goal.name == userData['goal'],
              orElse: () => WeightGoal.maintain,
            ),
            aiProvider: AIProvider.values.firstWhere(
              (provider) =>
                  provider.name == (userData['ai_provider'] ?? 'openai'),
              orElse: () => AIProvider.openai,
            ),
          );

          final isMetric =
              (userData['measurement_unit'] ?? 'metric') == 'metric';

          print(
              '💾 SyncService: About to save profile to SQLite with userId: $userId');
          await _sqliteService.saveUserProfile(profile, isMetric,
              userId: userId);
          print('✅ SyncService: saveUserProfile completed');

          // Mark onboarding as complete since user has a complete profile in AWS
          await _sqliteService.setHasCompletedOnboarding(true);
          print('✅ SyncService: Set onboarding complete = true');

          // Verify it was saved by reading it back
          final verifyProfile =
              await _sqliteService.getUserProfile(userId: userId);
          if (verifyProfile != null) {
            print('✅ AWS: User profile VERIFIED in local SQLite');
            print(
                '   - Gender: ${verifyProfile.gender}, Age: ${verifyProfile.age}');
            print(
                '   - Weight: ${verifyProfile.weightKg}kg, Height: ${verifyProfile.heightCm}cm');
            print(
                '   - Activity: ${verifyProfile.activityLevel.name}, Goal: ${verifyProfile.weightGoal.name}');
            print('   - AI Provider: ${verifyProfile.aiProvider.name}');
            print('   - Measurement Unit: ${isMetric ? "metric" : "imperial"}');
          } else {
            print('❌ AWS: FAILED to verify profile in local SQLite!');
          }

          if (userData['theme_preference'] != null) {
            await _sqliteService
                .setThemePreference(userData['theme_preference']);
            print('   - Theme: ${userData['theme_preference']}');
          }
        }
      } else {
        print('❌ AWS: Failed to load user profile from AWS');
        return;
      }

      // Step 2: Load food analyses from AWS
      print('📥 AWS: Fetching food analyses from AWS...');
      print('🔍 AWS: Using userId: $userId');
      final foodsData = await _awsService.getFoodAnalyses(userId);

      if (foodsData.isNotEmpty) {
        print('✅ AWS: Found ${foodsData.length} food analyses');

        // Convert AWS data to FoodAnalysis objects
        final foodAnalyses = foodsData.map((foodData) {
          // PostgreSQL returns numbers as strings, so we need to parse them
          final protein = foodData['protein'] is String
              ? double.parse(foodData['protein'])
              : (foodData['protein'] as num).toDouble();
          final carbs = foodData['carbs'] is String
              ? double.parse(foodData['carbs'])
              : (foodData['carbs'] as num).toDouble();
          final fat = foodData['fat'] is String
              ? double.parse(foodData['fat'])
              : (foodData['fat'] as num).toDouble();
          final calories = foodData['calories'] is String
              ? double.parse(foodData['calories'])
              : (foodData['calories'] as num).toDouble();
          final healthScore = foodData['health_score'] is num
              ? (foodData['health_score'] as num).toDouble()
              : double.parse(foodData['health_score'].toString());

          return FoodAnalysis(
            id: foodData['id'] as String,
            name: foodData['food_name'] as String,
            protein: protein,
            carbs: carbs,
            fat: fat,
            calories: calories,
            healthScore: healthScore,
            imagePath: foodData['image_url'] as String?,
            date: DateTime.parse(foodData['analysis_date'] as String),
            syncedToAws: true, // Already in AWS
          );
        }).toList();

        // Save all food analyses to local SQLite
        await _sqliteService.saveFoodAnalyses(foodAnalyses, userId: userId);
        print(
            '✅ AWS: Saved ${foodAnalyses.length} food analyses to local SQLite');

        // Log each food item
        for (var food in foodAnalyses) {
          print(
              '   - ${food.name}: ${food.calories.toInt()} cal, Score: ${food.healthScore.toInt()}/10');
        }
      } else {
        print('ℹ️ AWS: No food analyses found for user');
      }

      print('✅ AWS: User data loaded successfully');
    } catch (e) {
      print('❌ AWS: Error loading user data from AWS: $e');
    }
  }

  // Legacy method - kept for backward compatibility
  Future<void> loadUserProfileFromAWS() async {
    await loadUserDataFromAWS();
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

      if (analysis.id == null) {
        print('❌ AWS: No food ID available for sync');
        return;
      }

      final result = await _awsService.saveFoodAnalysis(
        userId: userId,
        imageUrl: analysis.imagePath ?? '',
        foodName: analysis.name,
        calories: analysis.calories.toInt(),
        protein: analysis.protein,
        carbs: analysis.carbs,
        fat: analysis.fat,
        healthScore: analysis.healthScore.toInt(),
        foodId: analysis.id!,
        analysisDate:
            analysis.date.toIso8601String().split('T')[0], // Format: YYYY-MM-DD
      );

      if (result != null) {
        // Mark as synced in local database
        await _sqliteService.markFoodAnalysisAsSynced(
            analysis.name, analysis.date,
            userId: userId);
        print('✅ AWS: Food analysis saved to AWS successfully');
        print('✅ AWS: Marked as synced in local database');
        print('✅ AWS: Server response: $result');
      } else {
        print('❌ AWS: Failed to save food analysis - null response');
      }
    } catch (e) {
      print('❌ AWS: Error saving food analysis to AWS: $e');
    }
  }

  // Delete food analysis from AWS when user is signed in
  Future<void> deleteFoodAnalysisFromAWS(FoodAnalysis analysis) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ AWS: No authenticated user, skipping food analysis deletion');
        return;
      }

      final userId = user.uid;
      print('🗑️ AWS: Deleting food analysis from AWS for user: $userId');
      print('📝 AWS: Analysis data - ${analysis.name} (ID: ${analysis.id})');

      if (analysis.id == null) {
        print('❌ AWS: No food ID available for deletion');
        return;
      }

      final result = await _awsService.deleteFoodAnalysis(
        userId: userId,
        foodId: analysis.id!,
      );

      if (result != null) {
        print('✅ AWS: Food analysis deleted from AWS successfully');
        print('✅ AWS: Server response: $result');
      } else {
        print('❌ AWS: Failed to delete food analysis - null response');
      }
    } catch (e) {
      print('❌ AWS: Error deleting food analysis from AWS: $e');
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
      if (themePreference != null) {
        requestData['themePreference'] = themePreference;
      }
      if (aiProvider != null) requestData['aiProvider'] = aiProvider;
      if (measurementUnit != null) {
        requestData['measurementUnit'] = measurementUnit;
      }

      await _awsService.saveUserProfileWithData(requestData);

      print('User profile updated in AWS successfully');
    } catch (e) {
      print('Error updating user profile in AWS: $e');
    }
  }
}

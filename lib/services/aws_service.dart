import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AWSService {
  static const String _baseUrl = 'https://xpdvcgcji6.execute-api.us-east-1.amazonaws.com/prod';
  final Dio _dio = Dio();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AWSService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  // Get Firebase ID token for authentication
  Future<String?> _getIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }

  // Create or update user profile
  Future<Map<String, dynamic>?> saveUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
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
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.post(
        '/users',
        data: {
          'userId': userId,
          'email': email,
          'displayName': displayName,
          'photoUrl': photoUrl,
          'gender': gender,
          'age': age,
          'weight': weight,
          'height': height,
          'activityLevel': activityLevel,
          'goal': goal,
          'dailyCalories': dailyCalories,
          'bmi': bmi,
          'themePreference': themePreference,
          'aiProvider': aiProvider,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to save user profile: ${response.statusMessage}');
      }
    } catch (e) {
      print('Error saving user profile: $e');
      return null;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.get(
        '/users/$userId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get user profile: ${response.statusMessage}');
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Save food analysis result
  Future<Map<String, dynamic>?> saveFoodAnalysis({
    required String userId,
    required String imageUrl,
    required String foodName,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required int healthScore,
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.post(
        '/food-analysis',
        data: {
          'userId': userId,
          'imageUrl': imageUrl,
          'foodName': foodName,
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
          'healthScore': healthScore,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to save food analysis: ${response.statusMessage}');
      }
    } catch (e) {
      print('Error saving food analysis: $e');
      return null;
    }
  }

  // Upload image to S3 (placeholder - would need S3 SDK)
  Future<String?> uploadImageToS3(File imageFile) async {
    // This would require AWS S3 SDK for Flutter
    // For now, return a placeholder URL
    // In production, you'd implement S3 upload here
    return 'https://foody-images-1759858489.s3.amazonaws.com/placeholder.jpg';
  }

  // Sync local data with AWS when user signs in
  Future<void> syncLocalDataWithAWS(String userId) async {
    try {
      // Get local data from SharedPreferences
      // This would be implemented based on your local storage
      print('Syncing local data with AWS for user: $userId');
      
      // Example: Sync user profile
      // final localProfile = await getLocalUserProfile();
      // if (localProfile != null) {
      //   await saveUserProfile(userId: userId, ...);
      // }
      
      // Example: Sync food analyses
      // final localAnalyses = await getLocalFoodAnalyses();
      // for (final analysis in localAnalyses) {
      //   await saveFoodAnalysis(userId: userId, ...);
      // }
      
    } catch (e) {
      print('Error syncing local data with AWS: $e');
    }
  }
}

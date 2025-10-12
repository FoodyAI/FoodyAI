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
    String? measurementUnit,
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
              'measurementUnit': measurementUnit,
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
          validateStatus: (status) {
            // Accept both 200 (user exists) and 404 (user doesn't exist) as valid responses
            return status != null && (status == 200 || status == 404);
          },
        ),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': response.data,
        };
      } else if (response.statusCode == 404) {
        // User doesn't exist - this is a valid scenario for first-time users
        print('ℹ️ AWS Service: User profile not found (404) - first-time user');
        return {
          'success': false,
          'message': 'User not found',
        };
      } else {
        throw Exception('Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting user profile: $e');
      
      // Check if this is a DioException with 404 status
      if (e.toString().contains('404')) {
        print('ℹ️ AWS Service: Caught 404 exception - treating as first-time user');
        return {
          'success': false,
          'message': 'User not found',
        };
      }
      
      // For other errors, return null to indicate a real error
      return null;
    }
  }

  // Save user profile with custom data
  Future<Map<String, dynamic>?> saveUserProfileWithData(Map<String, dynamic> data) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.post(
        '/users',
        data: data,
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
    required String foodId,
  }) async {
    try {
      print('🔄 AWS Service: Starting food analysis save...');
      print('📝 AWS Service: User ID: $userId');
      print('📝 AWS Service: Food: $foodName ($calories cal)');
      
      final idToken = await _getIdToken();
      if (idToken == null) {
        print('❌ AWS Service: No ID token available');
        throw Exception('User not authenticated');
      }

      final requestData = {
        'userId': userId,
        'imageUrl': imageUrl,
        'foodName': foodName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'healthScore': healthScore,
        'foodId': foodId,
      };
      
      print('📤 AWS Service: Sending request to /food-analysis');
      print('📤 AWS Service: Request data: $requestData');

      final response = await _dio.post(
        '/food-analysis',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('📥 AWS Service: Response status: ${response.statusCode}');
      print('📥 AWS Service: Response data: ${response.data}');

      if (response.statusCode == 200) {
        print('✅ AWS Service: Food analysis saved successfully');
        return response.data;
      } else {
        print('❌ AWS Service: Failed to save food analysis: ${response.statusMessage}');
        throw Exception('Failed to save food analysis: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ AWS Service: Error saving food analysis: $e');
      return null;
    }
  }

  // Delete food analysis from AWS
  Future<Map<String, dynamic>?> deleteFoodAnalysis({
    required String userId,
    required String foodId,
  }) async {
    try {
      print('🗑️ AWS Service: Starting food analysis deletion...');
      print('📝 AWS Service: User ID: $userId');
      print('📝 AWS Service: Food ID: $foodId');
      
      final idToken = await _getIdToken();
      if (idToken == null) {
        print('❌ AWS Service: No ID token available');
        throw Exception('User not authenticated');
      }

      final response = await _dio.delete(
        '/food-analysis',
        data: {
          'userId': userId,
          'foodId': foodId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('📥 AWS Service: Delete response status: ${response.statusCode}');
      print('📥 AWS Service: Delete response data: ${response.data}');

      if (response.statusCode == 200) {
        print('✅ AWS Service: Food analysis deleted successfully');
        return response.data;
      } else {
        print('❌ AWS Service: Failed to delete with status ${response.statusCode}');
        print('❌ AWS Service: Error: ${response.statusMessage}');
        throw Exception('Failed to delete food analysis: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ AWS Service: Exception occurred during deletion: $e');
      return null;
    }
  }

  // Delete user account and all associated data
  Future<Map<String, dynamic>?> deleteUser(String userId) async {
    try {
      print('🗑️ AWS Service: Starting user deletion...');
      print('📝 AWS Service: User ID: $userId');
      
      final idToken = await _getIdToken();
      if (idToken == null) {
        print('❌ AWS Service: No ID token available');
        throw Exception('User not authenticated');
      }

      final response = await _dio.delete(
        '/users/$userId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('📥 AWS Service: Delete user response status: ${response.statusCode}');
      print('📥 AWS Service: Delete user response data: ${response.data}');

      if (response.statusCode == 200) {
        print('✅ AWS Service: User deleted successfully');
        return response.data;
      } else {
        print('❌ AWS Service: Failed to delete user with status ${response.statusCode}');
        print('❌ AWS Service: Error: ${response.statusMessage}');
        throw Exception('Failed to delete user: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ AWS Service: Exception occurred during user deletion: $e');
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

import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AWSService {
  static const String _baseUrl =
      'https://xpdvcgcji6.execute-api.us-east-1.amazonaws.com/prod';
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
        throw Exception(
            'Failed to save user profile: ${response.statusMessage}');
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
        // AWS returns {"success": true, "user": {...}}
        // So response.data already has both 'success' and 'user'
        return response.data;
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
      // Inspect the response directly rather than string-matching the message:
      // '404' also appears in exception text for unrelated reasons (a userId
      // containing it, a timeout after 404ms), which would silently turn a
      // real failure into a "first-time user" and wipe the caller's data.
      if (e is DioException && e.response?.statusCode == 404) {
        print(
            'ℹ️ AWS Service: User profile not found (404) - first-time user');
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      print('Error getting user profile: $e');

      // For other errors, return null to indicate a real error
      return null;
    }
  }

  // Save user profile with custom data
  Future<Map<String, dynamic>?> saveUserProfileWithData(
      Map<String, dynamic> data) async {
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
        throw Exception(
            'Failed to save user profile: ${response.statusMessage}');
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
    required String analysisDate, // Format: YYYY-MM-DD
  }) async {
    try {
      print('🔄 AWS Service: Starting food analysis save...');
      print('📝 AWS Service: User ID: $userId');
      print('📝 AWS Service: Food: $foodName ($calories cal)');
      print('📝 AWS Service: Analysis Date: $analysisDate');

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
        'analysisDate': analysisDate,
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
        print(
            '❌ AWS Service: Failed to save food analysis: ${response.statusMessage}');
        throw Exception(
            'Failed to save food analysis: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ AWS Service: Error saving food analysis: $e');
      return null;
    }
  }

  // Get all food analyses for a user
  Future<List<Map<String, dynamic>>> getFoodAnalyses(String userId) async {
    try {
      print('📥 AWS Service: Fetching food analyses for user: $userId');

      final idToken = await _getIdToken();
      if (idToken == null) {
        print('❌ AWS Service: No ID token available');
        throw Exception('User not authenticated');
      }

      final response = await _dio.get(
        '/food-analysis/$userId',
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
        print('✅ AWS Service: Food analyses fetched successfully');
        final data = response.data;
        print('📥 AWS Service: data[success] = ${data['success']}');
        print('📥 AWS Service: data[foods] = ${data['foods']}');
        print('📥 AWS Service: food count = ${data['count']}');
        if (data['success'] == true && data['foods'] != null) {
          final foods = List<Map<String, dynamic>>.from(data['foods']);
          print('✅ AWS Service: Returning ${foods.length} foods');
          return foods;
        }
        print('⚠️ AWS Service: No foods found in response');
        return [];
      } else {
        print(
            '❌ AWS Service: Failed to fetch food analyses: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      print('❌ AWS Service: Error fetching food analyses: $e');
      return [];
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
        print(
            '❌ AWS Service: Failed to delete with status ${response.statusCode}');
        print('❌ AWS Service: Error: ${response.statusMessage}');
        throw Exception(
            'Failed to delete food analysis: ${response.statusMessage}');
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

      print(
          '📥 AWS Service: Delete user response status: ${response.statusCode}');
      print('📥 AWS Service: Delete user response data: ${response.data}');

      if (response.statusCode == 200) {
        print('✅ AWS Service: User deleted successfully');
        return response.data;
      } else {
        print(
            '❌ AWS Service: Failed to delete user with status ${response.statusCode}');
        print('❌ AWS Service: Error: ${response.statusMessage}');
        throw Exception('Failed to delete user: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ AWS Service: Exception occurred during user deletion: $e');
      return null;
    }
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

  /// Upload image to S3 via the image-upload Lambda function
  /// Returns the S3 URL if successful, null otherwise
  Future<String?> uploadImageToS3(File imageFile) async {
    try {
      print('🔄 AWS Service: Starting S3 image upload...');
      print('📝 AWS Service: Image file: ${imageFile.path}');

      final idToken = await _getIdToken();
      if (idToken == null) {
        print('❌ AWS Service: No ID token available');
        throw Exception('User not authenticated');
      }

      // Read image file and convert to base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Get file extension and determine content type
      final fileName = imageFile.path.split('/').last;
      final contentType = _getContentType(fileName);

      final requestData = {
        'imageData': base64Image,
        'fileName': fileName,
        'contentType': contentType,
      };

      print('📤 AWS Service: Sending request to /image-upload');
      print('📤 AWS Service: File size: ${imageBytes.length} bytes');
      print('📤 AWS Service: Content type: $contentType');

      final response = await _dio.post(
        '/image-upload',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      print(
          '📥 AWS Service: S3 upload response status: ${response.statusCode}');
      print('📥 AWS Service: S3 upload response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['s3Url'] != null) {
          print('✅ AWS Service: Image uploaded to S3 successfully');
          print('📝 AWS Service: S3 URL: ${data['s3Url']}');
          return data['s3Url'] as String;
        } else {
          print('❌ AWS Service: S3 upload failed: ${data['error']}');
          return null;
        }
      } else {
        print(
            '❌ AWS Service: Failed to upload to S3: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      print('❌ AWS Service: Error uploading to S3: $e');
      return null;
    }
  }

  /// Determine content type based on file extension
  String _getContentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default to JPEG
    }
  }

  /// Update FCM token for push notifications
  Future<Map<String, dynamic>?> updateFCMToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      print('🔄 AWS Service: Updating FCM token...');
      print('📝 AWS Service: User ID: $userId');

      final idToken = await _getIdToken();
      if (idToken == null) {
        print('❌ AWS Service: No ID token available');
        throw Exception('User not authenticated');
      }

      // Get current user's email (required by backend)
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        print('❌ AWS Service: No user email available');
        throw Exception('User email not found');
      }

      final response = await _dio.post(
        '/users',
        data: {
          'userId': userId,
          'email': user.email,
          'fcmToken': fcmToken,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      print(
          '📥 AWS Service: FCM token update response status: ${response.statusCode}');
      print('📥 AWS Service: FCM token update response data: ${response.data}');

      if (response.statusCode == 200) {
        print('✅ AWS Service: FCM token updated successfully');
        return response.data;
      } else {
        print(
            '❌ AWS Service: Failed to update FCM token: ${response.statusMessage}');
        throw Exception(
            'Failed to update FCM token: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ AWS Service: Error updating FCM token: $e');
      return null;
    }
  }

  /// Update notification preferences
  Future<Map<String, dynamic>?> updateNotificationPreferences({
    required String userId,
    required bool notificationsEnabled,
  }) async {
    try {
      print('🔄 AWS Service: Updating notification preferences...');
      print('📝 AWS Service: User ID: $userId');
      print('📝 AWS Service: Notifications enabled: $notificationsEnabled');

      final idToken = await _getIdToken();
      if (idToken == null) {
        print('❌ AWS Service: No ID token available');
        throw Exception('User not authenticated');
      }

      // Get current user's email (required by backend)
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        print('❌ AWS Service: No user email available');
        throw Exception('User email not found');
      }

      final response = await _dio.post(
        '/users',
        data: {
          'userId': userId,
          'email': user.email,
          'notificationsEnabled': notificationsEnabled,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      print(
          '📥 AWS Service: Notification preferences update response status: ${response.statusCode}');
      print(
          '📥 AWS Service: Notification preferences update response data: ${response.data}');

      if (response.statusCode == 200) {
        print('✅ AWS Service: Notification preferences updated successfully');
        return response.data;
      } else {
        print(
            '❌ AWS Service: Failed to update notification preferences: ${response.statusMessage}');
        throw Exception(
            'Failed to update notification preferences: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ AWS Service: Error updating notification preferences: $e');
      return null;
    }
  }
}

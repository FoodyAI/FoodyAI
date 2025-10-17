import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/food_analysis.dart';
import '../../data/datasources/remote/ai_service.dart';
import '../../data/datasources/remote/ai_service_factory.dart';
import '../../data/datasources/local/food_analysis_storage.dart';
import '../../data/services/sqlite_service.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../di/service_locator.dart';
import '../../services/sync_service.dart';
import '../../services/aws_service.dart';
import '../../services/permission_service.dart';
import '../../core/events/food_data_update_event.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/rating_dialog.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ImageAnalysisViewModel extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final FoodAnalysisStorage _storage = FoodAnalysisStorage();
  final SQLiteService _sqliteService = SQLiteService();
  final UserProfileRepository _profileRepository =
      getIt<UserProfileRepository>();
  final SyncService _syncService = SyncService();
  final AWSService _awsService = AWSService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  File? _selectedImage;
  FoodAnalysis? _currentAnalysis;
  bool _isLoading = false;
  String? _error;
  List<FoodAnalysis> _savedAnalyses = [];
  DateTime? _firstUseDate;
  DateTime _selectedDate = DateTime.now();

  File? get selectedImage => _selectedImage;
  FoodAnalysis? get currentAnalysis => _currentAnalysis;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;
  List<FoodAnalysis> get savedAnalyses => List.unmodifiable(_savedAnalyses);
  List<FoodAnalysis> get filteredAnalyses => _savedAnalyses.where((analysis) {
        return analysis.date.year == _selectedDate.year &&
            analysis.date.month == _selectedDate.month &&
            analysis.date.day == _selectedDate.day;
      }).toList();

  ImageAnalysisViewModel() {
    _loadSavedAnalyses();
    _initializeFirstUseDate();

    // Listen to auth state changes to clear data when user signs out
    // Note: We don't reload on sign-in here because AuthViewModel handles that
    // with proper timing after AWS data is loaded
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        // User signed out - clear local data
        _savedAnalyses.clear();
        notifyListeners();
      }
    });

    // Listen to food data update events to refresh the UI
    FoodDataUpdateEvent.stream.listen((_) {
      print(
          '📢 ImageAnalysisViewModel: Food data update event received, reloading...');
      _loadSavedAnalyses();
    });
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> _initializeFirstUseDate() async {
    final firstUseTimestamp = await _sqliteService.getFirstUseDate();
    if (firstUseTimestamp == null) {
      _firstUseDate = DateTime.now();
      await _sqliteService
          .setFirstUseDate(_firstUseDate!.millisecondsSinceEpoch);
    } else {
      _firstUseDate = DateTime.fromMillisecondsSinceEpoch(firstUseTimestamp);
    }
  }

  Future<void> _loadSavedAnalyses() async {
    _savedAnalyses = await _storage.loadAnalyses();
    // Sort by createdAt in descending order (latest first)
    _savedAnalyses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  // Public method to reload analyses (called after AWS sync)
  Future<void> reloadAnalyses() async {
    print(
        '🔄 ImageAnalysisViewModel: Manually reloading analyses after AWS sync...');

    try {
      await _loadSavedAnalyses();
      print(
          '✅ ImageAnalysisViewModel: Analyses reloaded, count: ${_savedAnalyses.length}');
    } catch (e) {
      print('❌ ImageAnalysisViewModel: Failed to reload analyses: $e');
      // If reload fails, try again after a short delay
      Future.delayed(const Duration(milliseconds: 1000), () async {
        try {
          await _loadSavedAnalyses();
          print(
              '✅ ImageAnalysisViewModel: Retry successful, count: ${_savedAnalyses.length}');
        } catch (retryError) {
          print('❌ ImageAnalysisViewModel: Retry also failed: $retryError');
        }
      });
    }
  }

  Future<void> _checkAndShowRating() async {
    final hasSubmittedRating = await _sqliteService.getHasSubmittedRating();
    final maybeLaterTimestamp = await _sqliteService.getMaybeLaterTimestamp();

    if (hasSubmittedRating) return;

    // Check if user has added at least 3 foods
    if (_savedAnalyses.length < 3) return;

    // If user clicked "Maybe Later", check if 2 days have passed
    if (maybeLaterTimestamp != null) {
      final daysSinceMaybeLater = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(maybeLaterTimestamp))
          .inDays;
      if (daysSinceMaybeLater < 2) return;
    }

    // Show rating dialog
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const RatingDialog(),
      );
    }
  }

  /// Show snackbar with message (same style as sign out success)
  void _showSnackBar(
      BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> pickImage(ImageSource source, BuildContext context) async {
    try {
      // Check camera permission if using camera
      if (source == ImageSource.camera) {
        // Always try to request permission - this handles all cases:
        // 1. First time request
        // 2. Permission already granted
        // 3. User changed from "Don't Allow" to "Ask Every Time"
        final permissionGranted =
            await PermissionService.requestCameraPermission(context);
        if (!permissionGranted) {
          return; // Permission denied, error message already shown
        }
      }

      final XFile? img = await _picker.pickImage(source: source);
      if (img != null) {
        _selectedImage = File(img.path);
        _currentAnalysis = null;
        _error = null;
        notifyListeners();
        await analyzeImage();
      } else {
        // User cancelled image picker
        _showSnackBar(
            context, 'Image selection cancelled', AppColors.textSecondary);
      }
    } catch (e) {
      // Handle different types of errors
      String errorMessage;
      if (e.toString().contains('camera_access_denied') ||
          e.toString().contains('permission')) {
        errorMessage =
            'Camera access denied. Please check permissions in settings.';
      } else if (e.toString().contains('camera_access_denied_without_prompt')) {
        errorMessage =
            'Camera permission is permanently denied. Please enable it in settings.';
      } else if (e.toString().contains('camera_access_restricted')) {
        errorMessage = 'Camera access is restricted on this device.';
      } else {
        errorMessage = 'Failed to pick image. Please try again.';
      }

      _showSnackBar(context, errorMessage, AppColors.error);
      _error = null; // Clear error state since we're showing snackbar
      notifyListeners();
    }
  }

  Future<void> analyzeImage() async {
    if (_selectedImage == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Get user's selected AI provider
      final profile = await _profileRepository.getProfile();
      AIProvider? aiProvider = profile?.aiProvider;

      // If no AI provider is set, use default
      aiProvider ??= AIProvider.gemini;

      // Get the appropriate AI service
      final AIService service = AIServiceFactory.getService(aiProvider);

      // Analyze the image
      final analysis = await service.analyzeImage(_selectedImage!);
      _currentAnalysis = FoodAnalysis(
        name: analysis.name,
        protein: analysis.protein,
        carbs: analysis.carbs,
        fat: analysis.fat,
        calories: analysis.calories,
        healthScore: analysis.healthScore,
        imagePath: _selectedImage!.path,
        date: _selectedDate,
      );
      await _saveCurrentAnalysis();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCurrentAnalysis() async {
    if (_currentAnalysis != null) {
      print('🔄 ImageAnalysisViewModel: Saving current analysis...');

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ ImageAnalysisViewModel: No authenticated user');
        throw Exception('User must be authenticated to save analysis');
      }

      // Upload image to S3 if we have a selected image
      String? s3ImageUrl;
      String? localImagePath;
      if (_selectedImage != null) {
        // Keep local file path for immediate display
        localImagePath = _selectedImage!.path;

        print('📤 ImageAnalysisViewModel: Uploading image to S3...');
        s3ImageUrl = await _awsService.uploadImageToS3(_selectedImage!);
        if (s3ImageUrl == null) {
          print('❌ ImageAnalysisViewModel: Failed to upload image to S3');
          throw Exception('Failed to upload image to S3');
        }
        print('✅ ImageAnalysisViewModel: Image uploaded to S3: $s3ImageUrl');
      }

      final analysis = FoodAnalysis(
        id: const Uuid().v4(), // Generate UUID for the object
        name: _currentAnalysis!.name,
        protein: _currentAnalysis!.protein,
        carbs: _currentAnalysis!.carbs,
        fat: _currentAnalysis!.fat,
        calories: _currentAnalysis!.calories,
        healthScore: _currentAnalysis!.healthScore,
        imagePath: s3ImageUrl ?? _currentAnalysis!.imagePath, // Legacy field
        localImagePath: localImagePath, // Local file path
        s3ImageUrl: s3ImageUrl, // S3 URL
        orderNumber: 0, // Not used anymore
        date: _selectedDate, // Use the selected date!
        dateOrderNumber: 0, // Not used anymore
      );

      print(
          '📝 ImageAnalysisViewModel: Created analysis: ${analysis.name} (${analysis.calories} cal) for date: $_selectedDate');
      _savedAnalyses.insert(
          0, analysis); // Insert at the beginning (top of list)

      print('💾 ImageAnalysisViewModel: Saving to storage...');
      await _storage.saveAnalyses(_savedAnalyses);

      // Debug: Check what's in SQLite after saving
      await _sqliteService.debugPrintFoodAnalyses(userId: userId);

      // Sync with AWS (user is authenticated)
      print('🔄 ImageAnalysisViewModel: Syncing to AWS...');
      await _syncService.saveFoodAnalysisToAWS(analysis);
      print('✅ ImageAnalysisViewModel: AWS sync completed');

      _currentAnalysis = null;
      _selectedImage = null;
      notifyListeners();

      // Check if it's a good time to show the rating dialog
      await _checkAndShowRating();
    }
  }

  Future<FoodAnalysis?> removeAnalysis(int index) async {
    if (index >= 0 && index < _savedAnalyses.length) {
      final removedAnalysis = _savedAnalyses[index];
      print(
          '🗑️ ImageAnalysisViewModel: Removing analysis: ${removedAnalysis.name}');

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ ImageAnalysisViewModel: No authenticated user');
        throw Exception('User must be authenticated to remove analysis');
      }

      // Remove from list immediately to update UI
      _savedAnalyses.removeAt(index);
      notifyListeners(); // Notify immediately to update UI

      try {
        print(
            '💾 ImageAnalysisViewModel: Saving updated analyses to storage...');
        await _storage.saveAnalyses(_savedAnalyses);

        // Sync deletion with AWS (user is authenticated)
        print('🔄 ImageAnalysisViewModel: Syncing deletion to AWS...');
        await _syncService.deleteFoodAnalysisFromAWS(removedAnalysis);
        print('✅ ImageAnalysisViewModel: AWS deletion sync completed');
      } catch (e) {
        print('❌ ImageAnalysisViewModel: Error during deletion: $e');
        // Re-add the analysis if deletion failed
        _savedAnalyses.insert(index, removedAnalysis);
        notifyListeners();
        rethrow;
      }

      return removedAnalysis;
    }
    return null;
  }

  Future<void> addAnalysis(FoodAnalysis analysis) async {
    print('🔄 ImageAnalysisViewModel: Adding analysis: ${analysis.name}');

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('❌ ImageAnalysisViewModel: No authenticated user');
      throw Exception('User must be authenticated to add analysis');
    }

    // Insert the analysis at the beginning of the list (top)
    _savedAnalyses.insert(0, analysis);

    print('💾 ImageAnalysisViewModel: Saving analyses to storage...');
    await _storage.saveAnalyses(_savedAnalyses);

    // Debug: Check what's in SQLite after saving
    await _sqliteService.debugPrintFoodAnalyses(userId: userId);

    // Sync with AWS (user is authenticated)
    print('🔄 ImageAnalysisViewModel: Syncing to AWS...');
    await _syncService.saveFoodAnalysisToAWS(analysis);

    notifyListeners();
  }

  void clearImage() {
    _selectedImage = null;
    _currentAnalysis = null;
    _error = null;
    notifyListeners();
  }

  // Add method to handle "Maybe Later" response
  Future<void> handleMaybeLater() async {
    await _sqliteService
        .setMaybeLaterTimestamp(DateTime.now().millisecondsSinceEpoch);
  }

  // Force refresh the UI - useful after sign-in when data might not be immediately available
  Future<void> forceRefresh() async {
    print('🔄 ImageAnalysisViewModel: Force refreshing UI...');
    await _loadSavedAnalyses();
    print(
        '✅ ImageAnalysisViewModel: Force refresh completed, count: ${_savedAnalyses.length}');
  }
}

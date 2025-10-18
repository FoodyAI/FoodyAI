import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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
import '../widgets/rating_dialog.dart';
import '../../config/routes/navigation_service.dart';

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
    // Note: Only reload when data comes from AWS (sign-in), not when adding new foods locally
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
    // 🔧 FIX #1: Add retry logic with exponential backoff
    int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        print('📥 ImageAnalysisViewModel: Loading analyses from SQLite (attempt ${retryCount + 1}/$maxRetries)...');
        _savedAnalyses = await _storage.loadAnalyses();
        // Sort by createdAt in descending order (latest first)
        _savedAnalyses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print('✅ ImageAnalysisViewModel: Loaded ${_savedAnalyses.length} analyses successfully');
        notifyListeners();
        return; // Success - exit retry loop
      } catch (e) {
        retryCount++;
        print('⚠️ ImageAnalysisViewModel: Failed to load analyses (attempt $retryCount/$maxRetries): $e');

        if (retryCount >= maxRetries) {
          // Final failure - set empty list to avoid null issues
          print('❌ ImageAnalysisViewModel: All retry attempts failed, setting empty list');
          _savedAnalyses = [];
          notifyListeners();
          return;
        }

        // Exponential backoff: 100ms, 500ms, 1000ms
        final delayMs = retryCount == 1 ? 100 : (retryCount == 2 ? 500 : 1000);
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  // Public method to reload analyses (called after AWS sync)
  Future<void> reloadAnalyses() async {
    print('🔄 ImageAnalysisViewModel: Manually reloading analyses after AWS sync...');
    // Retry logic is now handled inside _loadSavedAnalyses()
    await _loadSavedAnalyses();
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
    final context = NavigationService.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const RatingDialog(),
      );
    }
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

        print('📸 [ViewModel] Image picked, starting analysis...');
        await analyzeImage();
        print('✅ [ViewModel] Analysis complete, error: $_error');

        // Show error snackbar if analysis failed
        if (_error != null) {
          print('⚠️ [ViewModel] Error detected, showing snackbar...');
          // Use NavigationService to get a valid context instead of the passed context
          final validContext = NavigationService.currentContext;
          if (validContext != null && validContext.mounted) {
            _showErrorSnackBar(validContext, _error!);
          } else {
            print('❌ [ViewModel] No valid context available!');
          }
        } else {
          print('✅ [ViewModel] No error, analysis successful');
        }
      }
      // User cancelled - no need to show message
    } catch (e) {
      // Handle unexpected errors (permission errors are already handled by PermissionService)
      _error = 'Failed to access camera. Please try again.';
      notifyListeners();
      final validContext = NavigationService.currentContext;
      if (validContext != null && validContext.mounted) {
        _showErrorSnackBar(validContext, _error!);
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String errorMessage) {
    print('🚨 [ViewModel] Showing error snackbar: $errorMessage');

    // Extract user-friendly message from error
    String displayMessage = 'This image is not related to food';

    // Check if it contains our specific error message
    if (errorMessage.contains('This image is not related to food')) {
      displayMessage = 'This image is not related to food';
    } else {
      // For other errors, clean up and show
      displayMessage = errorMessage
          .replaceAll('Exception: ', '')
          .replaceAll('Error analyzing image with Gemini: ', '')
          .replaceAll('Error analyzing image with OpenAI: ', '')
          .replaceAll('Error analyzing image with Claude: ', '')
          .replaceAll('Error analyzing image with Hugging Face: ', '')
          .replaceAll('Error analyzing image: ', '');

      // If the message is too long, just show the core message
      if (displayMessage.length > 100) {
        displayMessage = 'This image is not related to food';
      }
    }

    print('📝 [ViewModel] Display message: $displayMessage');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayMessage,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 4),
      ),
    );

    print('✅ [ViewModel] Snackbar displayed');
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
      _isLoading = false;
      await _saveCurrentAnalysis();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _selectedImage = null; // Clear selected image on error
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

      // Clear current analysis and image after saving to prevent double notify
      _currentAnalysis = null;
      _selectedImage = null;

      // Debug: Check what's in SQLite after saving
      await _sqliteService.debugPrintFoodAnalyses(userId: userId);

      // Sync with AWS (user is authenticated)
      print('🔄 ImageAnalysisViewModel: Syncing to AWS...');
      await _syncService.saveFoodAnalysisToAWS(analysis);
      print('✅ ImageAnalysisViewModel: AWS sync completed');

      // Single UI update after all operations are complete
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

  /// Add analysis with loading state (for barcode scanner)
  /// Shows shimmer effect on home page while processing
  Future<void> addAnalysisWithLoading(FoodAnalysis analysis) async {
    print('🔄 ImageAnalysisViewModel: Adding analysis with loading: ${analysis.name}');

    // Set loading state to show shimmer on home page
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Add a small delay to ensure shimmer is visible
      await Future.delayed(const Duration(milliseconds: 500));

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

      print('✅ ImageAnalysisViewModel: Analysis added successfully');

      // Check if it's a good time to show the rating dialog
      await _checkAndShowRating();
    } catch (e) {
      print('❌ ImageAnalysisViewModel: Error adding analysis: $e');
      _error = e.toString();
    } finally {
      // Clear loading state
      _isLoading = false;
      notifyListeners();
    }
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

  /// Add barcode analysis with automatic image download and S3 upload
  /// Downloads image from HTTP URL, saves locally, uploads to S3, then saves analysis
  Future<void> addBarcodeAnalysis({
    required String productName,
    required String imageUrl,
    required double protein,
    required double carbs,
    required double fat,
    required double calories,
    required double healthScore,
  }) async {
    print('🔄 ImageAnalysisViewModel: Adding barcode analysis: $productName');
    print('📥 ImageAnalysisViewModel: Downloading image from: $imageUrl');

    // Set loading state to show shimmer on home page
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ ImageAnalysisViewModel: No authenticated user');
        throw Exception('User must be authenticated to add analysis');
      }

      // Download image from HTTP URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'barcode_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File('${tempDir.path}/$fileName');

      // Save downloaded image to temporary file
      await tempFile.writeAsBytes(response.bodyBytes);
      print('✅ ImageAnalysisViewModel: Image downloaded and saved to: ${tempFile.path}');

      // Upload image to S3
      print('📤 ImageAnalysisViewModel: Uploading image to S3...');
      final s3ImageUrl = await _awsService.uploadImageToS3(tempFile);
      if (s3ImageUrl == null) {
        throw Exception('Failed to upload image to S3');
      }
      print('✅ ImageAnalysisViewModel: Image uploaded to S3: $s3ImageUrl');

      // Create FoodAnalysis with S3 path
      final analysis = FoodAnalysis(
        id: const Uuid().v4(),
        name: productName,
        protein: protein,
        carbs: carbs,
        fat: fat,
        calories: calories,
        healthScore: healthScore,
        imagePath: s3ImageUrl, // Legacy field
        localImagePath: tempFile.path, // Local file path
        s3ImageUrl: s3ImageUrl, // S3 URL
        orderNumber: 0,
        date: _selectedDate,
        dateOrderNumber: 0,
      );

      print('📝 ImageAnalysisViewModel: Created barcode analysis: ${analysis.name} (${analysis.calories} cal)');

      // Insert the analysis at the beginning of the list (top)
      _savedAnalyses.insert(0, analysis);

      print('💾 ImageAnalysisViewModel: Saving analyses to storage...');
      await _storage.saveAnalyses(_savedAnalyses);

      // Debug: Check what's in SQLite after saving
      await _sqliteService.debugPrintFoodAnalyses(userId: userId);

      // Sync with AWS (user is authenticated)
      print('🔄 ImageAnalysisViewModel: Syncing to AWS...');
      await _syncService.saveFoodAnalysisToAWS(analysis);
      print('✅ ImageAnalysisViewModel: AWS sync completed');

      // Check if it's a good time to show the rating dialog
      await _checkAndShowRating();

      print('✅ ImageAnalysisViewModel: Barcode analysis added successfully');
    } catch (e) {
      print('❌ ImageAnalysisViewModel: Error adding barcode analysis: $e');
      _error = e.toString();
    } finally {
      // Clear loading state
      _isLoading = false;
      notifyListeners();
    }
  }
}

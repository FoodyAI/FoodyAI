import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/food_analysis.dart';
import '../../data/datasources/remote/ai_service.dart';
import '../../data/datasources/remote/ai_service_factory.dart';
import '../../data/datasources/local/food_analysis_storage.dart';
import '../../data/services/sqlite_service.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../di/service_locator.dart';
import '../../services/sync_service.dart';
import '../widgets/rating_dialog.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ImageAnalysisViewModel extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final FoodAnalysisStorage _storage = FoodAnalysisStorage();
  final SQLiteService _sqliteService = SQLiteService();
  final UserProfileRepository _profileRepository =
      getIt<UserProfileRepository>();
  final SyncService _syncService = SyncService();
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
    notifyListeners();
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

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? img = await _picker.pickImage(source: source);
      if (img != null) {
        _selectedImage = File(img.path);
        _currentAnalysis = null;
        _error = null;
        notifyListeners();
        await analyzeImage();
      }
    } catch (e) {
      _error = 'Failed to pick image';
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

      // No need to count analyses for ordering anymore

      final analysis = FoodAnalysis(
        name: _currentAnalysis!.name,
        protein: _currentAnalysis!.protein,
        carbs: _currentAnalysis!.carbs,
        fat: _currentAnalysis!.fat,
        calories: _currentAnalysis!.calories,
        healthScore: _currentAnalysis!.healthScore,
        imagePath: _currentAnalysis!.imagePath,
        orderNumber: 0, // Not used anymore
        date: _selectedDate,
        dateOrderNumber: 0, // Not used anymore
      );

      print(
          '📝 ImageAnalysisViewModel: Created analysis: ${analysis.name} (${analysis.calories} cal)');
      _savedAnalyses.add(analysis);

      print('💾 ImageAnalysisViewModel: Saving to storage...');
      await _storage.saveAnalyses(_savedAnalyses);

      // Debug: Check what's in SQLite after saving
      await _sqliteService.debugPrintFoodAnalyses();

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
      _savedAnalyses.removeAt(index);

      await _storage.saveAnalyses(_savedAnalyses);
      notifyListeners();
      return removedAnalysis;
    }
    return null;
  }

  Future<void> addAnalysis(FoodAnalysis analysis) async {
    print('🔄 ImageAnalysisViewModel: Adding analysis: ${analysis.name}');

    // Simply add the analysis to the list
    _savedAnalyses.add(analysis);

    print('💾 ImageAnalysisViewModel: Saving analyses to storage...');
    await _storage.saveAnalyses(_savedAnalyses);

    // Debug: Check what's in SQLite after saving
    await _sqliteService.debugPrintFoodAnalyses();

    // Sync with AWS if user is signed in
    if (_auth.currentUser != null) {
      print('🔄 ImageAnalysisViewModel: User is signed in, syncing to AWS...');
      await _syncService.saveFoodAnalysisToAWS(analysis);
    } else {
      print('❌ ImageAnalysisViewModel: No user signed in, skipping AWS sync');
    }

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
}

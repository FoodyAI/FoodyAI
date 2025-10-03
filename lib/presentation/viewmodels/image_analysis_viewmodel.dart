import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/food_analysis.dart';
import '../../data/datasources/remote/ai_service.dart';
import '../../data/datasources/remote/ai_service_factory.dart';
import '../../data/datasources/local/food_analysis_storage.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../di/service_locator.dart';
import '../widgets/rating_dialog.dart';
import '../pages/ai_provider_selection_page.dart';
import '../../core/events/profile_update_event.dart';
import '../../data/services/subscription_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ImageAnalysisViewModel extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final FoodAnalysisStorage _storage = FoodAnalysisStorage();
  final UserProfileRepository _profileRepository =
      getIt<UserProfileRepository>();

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
    final prefs = await SharedPreferences.getInstance();
    final firstUseTimestamp = prefs.getInt('first_use_date');
    if (firstUseTimestamp == null) {
      _firstUseDate = DateTime.now();
      await prefs.setInt(
          'first_use_date', _firstUseDate!.millisecondsSinceEpoch);
    } else {
      _firstUseDate = DateTime.fromMillisecondsSinceEpoch(firstUseTimestamp);
    }
  }

  Future<void> _loadSavedAnalyses() async {
    _savedAnalyses = await _storage.loadAnalyses();
    notifyListeners();
  }

  Future<void> _checkAndShowRating() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSubmittedRating = prefs.getBool('has_submitted_rating') ?? false;
    final maybeLaterTimestamp = prefs.getInt('maybe_later_timestamp');

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
    
    // Check if user can perform analysis (usage limits)
    final canAnalyze = await SubscriptionService.canPerformAnalysis();
    if (!canAnalyze) {
      _error = 'You\'ve reached your monthly analysis limit. Upgrade to Premium for unlimited access.';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Get user's selected AI provider
      final profile = await _profileRepository.getProfile();
      final hasChosenAIProvider = await _profileRepository.getHasChosenAIProvider();
      AIProvider? aiProvider = profile?.aiProvider;
      
      // If user hasn't explicitly chosen an AI provider yet, show selection dialog
      if (!hasChosenAIProvider) {
        _isLoading = false;
        notifyListeners();
        
        final context = navigatorKey.currentContext;
        if (context != null) {
          final selectedProvider = await Navigator.of(context).push<AIProvider>(
            MaterialPageRoute(
              builder: (context) => const AIProviderSelectionPage(),
            ),
          );
          
          if (selectedProvider == null) {
            // User cancelled, don't proceed with analysis
            return;
          }
          
          // Save the selected AI provider to user profile
          await _profileRepository.saveProfile(
            UserProfile(
              gender: profile?.gender ?? 'Not specified',
              age: profile?.age ?? 25,
              weightKg: profile?.weightKg ?? 70,
              heightCm: profile?.heightCm ?? 170,
              activityLevel: profile?.activityLevel ?? ActivityLevel.moderatelyActive,
              weightGoal: profile?.weightGoal ?? WeightGoal.maintain,
              aiProvider: selectedProvider,
              isGuest: profile?.isGuest ?? true,
            ),
            true, // isMetric
          );
          
          // Mark that user has chosen an AI provider
          await _profileRepository.setHasChosenAIProvider(true);
          
          // Notify that profile has been updated
          ProfileUpdateEvent.notifyUpdate();
          
          aiProvider = selectedProvider;
        } else {
          // Fallback to default if no context
          aiProvider = AIProvider.openai;
        }
        
        // Restart loading
        _isLoading = true;
        notifyListeners();
      }

      // Get the appropriate AI service
      final AIService service = AIServiceFactory.getService(aiProvider!);

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
      
      // Increment usage counter for free users
      final tier = await SubscriptionService.getSubscriptionTier();
      if (tier == SubscriptionTier.free) {
        await SubscriptionService.incrementFreeAnalysesUsed();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCurrentAnalysis() async {
    if (_currentAnalysis != null) {
      // Get the count of analyses for the current date
      final dateCount = _savedAnalyses
          .where((a) =>
              a.date.year == _selectedDate.year &&
              a.date.month == _selectedDate.month &&
              a.date.day == _selectedDate.day)
          .length;

      final analysis = FoodAnalysis(
        name: _currentAnalysis!.name,
        protein: _currentAnalysis!.protein,
        carbs: _currentAnalysis!.carbs,
        fat: _currentAnalysis!.fat,
        calories: _currentAnalysis!.calories,
        healthScore: _currentAnalysis!.healthScore,
        imagePath: _currentAnalysis!.imagePath,
        orderNumber: _savedAnalyses.length + 1,
        date: _selectedDate,
        dateOrderNumber: dateCount + 1,
      );
      _savedAnalyses.add(analysis);
      await _storage.saveAnalyses(_savedAnalyses);
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
      final removedDate = removedAnalysis.date;
      _savedAnalyses.removeAt(index);

      // Update order numbers for all analyses
      for (int i = 0; i < _savedAnalyses.length; i++) {
        _savedAnalyses[i] = FoodAnalysis(
          name: _savedAnalyses[i].name,
          protein: _savedAnalyses[i].protein,
          carbs: _savedAnalyses[i].carbs,
          fat: _savedAnalyses[i].fat,
          calories: _savedAnalyses[i].calories,
          healthScore: _savedAnalyses[i].healthScore,
          imagePath: _savedAnalyses[i].imagePath,
          orderNumber: i + 1,
          date: _savedAnalyses[i].date,
          dateOrderNumber: _savedAnalyses[i].dateOrderNumber,
        );
      }

      // Update date order numbers for the affected date
      final sameDateAnalyses = _savedAnalyses
          .where((a) =>
              a.date.year == removedDate.year &&
              a.date.month == removedDate.month &&
              a.date.day == removedDate.day)
          .toList();

      for (int i = 0; i < sameDateAnalyses.length; i++) {
        final analysis = sameDateAnalyses[i];
        final index = _savedAnalyses.indexOf(analysis);
        _savedAnalyses[index] = FoodAnalysis(
          name: analysis.name,
          protein: analysis.protein,
          carbs: analysis.carbs,
          fat: analysis.fat,
          calories: analysis.calories,
          healthScore: analysis.healthScore,
          imagePath: analysis.imagePath,
          orderNumber: analysis.orderNumber,
          date: analysis.date,
          dateOrderNumber: i + 1,
        );
      }

      await _storage.saveAnalyses(_savedAnalyses);
      notifyListeners();
      return removedAnalysis;
    }
    return null;
  }

  Future<void> addAnalysis(FoodAnalysis analysis) async {
    if (analysis.orderNumber > 0) {
      _savedAnalyses.insert(analysis.orderNumber - 1, analysis);
      for (int i = analysis.orderNumber; i < _savedAnalyses.length; i++) {
        _savedAnalyses[i] = FoodAnalysis(
          name: _savedAnalyses[i].name,
          protein: _savedAnalyses[i].protein,
          carbs: _savedAnalyses[i].carbs,
          fat: _savedAnalyses[i].fat,
          calories: _savedAnalyses[i].calories,
          healthScore: _savedAnalyses[i].healthScore,
          imagePath: _savedAnalyses[i].imagePath,
          orderNumber: i + 1,
          date: _savedAnalyses[i].date,
          dateOrderNumber: _savedAnalyses[i].dateOrderNumber,
        );
      }
    } else {
      // Get the count of analyses for the current date
      final dateCount = _savedAnalyses
          .where((a) =>
              a.date.year == _selectedDate.year &&
              a.date.month == _selectedDate.month &&
              a.date.day == _selectedDate.day)
          .length;

      final newAnalysis = FoodAnalysis(
        name: analysis.name,
        protein: analysis.protein,
        carbs: analysis.carbs,
        fat: analysis.fat,
        calories: analysis.calories,
        healthScore: analysis.healthScore,
        imagePath: analysis.imagePath,
        orderNumber: _savedAnalyses.length + 1,
        date: _selectedDate,
        dateOrderNumber: dateCount + 1,
      );
      _savedAnalyses.add(newAnalysis);
    }
    await _storage.saveAnalyses(_savedAnalyses);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'maybe_later_timestamp', DateTime.now().millisecondsSinceEpoch);
  }
}

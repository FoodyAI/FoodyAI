import 'dart:io';
import '../../models/food_analysis.dart';

/// Base interface for AI food analysis services
abstract class AIService {
  Future<FoodAnalysis> analyzeImage(File image);
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/food_analysis.dart';

class FoodAnalysisStorage {
  static const String _storageKey = 'saved_food_analyses';

  Future<void> saveAnalyses(List<FoodAnalysis> analyses) async {
    final prefs = await SharedPreferences.getInstance();
    final analysesJson = analyses
        .map((analysis) => {
              'name': analysis.name,
              'protein': analysis.protein,
              'carbs': analysis.carbs,
              'fat': analysis.fat,
              'calories': analysis.calories,
              'healthScore': analysis.healthScore,
              'imagePath': analysis.imagePath,
            })
        .toList();

    await prefs.setString(_storageKey, jsonEncode(analysesJson));
  }

  Future<List<FoodAnalysis>> loadAnalyses() async {
    final prefs = await SharedPreferences.getInstance();
    final analysesJson = prefs.getString(_storageKey);

    if (analysesJson == null) return [];

    final List<dynamic> decoded = jsonDecode(analysesJson);
    return decoded
        .map((item) => FoodAnalysis(
              name: item['name'],
              protein: (item['protein'] as num).toDouble(),
              carbs: (item['carbs'] as num).toDouble(),
              fat: (item['fat'] as num).toDouble(),
              calories: (item['calories'] as num).toDouble(),
              healthScore: (item['healthScore'] as num).toDouble(),
              imagePath: item['imagePath'] as String?,
            ))
        .toList();
  }
}

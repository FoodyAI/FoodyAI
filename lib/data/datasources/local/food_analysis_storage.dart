import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/food_analysis.dart';

class FoodAnalysisStorage {
  static const String _storageKey = 'saved_food_analyses';

  Future<void> saveAnalyses(List<FoodAnalysis> analyses) async {
    final prefs = await SharedPreferences.getInstance();
    final analysesJson = analyses.map((analysis) => analysis.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(analysesJson));
  }

  Future<List<FoodAnalysis>> loadAnalyses() async {
    final prefs = await SharedPreferences.getInstance();
    final analysesJson = prefs.getString(_storageKey);

    if (analysesJson == null) return [];

    final List<dynamic> decoded = jsonDecode(analysesJson);
    return decoded.map((item) => FoodAnalysis.fromJson(item)).toList();
  }
}

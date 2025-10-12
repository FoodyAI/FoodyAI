import 'package:firebase_auth/firebase_auth.dart';
import '../../models/food_analysis.dart';
import '../../services/sqlite_service.dart';

class FoodAnalysisStorage {
  final SQLiteService _sqliteService = SQLiteService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveAnalyses(List<FoodAnalysis> analyses) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('❌ FoodAnalysisStorage: No authenticated user');
      throw Exception('User must be authenticated to save analyses');
    }
    await _sqliteService.saveFoodAnalyses(analyses, userId: userId);
  }

  Future<List<FoodAnalysis>> loadAnalyses() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('❌ FoodAnalysisStorage: No authenticated user');
      return [];
    }
    return await _sqliteService.getFoodAnalyses(userId: userId);
  }
}

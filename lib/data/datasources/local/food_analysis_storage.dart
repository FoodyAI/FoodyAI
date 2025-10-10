import '../../models/food_analysis.dart';
import '../../services/sqlite_service.dart';

class FoodAnalysisStorage {
  final SQLiteService _sqliteService = SQLiteService();

  Future<void> saveAnalyses(List<FoodAnalysis> analyses) async {
    await _sqliteService.saveFoodAnalyses(analyses);
  }

  Future<List<FoodAnalysis>> loadAnalyses() async {
    return await _sqliteService.getFoodAnalyses();
  }
}

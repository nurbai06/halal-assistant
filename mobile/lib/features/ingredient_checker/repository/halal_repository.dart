import '../../../core/network/api_client.dart';
import '../models/analysis_result.dart';
import '../models/dashboard_data.dart';
import '../models/ingredient_info.dart';

/// Everything the app knows comes from the backend through this class.
/// Blocs depend on it instead of on HTTP details.
class HalalRepository {
  const HalalRepository(this._api);

  final ApiClient _api;

  /// POST /api/analyze — the backend classifies the ingredients.
  Future<AnalysisResult> analyzeIngredients({
    required String productName,
    required String ingredients,
  }) async {
    final json = await _api.post(
      '/api/analyze',
      body: {'product_name': productName, 'ingredients': ingredients},
    );
    return AnalysisResult.fromJson(json as Map<String, dynamic>);
  }

  /// GET /api/products/barcode/{barcode} — null when the product is unknown
  /// to Open Food Facts.
  Future<AnalysisResult?> lookupBarcode(String barcode) async {
    try {
      final json = await _api.get('/api/products/barcode/$barcode');
      return AnalysisResult.fromJson(json as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.isNotFound) return null;
      rethrow;
    }
  }

  /// GET /api/history
  Future<List<AnalysisResult>> getHistory() async {
    final json = await _api.get('/api/history');
    return (json as List)
        .cast<Map<String, dynamic>>()
        .map(AnalysisResult.fromJson)
        .toList();
  }

  /// DELETE /api/history/{id}
  Future<void> deleteHistoryItem(int id) => _api.delete('/api/history/$id');

  /// GET /api/dashboard
  Future<DashboardData> getDashboard() async {
    final json = await _api.get('/api/dashboard');
    return DashboardData.fromJson(json as Map<String, dynamic>);
  }

  /// GET /api/ingredients
  Future<List<IngredientInfo>> getIngredients() async {
    final json = await _api.get('/api/ingredients');
    return (json as List)
        .cast<Map<String, dynamic>>()
        .map(IngredientInfo.fromJson)
        .toList();
  }

  /// GET /api/ingredients/{code}
  Future<IngredientInfo> getIngredient(String code) async {
    final json = await _api.get('/api/ingredients/$code');
    return IngredientInfo.fromJson(json as Map<String, dynamic>);
  }
}

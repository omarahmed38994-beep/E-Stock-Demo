import '../core/api_client.dart';

class DashboardService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getOverview() async {
    final data = await _api.get('/dashboard/overview');
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> getBusinessOverview() async {
    final data = await _api.get('/dashboard/business-overview');
    return Map<String, dynamic>.from(data);
  }
}

class AnalyticsService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> salesAnalytics({String period = '30d', int? branchId, int? categoryId, int? productId}) async {
    final data = await _api.get('/analytics/sales', query: {
      'period': period,
      if (branchId != null) 'branch_id': branchId,
      if (categoryId != null) 'category_id': categoryId,
      if (productId != null) 'product_id': productId,
    });
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> profitAnalytics({String period = '30d', int? branchId}) async {
    final data = await _api.get('/analytics/profit', query: {
      'period': period,
      if (branchId != null) 'branch_id': branchId,
    });
    return Map<String, dynamic>.from(data);
  }

  Future<List<dynamic>> branchesAnalytics({String period = '30d'}) async {
    final data = await _api.get('/analytics/branches', query: {'period': period});
    return List<dynamic>.from(data);
  }
}

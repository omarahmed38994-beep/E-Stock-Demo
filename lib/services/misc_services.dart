import '../core/api_client.dart';
import '../models/alert.dart';

class AlertService {
  final ApiClient _api = ApiClient();

  Future<List<AlertItem>> listAlerts({String? severity, bool? isRead}) async {
    final data = await _api.get('/alerts', query: {
      if (severity != null) 'severity': severity,
      if (isRead != null) 'is_read': isRead,
    });
    return (data as List).map((e) => AlertItem.fromJson(e)).toList();
  }

  Future<void> markRead(int alertId) async {
    await _api.patch('/alerts/$alertId/read');
  }
}

class ActivityService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> listActivity({int? branchId, String? entityType, int page = 1}) async {
    final data = await _api.get('/activity', query: {
      if (branchId != null) 'branch_id': branchId,
      if (entityType != null) 'entity_type': entityType,
      'page': page,
      'page_size': 40,
    });
    return Map<String, dynamic>.from(data);
  }
}

class TransferService {
  final ApiClient _api = ApiClient();

  Future<List<dynamic>> listTransfers({String? status}) async {
    final data = await _api.get('/transfers', query: {if (status != null) 'status': status});
    return List<dynamic>.from(data);
  }

  Future<void> approve(int id) async {
    await _api.patch('/transfers/$id/approve');
  }

  Future<void> reject(int id) async {
    await _api.patch('/transfers/$id/reject');
  }

  Future<void> create(int fromBranchId, int toBranchId, List<Map<String, dynamic>> items) async {
    await _api.post('/transfers', data: {
      'from_branch_id': fromBranchId,
      'to_branch_id': toBranchId,
      'items': items,
    });
  }
}

class AssistantService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> ask(String question) async {
    final data = await _api.post('/assistant/query', data: {'question': question});
    return Map<String, dynamic>.from(data);
  }
}

class ForecastService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> forecastProduct(int productId, {int days = 7}) async {
    final data = await _api.get('/forecast/$productId', query: {'days': days});
    return Map<String, dynamic>.from(data);
  }

  Future<List<dynamic>> recommendations() async {
    final data = await _api.get('/recommendations');
    return List<dynamic>.from(data);
  }

  Future<List<dynamic>> anomalies() async {
    final data = await _api.get('/anomalies');
    return List<dynamic>.from(data);
  }
}

class SearchService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> search(String query) async {
    final data = await _api.get('/search', query: {'q': query});
    return Map<String, dynamic>.from(data);
  }
}

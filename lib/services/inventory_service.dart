import '../core/api_client.dart';
import '../models/inventory_item.dart';
import '../models/product.dart';

class InventoryService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> overview({int? branchId, String? status}) async {
    final data = await _api.get('/inventory', query: {
      if (branchId != null) 'branch_id': branchId,
      if (status != null) 'status': status,
    });
    return Map<String, dynamic>.from(data);
  }

  Future<List<InventoryItem>> lowStock({int? branchId}) async {
    final data = await _api.get('/inventory/low-stock', query: {if (branchId != null) 'branch_id': branchId});
    return (data as List).map((e) => InventoryItem.fromJson(e)).toList();
  }

  Future<List<InventoryItem>> expiring({int? branchId}) async {
    final data = await _api.get('/inventory/expiring', query: {if (branchId != null) 'branch_id': branchId});
    return (data as List).map((e) => InventoryItem.fromJson(e)).toList();
  }
}

class ProductService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> listProducts({String? search, int page = 1, int pageSize = 30}) async {
    final data = await _api.get('/products', query: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'page_size': pageSize,
    });
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> productDetail(int id) async {
    final data = await _api.get('/products/$id');
    return Map<String, dynamic>.from(data);
  }
}

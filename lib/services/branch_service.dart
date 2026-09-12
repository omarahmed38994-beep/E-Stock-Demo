import '../core/api_client.dart';
import '../models/branch.dart';

class BranchService {
  final ApiClient _api = ApiClient();

  Future<List<BranchPerformance>> listBranches() async {
    final data = await _api.get('/branches');
    return (data as List).map((e) => BranchPerformance.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> compareBranches() async {
    final data = await _api.get('/branches/compare');
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> branchDetail(int branchId) async {
    final data = await _api.get('/branches/$branchId');
    return Map<String, dynamic>.from(data);
  }
}

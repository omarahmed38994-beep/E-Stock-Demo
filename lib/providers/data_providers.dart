import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dashboard_service.dart';
import '../services/branch_service.dart';
import '../services/inventory_service.dart';
import '../services/misc_services.dart';
import '../models/branch.dart';
import '../models/alert.dart';

/// A simple auto-incrementing "refresh token" pattern: bump this provider's
/// value to force all dependent FutureProviders to re-fetch (used by
/// pull-to-refresh across the app).
final refreshTickProvider = StateProvider<int>((ref) => 0);

final dashboardOverviewProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return DashboardService().getOverview();
});

final businessOverviewProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return DashboardService().getBusinessOverview();
});

final branchListProvider = FutureProvider.autoDispose<List<BranchPerformance>>((ref) async {
  ref.watch(refreshTickProvider);
  return BranchService().listBranches();
});

final branchCompareProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return BranchService().compareBranches();
});

final branchDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, branchId) async {
  ref.watch(refreshTickProvider);
  return BranchService().branchDetail(branchId);
});

final inventoryOverviewProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int?>((ref, branchId) async {
  ref.watch(refreshTickProvider);
  return InventoryService().overview(branchId: branchId);
});

final alertsProvider = FutureProvider.autoDispose<List<AlertItem>>((ref) async {
  ref.watch(refreshTickProvider);
  return AlertService().listAlerts();
});

final activityProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int?>((ref, branchId) async {
  ref.watch(refreshTickProvider);
  return ActivityService().listActivity(branchId: branchId);
});

final transfersProvider = FutureProvider.autoDispose.family<List<dynamic>, String?>((ref, status) async {
  ref.watch(refreshTickProvider);
  return TransferService().listTransfers(status: status);
});

final recommendationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(refreshTickProvider);
  return ForecastService().recommendations();
});

final productsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, search) async {
  ref.watch(refreshTickProvider);
  return ProductService().listProducts(search: search);
});

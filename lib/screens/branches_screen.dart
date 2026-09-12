import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/state_views.dart';
import 'branch_detail_screen.dart';
import 'branch_comparison_screen.dart';

class BranchesScreen extends ConsumerWidget {
  final bool scopedToOwnBranch;
  final int? ownBranchId;
  const BranchesScreen({super.key, this.scopedToOwnBranch = false, this.ownBranchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(branchListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branches'),
        actions: [
          if (!scopedToOwnBranch)
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded),
              tooltip: 'Compare Branches',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BranchComparisonScreen())),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(refreshTickProvider.notifier).state++,
        child: async.when(
          loading: () => const DashboardSkeleton(),
          error: (e, _) => ErrorStateView(message: e.toString(), onRetry: () => ref.invalidate(branchListProvider)),
          data: (branches) {
            if (branches.isEmpty) return const EmptyStateView(message: 'No branches found');
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: branches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final b = branches[i];
                final growthColor = b.growthPct >= 0 ? AppColors.success : AppColors.critical;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BranchDetailScreen(branchId: b.id, branchName: b.name))),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: b.type == 'Main' ? AppColors.primary.withOpacity(0.12) : AppColors.accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(b.type == 'Main' ? Icons.warehouse_rounded : Icons.storefront_rounded,
                                  color: b.type == 'Main' ? AppColors.primary : AppColors.accent, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(b.name, style: theme.textTheme.titleSmall),
                                  Text(b.code, style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: growthColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                              child: Text('${b.growthPct >= 0 ? '+' : ''}${b.growthPct.toStringAsFixed(1)}%',
                                  style: TextStyle(color: growthColor, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            _Stat(label: 'Sales', value: 'EGP ${b.sales.toStringAsFixed(0)}'),
                            _Stat(label: 'Profit', value: 'EGP ${b.profit.toStringAsFixed(0)}'),
                            _Stat(label: 'Orders', value: '${b.orders}'),
                            _Stat(label: 'Low Stock', value: '${b.lowStockCount}', warn: b.lowStockCount > 0),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool warn;
  const _Stat({required this.label, required this.value, this.warn = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: warn ? AppColors.warning : null)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

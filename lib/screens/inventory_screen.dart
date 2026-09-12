import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/kpi_card.dart';
import '../widgets/state_views.dart';
import '../widgets/chips_and_badges.dart';

final _inventoryStatusFilterProvider = StateProvider<String?>((ref) => null);

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  static const _statuses = ['Healthy', 'Low Stock', 'Critical', 'Overstock', 'Expiring', 'Fast Moving', 'Slow Moving', 'Dead Stock'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inventoryOverviewProvider(null));
    final selectedStatus = ref.watch(_inventoryStatusFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(refreshTickProvider.notifier).state++,
        child: async.when(
          loading: () => const DashboardSkeleton(),
          error: (e, _) => ErrorStateView(message: e.toString(), onRetry: () => ref.invalidate(inventoryOverviewProvider(null))),
          data: (d) {
            final summary = d['summary'];
            var items = d['items'] as List;
            if (selectedStatus != null) {
              items = items.where((i) => i['status'] == selectedStatus).toList();
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    KpiCard(label: 'Total SKUs', value: '${summary['total_skus']}', icon: Icons.qr_code_2_rounded, iconColor: AppColors.primary),
                    KpiCard(label: 'Total Units', value: '${summary['total_units']}', icon: Icons.inventory_2_rounded, iconColor: AppColors.accent),
                    KpiCard(label: 'Inventory Value', value: 'EGP ${(summary['inventory_value'] as num).toStringAsFixed(0)}', icon: Icons.attach_money_rounded, iconColor: AppColors.success),
                    KpiCard(label: 'Low Stock', value: '${summary['low_stock']}', icon: Icons.warning_amber_rounded, iconColor: AppColors.warning),
                    KpiCard(label: 'Overstock', value: '${summary['overstock']}', icon: Icons.upload_rounded, iconColor: AppColors.info),
                    KpiCard(label: 'Expiring', value: '${summary['expiring']}', icon: Icons.event_busy_rounded, iconColor: AppColors.critical),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(label: 'All', selected: selectedStatus == null, onTap: () => ref.read(_inventoryStatusFilterProvider.notifier).state = null),
                      const SizedBox(width: 8),
                      ..._statuses.map((s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(label: s, selected: selectedStatus == s, onTap: () => ref.read(_inventoryStatusFilterProvider.notifier).state = s),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Padding(padding: EdgeInsets.only(top: 40), child: EmptyStateView(message: 'No items match this filter'))
                else
                  ...items.take(100).map((i) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(i['product'], style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                  Text('${i['branch']} · ${i['quantity']} units', style: theme.textTheme.bodySmall),
                                  if (i['days_of_stock_left'] != null)
                                    Text('~${(i['days_of_stock_left'] as num).toStringAsFixed(0)} days of stock left', style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            StatusBadge(status: i['status']),
                          ],
                        ),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          border: Border.all(color: selected ? AppColors.accent : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 12.5, color: selected ? Colors.white : null, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

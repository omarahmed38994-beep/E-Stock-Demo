import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/kpi_card.dart';
import '../widgets/state_views.dart';

class BusinessOverviewScreen extends ConsumerWidget {
  const BusinessOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(businessOverviewProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Business Overview')),
      body: async.when(
        loading: () => const DashboardSkeleton(),
        error: (e, _) => ErrorStateView(message: e.toString(), onRetry: () => ref.invalidate(businessOverviewProvider)),
        data: (d) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('How is my entire company doing?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Last 30 days vs. the previous 30 days', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                KpiCard(label: 'Total Revenue', value: 'EGP ${(d['total_revenue'] as num).toStringAsFixed(0)}', icon: Icons.attach_money_rounded, iconColor: AppColors.accent, trendPct: (d['sales_growth_pct'] as num?)?.toDouble()),
                KpiCard(label: 'Total Profit', value: 'EGP ${(d['total_profit'] as num).toStringAsFixed(0)}', icon: Icons.savings_rounded, iconColor: AppColors.success),
                KpiCard(label: 'Profit Margin', value: '${d['profit_margin_pct']}%', icon: Icons.percent_rounded, iconColor: AppColors.info),
                KpiCard(label: 'Sales Growth', value: '${(d['sales_growth_pct'] as num).toStringAsFixed(1)}%', icon: Icons.show_chart_rounded, iconColor: AppColors.primary),
              ],
            ),
            const SizedBox(height: 16),
            _InfoTile(icon: Icons.emoji_events_rounded, color: AppColors.success, label: 'Best Branch', value: d['best_branch'] ?? '—'),
            _InfoTile(icon: Icons.trending_down_rounded, color: AppColors.critical, label: 'Worst Branch', value: d['worst_branch'] ?? '—'),
            _InfoTile(icon: Icons.star_rounded, color: AppColors.accent, label: 'Best Product', value: d['best_product'] ?? '—'),
            _InfoTile(icon: Icons.hourglass_bottom_rounded, color: AppColors.warning, label: 'Slowest Product', value: d['slowest_product'] ?? '—'),
            _InfoTile(icon: Icons.warning_amber_rounded, color: AppColors.warning, label: 'Low Stock Count', value: '${d['low_stock_count']}'),
            _InfoTile(icon: Icons.event_busy_rounded, color: AppColors.critical, label: 'Expiring Products', value: '${d['expiring_products']}'),
            _InfoTile(icon: Icons.swap_horiz_rounded, color: AppColors.info, label: 'Pending Transfers', value: '${d['pending_transfers']}'),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dashboard_service.dart';
import '../theme/app_colors.dart';
import '../widgets/state_views.dart';
import '../widgets/trend_chart.dart';
import '../widgets/kpi_card.dart';

final _periodProvider = StateProvider<String>((ref) => '30d');
final _analyticsTabProvider = StateProvider<int>((ref) => 0); // 0 = Sales, 1 = Profit

final _salesAnalyticsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, period) async {
  return AnalyticsService().salesAnalytics(period: period);
});

final _profitAnalyticsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, period) async {
  return AnalyticsService().profitAnalytics(period: period);
});

const _periods = {'today': 'Today', '7d': '7 Days', '30d': '30 Days', '90d': '90 Days', '12m': '12 Months'};

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_periodProvider);
    final tab = ref.watch(_analyticsTabProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Sales')),
                      ButtonSegment(value: 1, label: Text('Profit')),
                    ],
                    selected: {tab},
                    onSelectionChanged: (s) => ref.read(_analyticsTabProvider.notifier).state = s.first,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _periods.entries.map((e) {
                final selected = period == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => ref.read(_periodProvider.notifier).state = e.key,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accent : Colors.transparent,
                        border: Border.all(color: selected ? AppColors.accent : Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(e.value, style: TextStyle(fontSize: 12.5, color: selected ? Colors.white : null, fontWeight: FontWeight.w600)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: tab == 0 ? _SalesTab(period: period) : _ProfitTab(period: period)),
        ],
      ),
    );
  }
}

class _SalesTab extends ConsumerWidget {
  final String period;
  const _SalesTab({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_salesAnalyticsProvider(period));
    final theme = Theme.of(context);

    return async.when(
      loading: () => const DashboardSkeleton(),
      error: (e, _) => ErrorStateView(message: e.toString(), onRetry: () => ref.invalidate(_salesAnalyticsProvider(period))),
      data: (d) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
            children: [
              KpiCard(label: 'Revenue', value: 'EGP ${(d['revenue'] as num).toStringAsFixed(0)}', icon: Icons.payments_rounded, iconColor: AppColors.accent),
              KpiCard(label: 'Orders', value: '${d['orders']}', icon: Icons.receipt_long_rounded, iconColor: AppColors.info),
              KpiCard(label: 'Avg Order Value', value: 'EGP ${(d['avg_order_value'] as num).toStringAsFixed(0)}', icon: Icons.shopping_cart_rounded, iconColor: AppColors.primary),
              KpiCard(label: 'Units Sold', value: '${d['units_sold']}', icon: Icons.inventory_rounded, iconColor: AppColors.success),
            ],
          ),
          const SizedBox(height: 16),
          _Card(title: 'Sales Trend', child: TrendLineChart(data: d['daily_trend'] ?? [])),
          const SizedBox(height: 16),
          _Card(
            title: 'Best Selling Products',
            child: Column(
              children: (d['best_selling'] as List).take(8).map<Widget>((p) {
                return ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(p['name'], style: const TextStyle(fontSize: 13)), trailing: Text('EGP ${(p['revenue'] as num).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)));
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ProfitTab extends ConsumerWidget {
  final String period;
  const _ProfitTab({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_profitAnalyticsProvider(period));

    return async.when(
      loading: () => const DashboardSkeleton(),
      error: (e, _) => ErrorStateView(message: e.toString(), onRetry: () => ref.invalidate(_profitAnalyticsProvider(period))),
      data: (d) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
            children: [
              KpiCard(label: 'Revenue', value: 'EGP ${(d['revenue'] as num).toStringAsFixed(0)}', icon: Icons.attach_money_rounded, iconColor: AppColors.accent),
              KpiCard(label: 'Cost', value: 'EGP ${(d['cost'] as num).toStringAsFixed(0)}', icon: Icons.money_off_rounded, iconColor: AppColors.warning),
              KpiCard(label: 'Gross Profit', value: 'EGP ${(d['gross_profit'] as num).toStringAsFixed(0)}', icon: Icons.savings_rounded, iconColor: AppColors.success),
              KpiCard(label: 'Margin', value: '${d['margin_pct']}%', icon: Icons.percent_rounded, iconColor: AppColors.primary),
            ],
          ),
          const SizedBox(height: 16),
          _Card(
            title: 'Profit by Category',
            child: Column(
              children: (d['by_category'] as List).take(8).map<Widget>((c) {
                return ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(c['category'], style: const TextStyle(fontSize: 13)), trailing: Text('EGP ${(c['profit'] as num).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)));
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            title: 'Most Profitable Products',
            child: Column(
              children: (d['top_products'] as List).take(6).map<Widget>((p) {
                return ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(p['name'], style: const TextStyle(fontSize: 13)), subtitle: Text('${p['margin_pct']}% margin'), trailing: Text('EGP ${(p['profit'] as num).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)));
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            title: 'Lowest Margin Products',
            child: Column(
              children: (d['lowest_margin_products'] as List).take(6).map<Widget>((p) {
                return ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(p['name'], style: const TextStyle(fontSize: 13)), trailing: Text('${p['margin_pct']}%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.warning)));
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: theme.textTheme.titleSmall), const SizedBox(height: 10), child]),
    );
  }
}

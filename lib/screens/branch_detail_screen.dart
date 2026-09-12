import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/state_views.dart';
import '../widgets/trend_chart.dart';
import '../widgets/chips_and_badges.dart';

class BranchDetailScreen extends ConsumerWidget {
  final int branchId;
  final String branchName;
  const BranchDetailScreen({super.key, required this.branchId, required this.branchName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(branchDetailProvider(branchId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(branchName)),
      body: async.when(
        loading: () => const DashboardSkeleton(),
        error: (e, _) => ErrorStateView(message: e.toString(), onRetry: () => ref.invalidate(branchDetailProvider(branchId))),
        data: (d) {
          final monthly = d['monthly_sales'];
          final daily = d['daily_sales'];
          final inv = d['inventory'];
          final lowStock = d['low_stock_products'] as List;
          final topProducts = d['top_products'] as List;
          final activity = d['recent_activity'] as List;
          final vsAvg = (d['vs_company_average_pct'] as num).toDouble();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accentDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monthly Sales', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                          Text('EGP ${(monthly['revenue'] as num).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                      child: Text('${vsAvg >= 0 ? '+' : ''}${vsAvg.toStringAsFixed(1)}% vs avg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _MiniStat(label: "Today's Sales", value: 'EGP ${(daily['revenue'] as num).toStringAsFixed(0)}')),
                const SizedBox(width: 12),
                Expanded(child: _MiniStat(label: 'Orders', value: '${daily['orders']}')),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _MiniStat(label: 'Inventory Value', value: 'EGP ${(inv['inventory_value'] as num).toStringAsFixed(0)}')),
                const SizedBox(width: 12),
                Expanded(child: _MiniStat(label: 'Low Stock SKUs', value: '${inv['low_stock']}', warn: (inv['low_stock'] as int) > 0)),
              ]),

              const SizedBox(height: 20),
              SectionHeader(title: 'Sales Trend'),
              _Card(child: TrendLineChart(data: monthly['daily_trend'] ?? [])),

              const SizedBox(height: 20),
              SectionHeader(title: 'Top Products'),
              _Card(
                child: topProducts.isEmpty
                    ? const EmptyStateView(message: 'No sales yet')
                    : Column(
                        children: topProducts.map<Widget>((p) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(p['name'], style: const TextStyle(fontSize: 13.5)),
                            trailing: Text('EGP ${(p['revenue'] as num).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 20),
              SectionHeader(title: 'Low Stock Products'),
              _Card(
                child: lowStock.isEmpty
                    ? const EmptyStateView(message: 'Inventory looks healthy')
                    : Column(
                        children: lowStock.map<Widget>((i) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(i['product'], style: const TextStyle(fontSize: 13.5)),
                            subtitle: Text('${i['quantity']} units left'),
                            trailing: StatusBadge(status: i['status']),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 20),
              SectionHeader(title: 'Recent Activity'),
              _Card(
                child: activity.isEmpty
                    ? const EmptyStateView(message: 'No recent activity')
                    : Column(
                        children: activity.map<Widget>((a) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.circle, size: 8, color: AppColors.accent),
                            title: Text(a['description'], style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool warn;
  const _MiniStat({required this.label, required this.value, this.warn = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: warn ? AppColors.warning : null)),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

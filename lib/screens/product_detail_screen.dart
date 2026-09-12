import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/inventory_service.dart';
import '../theme/app_colors.dart';
import '../widgets/state_views.dart';
import '../widgets/trend_chart.dart';

final _productDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, id) async {
  return ProductService().productDetail(id);
});

class ProductDetailScreen extends ConsumerWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_productDetailProvider(productId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: async.when(
        loading: () => const DashboardSkeleton(),
        error: (e, _) => ErrorStateView(message: e.toString(), onRetry: () => ref.invalidate(_productDetailProvider(productId))),
        data: (p) {
          final forecast = p['forecast'] as Map;
          final branchDist = p['branch_distribution'] as List;
          final salesTrend = (p['sales_trend'] as List).map((e) => {'date': e['date'], 'value': e['quantity']}).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(p['name'], style: theme.textTheme.headlineSmall),
              Text('${p['sku']} · ${p['category']}', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _StatCard(label: 'Selling Price', value: 'EGP ${(p['selling_price'] as num).toStringAsFixed(0)}')),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(label: 'Profit / Unit', value: 'EGP ${(p['profit_per_unit'] as num).toStringAsFixed(0)}', color: AppColors.success)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _StatCard(label: 'Current Stock', value: '${p['current_stock']}')),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(label: 'Sales Velocity', value: '${p['sales_velocity_per_day']}/day')),
              ]),

              const SizedBox(height: 20),
              Text('Demand Forecast', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accentDark]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ForecastRow(label: 'Current Stock', value: '${forecast['current_stock']}'),
                    _ForecastRow(label: 'Expected 7-day demand', value: '${forecast['forecast_7_day_demand']}'),
                    _ForecastRow(label: 'Expected 30-day demand', value: '${forecast['forecast_30_day_demand']}'),
                    _ForecastRow(
                      label: 'Estimated stockout',
                      value: forecast['estimated_stockout_days'] != null ? '${forecast['estimated_stockout_days']} days' : 'N/A',
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    Row(children: [
                      const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (forecast['recommended_reorder_qty'] as int) > 0
                              ? 'Recommendation: Reorder ${forecast['recommended_reorder_qty']} units'
                              : 'Stock levels look sufficient for now',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text('Sales Trend (90 days)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200)),
                child: TrendLineChart(data: salesTrend, color: AppColors.info),
              ),

              const SizedBox(height: 20),
              Text('Branch Distribution', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200)),
                child: Column(
                  children: branchDist.map<Widget>((b) {
                    return ListTile(
                      dense: true,
                      title: Text(b['branch'], style: const TextStyle(fontSize: 13.5)),
                      trailing: Text('${b['quantity']} units', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatCard({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ForecastRow extends StatelessWidget {
  final String label;
  final String value;
  const _ForecastRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

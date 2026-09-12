import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/data_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/kpi_card.dart';
import '../widgets/state_views.dart';
import '../widgets/chips_and_badges.dart';
import '../widgets/attention_required_card.dart';
import '../widgets/trend_chart.dart';
import 'notifications_screen.dart';
import 'business_overview_screen.dart';
import 'assistant_screen.dart';
import 'search_screen.dart';

final _currencyFmt = (num v) => 'EGP ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final overviewAsync = ref.watch(dashboardOverviewProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.insights_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('StockVision'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'Ask your business',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssistantScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(refreshTickProvider.notifier).state++,
        child: overviewAsync.when(
          loading: () => const DashboardSkeleton(),
          error: (e, _) => ErrorStateView(message: e.toString().replaceFirst('ApiException: ', ''), onRetry: () => ref.invalidate(dashboardOverviewProvider)),
          data: (data) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Welcome back, ${user?.name.split(' ').first ?? ''}', style: theme.textTheme.headlineSmall),
              Text('Here is what is happening across your business today.', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),

              // Attention Required — the key UX feature
              AttentionRequiredCard(items: data['attention_required'] ?? []),
              const SizedBox(height: 20),

              // KPI Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  KpiCard(
                    label: "Today's Sales",
                    value: _currencyFmt(data['today_sales'] ?? 0),
                    icon: Icons.payments_rounded,
                    iconColor: AppColors.accent,
                    trendPct: (data['sales_growth_vs_yesterday'] as num?)?.toDouble(),
                  ),
                  KpiCard(
                    label: "Today's Profit",
                    value: _currencyFmt(data['today_profit'] ?? 0),
                    icon: Icons.trending_up_rounded,
                    iconColor: AppColors.success,
                  ),
                  KpiCard(
                    label: 'Orders',
                    value: '${data['today_orders'] ?? 0}',
                    icon: Icons.receipt_long_rounded,
                    iconColor: AppColors.info,
                  ),
                  KpiCard(
                    label: 'Active Branches',
                    value: '${data['active_branches'] ?? 0}',
                    icon: Icons.store_rounded,
                    iconColor: AppColors.primary,
                  ),
                  KpiCard(
                    label: 'Low Stock Items',
                    value: '${data['low_stock_items'] ?? 0}',
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.warning,
                  ),
                  KpiCard(
                    label: 'Expiring Soon',
                    value: '${data['expiring_soon'] ?? 0}',
                    icon: Icons.hourglass_bottom_rounded,
                    iconColor: AppColors.critical,
                  ),
                  KpiCard(
                    label: 'Pending Transfers',
                    value: '${data['pending_transfers'] ?? 0}',
                    icon: Icons.swap_horiz_rounded,
                    iconColor: AppColors.info,
                  ),
                  KpiCard(
                    label: 'Notifications',
                    value: '${data['unread_notifications'] ?? 0}',
                    icon: Icons.notifications_rounded,
                    iconColor: AppColors.accentDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              SectionHeader(
                title: 'Business Overview',
                actionLabel: 'View details',
                onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessOverviewScreen())),
              ),

              const SizedBox(height: 12),
              _ChartCard(title: 'Sales Trend (30 days)', child: TrendLineChart(data: data['sales_trend_30d'] ?? [], color: AppColors.accent)),
              const SizedBox(height: 16),
              _ChartCard(title: 'Profit Trend (30 days)', child: TrendLineChart(data: data['profit_trend_30d'] ?? [], color: AppColors.success)),

              const SizedBox(height: 16),
              _ChartCard(
                title: 'Branch Performance',
                child: BranchBarChart(branches: data['branch_performance'] ?? []),
              ),

              const SizedBox(height: 16),
              _TopProductsCard(products: data['top_products_30d'] ?? []),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  final List<dynamic> products;
  const _TopProductsCard({required this.products});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: Text('Top Products (30 days)', style: theme.textTheme.titleSmall)),
          if (products.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: EmptyStateView(message: 'No sales data yet'))
          else
            ...products.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.accent.withOpacity(0.12),
                  child: Text('${i + 1}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                title: Text(p['name'], style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                subtitle: Text('${p['quantity']} units sold'),
                trailing: Text(_currencyFmt(p['revenue']), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              );
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

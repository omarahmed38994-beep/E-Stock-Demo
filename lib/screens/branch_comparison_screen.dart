import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../widgets/state_views.dart';
import '../widgets/trend_chart.dart';

class BranchComparisonScreen extends ConsumerWidget {
  const BranchComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(branchCompareProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Branch Comparison')),
      body: async.when(
        loading: () => const DashboardSkeleton(),
        error: (e, _) => ErrorStateView(message: e.toString(), onRetry: () => ref.invalidate(branchCompareProvider)),
        data: (d) {
          final branches = d['branches'] as List;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Company average: EGP ${(d['company_average_sales'] as num).toStringAsFixed(0)} / 30 days', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
                ),
                child: BranchBarChart(branches: branches),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

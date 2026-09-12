import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/state_views.dart';

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  IconData _iconFor(String type) {
    switch (type) {
      case 'reorder':
        return Icons.shopping_cart_checkout_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      case 'reduce_purchasing':
        return Icons.trending_down_rounded;
      default:
        return Icons.lightbulb_rounded;
    }
  }

  Color _colorFor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.critical;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recommendationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(refreshTickProvider.notifier).state++,
        child: async.when(
          loading: () => const DashboardSkeleton(),
          error: (e, _) => ErrorStateView(message: e.toString(), onRetry: () => ref.invalidate(recommendationsProvider)),
          data: (recs) {
            if (recs.isEmpty) return const EmptyStateView(message: 'No recommendations right now — everything looks well balanced.', icon: Icons.lightbulb_outline_rounded);
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: recs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = recs[i];
                final color = _colorFor(r['priority']);
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(_iconFor(r['type']), color: color, size: 18)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['title'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                            const SizedBox(height: 4),
                            Text(r['description'], style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
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

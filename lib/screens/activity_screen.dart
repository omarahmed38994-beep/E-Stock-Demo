import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/state_views.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activityProvider(null));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Timeline')),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(refreshTickProvider.notifier).state++,
        child: async.when(
          loading: () => const DashboardSkeleton(),
          error: (e, _) => ErrorStateView(message: e.toString(), onRetry: () => ref.invalidate(activityProvider(null))),
          data: (d) {
            final items = d['items'] as List;
            if (items.isEmpty) return const EmptyStateView(message: 'No activity recorded yet', icon: Icons.history_rounded);

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final a = items[i];
                DateTime? ts;
                try {
                  ts = DateTime.parse(a['created_at']);
                } catch (_) {}
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 52,
                        child: Text(ts != null ? DateFormat('HH:mm').format(ts) : '', style: theme.textTheme.bodySmall),
                      ),
                      Column(
                        children: [
                          Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                          if (i != items.length - 1) Expanded(child: Container(width: 1, color: theme.dividerTheme.color)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a['description'], style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                              if (a['branch_name'] != null) Text(a['branch_name'], style: theme.textTheme.bodySmall),
                            ],
                          ),
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

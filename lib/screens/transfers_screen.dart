import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../providers/auth_provider.dart';
import '../services/misc_services.dart';
import '../theme/app_colors.dart';
import '../widgets/state_views.dart';

class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transfersProvider(null));
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final canApprove = user?.canApproveTransfers ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Transfers')),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(refreshTickProvider.notifier).state++,
        child: async.when(
          loading: () => const DashboardSkeleton(),
          error: (e, _) => ErrorStateView(message: e.toString(), onRetry: () => ref.invalidate(transfersProvider(null))),
          data: (transfers) {
            if (transfers.isEmpty) return const EmptyStateView(message: 'No transfers yet', icon: Icons.swap_horiz_rounded);
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: transfers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final t = transfers[i];
                final status = t['status'] as String;
                final color = status == 'Pending' ? AppColors.warning : (status == 'Completed' ? AppColors.success : AppColors.critical);
                final items = t['items'] as List;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text('${t['from_branch']} → ${t['to_branch']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                          child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      ...items.map((it) => Text('• ${it['product']} × ${it['quantity']}', style: theme.textTheme.bodySmall)),
                      if (status == 'Pending' && canApprove) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await TransferService().reject(t['id']);
                                  ref.read(refreshTickProvider.notifier).state++;
                                },
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.critical),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await TransferService().approve(t['id']);
                                  ref.read(refreshTickProvider.notifier).state++;
                                },
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                      ],
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

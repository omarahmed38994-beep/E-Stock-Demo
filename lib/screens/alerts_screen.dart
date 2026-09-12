import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../services/misc_services.dart';
import '../theme/app_colors.dart';
import '../widgets/state_views.dart';
import '../widgets/chips_and_badges.dart';
import '../models/alert.dart';

final _alertFilterProvider = StateProvider<String>((ref) => 'All'); // All, Critical, Warnings, Information, Read, Unread

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(alertsProvider);
    final filter = ref.watch(_alertFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Center')),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(refreshTickProvider.notifier).state++,
        child: async.when(
          loading: () => const DashboardSkeleton(),
          error: (e, _) => ErrorStateView(message: e.toString(), onRetry: () => ref.invalidate(alertsProvider)),
          data: (alerts) {
            List<AlertItem> filtered = alerts;
            switch (filter) {
              case 'Critical':
                filtered = alerts.where((a) => a.severity == 'critical').toList();
                break;
              case 'Warnings':
                filtered = alerts.where((a) => a.severity == 'warning').toList();
                break;
              case 'Information':
                filtered = alerts.where((a) => a.severity == 'info').toList();
                break;
              case 'Read':
                filtered = alerts.where((a) => a.isRead).toList();
                break;
              case 'Unread':
                filtered = alerts.where((a) => !a.isRead).toList();
                break;
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['All', 'Critical', 'Warnings', 'Information', 'Unread', 'Read'].map((f) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => ref.read(_alertFilterProvider.notifier).state = f,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: filter == f ? AppColors.accent : Colors.transparent,
                                border: Border.all(color: filter == f ? AppColors.accent : Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(f, style: TextStyle(fontSize: 12.5, color: filter == f ? Colors.white : null, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const EmptyStateView(message: 'No notifications in this filter', icon: Icons.notifications_off_outlined)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final a = filtered[i];
                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                if (!a.isRead) {
                                  await AlertService().markRead(a.id);
                                  ref.read(refreshTickProvider.notifier).state++;
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: a.isRead ? theme.cardTheme.color : AppColors.severityColor(a.severity).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!a.isRead)
                                      Container(margin: const EdgeInsets.only(top: 5, right: 8), width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Expanded(child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
                                            SeverityChip(severity: a.severity),
                                          ]),
                                          const SizedBox(height: 4),
                                          Text(a.message, style: theme.textTheme.bodySmall),
                                          if (a.recommendedAction != null) ...[
                                            const SizedBox(height: 4),
                                            Text('→ ${a.recommendedAction}', style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w500)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

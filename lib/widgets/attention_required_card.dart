import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The dashboard's most important section: tells the manager exactly what
/// needs action right now, ranked by severity.
class AttentionRequiredCard extends StatelessWidget {
  final List<dynamic> items;
  const AttentionRequiredCard({super.key, required this.items});

  IconData _iconFor(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.error_rounded;
      case 'warning':
        return Icons.warning_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withOpacity(0.25)),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(child: Text('Everything looks healthy — no urgent action needed right now.', style: theme.textTheme.bodyMedium)),
        ]),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(children: [
              const Icon(Icons.notifications_active_rounded, color: AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Text('Attention Required', style: theme.textTheme.titleMedium),
            ]),
          ),
          const Divider(height: 1),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final a = entry.value as Map;
            final color = AppColors.severityColor(a['severity'] as String);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_iconFor(a['severity'] as String), color: color, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a['title'] as String, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text(a['message'] as String, style: theme.textTheme.bodySmall),
                            if (a['recommended_action'] != null) ...[
                              const SizedBox(height: 4),
                              Text('→ ${a['recommended_action']}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w500)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (i != items.length - 1) const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }
}

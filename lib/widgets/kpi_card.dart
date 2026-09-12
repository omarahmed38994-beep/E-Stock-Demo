import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A compact metric card used across the dashboard and analytics screens.
/// Keeps every KPI visually consistent: icon, label, value, optional trend.
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final double? trendPct;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.trendPct,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? AppColors.accent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 18, color: color),
                ),
                if (trendPct != null) _TrendBadge(pct: trendPct!),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final double pct;
  const _TrendBadge({required this.pct});

  @override
  Widget build(BuildContext context) {
    final positive = pct >= 0;
    final color = positive ? AppColors.success : AppColors.critical;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 11, color: color),
          const SizedBox(width: 2),
          Text('${pct.abs().toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

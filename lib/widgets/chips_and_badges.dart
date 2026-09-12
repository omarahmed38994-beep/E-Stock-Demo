import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SeverityChip extends StatelessWidget {
  final String severity;
  const SeverityChip({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(
        severity[0].toUpperCase() + severity.substring(1),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color _colorFor(String s) {
    switch (s) {
      case 'Critical':
        return AppColors.critical;
      case 'Low Stock':
        return AppColors.warning;
      case 'Expiring':
        return AppColors.warning;
      case 'Overstock':
        return AppColors.info;
      case 'Dead Stock':
        return Colors.grey;
      case 'Fast Moving':
        return AppColors.success;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

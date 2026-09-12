import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// Skeleton loader used instead of blank screens/spinners while data loads.
class SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  const SkeletonBox({super.key, required this.height, this.width, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1F2730) : const Color(0xFFEDEFF3),
      highlightColor: isDark ? const Color(0xFF2A333F) : const Color(0xFFF7F8FA),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SkeletonBox(height: 90),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: SkeletonBox(height: 110)),
          const SizedBox(width: 12),
          Expanded(child: SkeletonBox(height: 110)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: SkeletonBox(height: 110)),
          const SizedBox(width: 12),
          Expanded(child: SkeletonBox(height: 110)),
        ]),
        const SizedBox(height: 20),
        const SkeletonBox(height: 220),
        const SizedBox(height: 20),
        const SkeletonBox(height: 180),
      ],
    );
  }
}

/// Friendly error state — never shows raw stack traces to the user.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorStateView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.critical.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded, color: AppColors.critical, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Something went wrong', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyStateView({super.key, required this.message, this.icon = Icons.inbox_rounded});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 12),
            Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

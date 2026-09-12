import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import 'analytics_screen.dart';
import 'transfers_screen.dart';
import 'activity_screen.dart';
import 'recommendations_screen.dart';
import 'assistant_screen.dart';
import 'products_screen.dart';
import 'export_screen.dart';
import 'login_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final themeMode = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accentDark]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 24, backgroundColor: Colors.white.withOpacity(0.2), child: Text(user?.name.substring(0, 1) ?? '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(user?.role ?? '', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _SectionLabel('Business Tools'),
          _MenuTile(icon: Icons.inventory_2_rounded, label: 'Products', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()))),
          _MenuTile(icon: Icons.query_stats_rounded, label: 'Analytics', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
          _MenuTile(icon: Icons.lightbulb_outline_rounded, label: 'Recommendations', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecommendationsScreen()))),
          _MenuTile(icon: Icons.swap_horiz_rounded, label: 'Stock Transfers', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransfersScreen()))),
          if (user?.canSeeActivityAudit ?? false)
            _MenuTile(icon: Icons.history_rounded, label: 'Activity Timeline', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen()))),
          _MenuTile(icon: Icons.smart_toy_outlined, label: 'Ask your business', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssistantScreen()))),
          if (user?.canSeeFinancials ?? false)
            _MenuTile(icon: Icons.file_download_rounded, label: 'Export Reports', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportScreen()))),

          const SizedBox(height: 20),
          _SectionLabel('Preferences'),
          Container(
            decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200)),
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_rounded, color: AppColors.accent),
              title: const Text('Dark Mode'),
              value: themeMode == ThemeMode.dark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
            ),
          ),

          const SizedBox(height: 20),
          _SectionLabel('Account'),
          Container(
            decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200)),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.critical),
              title: const Text('Log Out', style: TextStyle(color: AppColors.critical)),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
              },
            ),
          ),
          const SizedBox(height: 20),
          Center(child: Text('StockVision v1.0.0 — Demo', style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5)),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.accent),
        title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }
}

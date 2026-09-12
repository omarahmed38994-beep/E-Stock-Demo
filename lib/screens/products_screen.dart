import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/state_views.dart';
import 'product_detail_screen.dart';

final _productSearchProvider = StateProvider<String>((ref) => '');

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(_productSearchProvider);
    final async = ref.watch(productsProvider(search));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search products or SKU...', prefixIcon: Icon(Icons.search_rounded, size: 20)),
              onChanged: (v) => ref.read(_productSearchProvider.notifier).state = v,
            ),
          ),
        ),
      ),
      body: async.when(
        loading: () => const DashboardSkeleton(),
        error: (e, _) => ErrorStateView(message: e.toString(), onRetry: () => ref.invalidate(productsProvider(search))),
        data: (d) {
          final items = d['items'] as List;
          if (items.isEmpty) return const EmptyStateView(message: 'No products found');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = items[i];
              return Container(
                decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200)),
                child: ListTile(
                  title: Text(p['name'], style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: Text('${p['sku']} · ${p['category']} · ${p['total_stock']} in stock'),
                  trailing: Text('EGP ${(p['selling_price'] as num).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.accent)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p['id']))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

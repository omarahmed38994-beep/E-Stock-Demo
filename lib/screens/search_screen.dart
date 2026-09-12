import 'package:flutter/material.dart';
import '../services/misc_services.dart';
import '../theme/app_colors.dart';
import '../widgets/state_views.dart';
import 'product_detail_screen.dart';
import 'branch_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final SearchService _service = SearchService();
  Map<String, dynamic>? _results;
  bool _loading = false;

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = null);
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await _service.search(q);
      setState(() => _results = r);
    } catch (_) {
      setState(() => _results = null);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search products, branches, customers...', border: InputBorder.none),
          onChanged: _search,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results == null
              ? const EmptyStateView(message: 'Search across products, branches, customers, and suppliers', icon: Icons.search_rounded)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if ((_results!['branches'] as List).isNotEmpty) ...[
                      Text('Branches', style: theme.textTheme.titleSmall),
                      ...(_results!['branches'] as List).map((b) => ListTile(
                            leading: const Icon(Icons.store_rounded, color: AppColors.primary),
                            title: Text(b['name']),
                            subtitle: Text(b['code']),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BranchDetailScreen(branchId: b['id'], branchName: b['name']))),
                          )),
                      const Divider(),
                    ],
                    if ((_results!['products'] as List).isNotEmpty) ...[
                      Text('Products', style: theme.textTheme.titleSmall),
                      ...(_results!['products'] as List).map((p) => ListTile(
                            leading: const Icon(Icons.inventory_2_rounded, color: AppColors.accent),
                            title: Text(p['name']),
                            subtitle: Text(p['sku']),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p['id']))),
                          )),
                      const Divider(),
                    ],
                    if ((_results!['customers'] as List).isNotEmpty) ...[
                      Text('Customers', style: theme.textTheme.titleSmall),
                      ...(_results!['customers'] as List).map((c) => ListTile(leading: const Icon(Icons.person_rounded), title: Text(c['name']), subtitle: Text(c['phone'] ?? ''))),
                      const Divider(),
                    ],
                    if ((_results!['suppliers'] as List).isNotEmpty) ...[
                      Text('Suppliers', style: theme.textTheme.titleSmall),
                      ...(_results!['suppliers'] as List).map((s) => ListTile(leading: const Icon(Icons.local_shipping_rounded), title: Text(s['name']))),
                    ],
                    if ((_results!['branches'] as List).isEmpty &&
                        (_results!['products'] as List).isEmpty &&
                        (_results!['customers'] as List).isEmpty &&
                        (_results!['suppliers'] as List).isEmpty)
                      const Padding(padding: EdgeInsets.only(top: 60), child: EmptyStateView(message: 'No results found')),
                  ],
                ),
    );
  }
}

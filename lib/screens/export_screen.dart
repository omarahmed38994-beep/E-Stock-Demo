import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../theme/app_colors.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _loading = false;
  String? _message;

  Future<void> _export(int days) async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final dio = ApiClient().dio;
      final resp = await dio.get('/export/sales-csv', queryParameters: {'period_days': days});
      final rowCount = (resp.data as String).split('\n').length - 1;
      setState(() => _message = 'Export ready: $rowCount rows generated for the last $days days.\n(In the desktop/mobile build, this would save to your downloads folder or open a share sheet.)');
    } catch (e) {
      setState(() => _message = 'Export failed. Please check your connection and try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Export Reports')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export your sales data as CSV for the selected period.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [7, 30, 90, 365].map((d) {
                return ElevatedButton.icon(
                  onPressed: _loading ? null : () => _export(d),
                  icon: const Icon(Icons.file_download_rounded, size: 18),
                  label: Text(d == 365 ? '12 Months' : '$d Days'),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success.withOpacity(0.25))),
                child: Text(_message!, style: theme.textTheme.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }
}

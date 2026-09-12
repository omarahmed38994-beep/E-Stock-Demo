import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';

/// Reusable trend line chart for sales/profit series (list of {date, value}).
class TrendLineChart extends StatelessWidget {
  final List<dynamic> data; // [{date: '2026-01-01', value: 1234.5}, ...]
  final Color color;
  final double height;

  const TrendLineChart({super.key, required this.data, this.color = AppColors.accent, this.height = 180});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(height: height, child: const Center(child: Text('No data for this period')));
    }
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      final v = (data[i]['value'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), v));
    }
    final maxY = spots.map((s) => s.y).fold<double>(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY == 0 ? 10 : maxY * 1.2,
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY == 0 ? 2 : maxY / 4),
          titlesData: const FlTitlesData(
            show: true,
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: color.withOpacity(0.12)),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.black87,
              getTooltipItems: (spots) => spots.map((s) {
                return LineTooltipItem(s.y.toStringAsFixed(0), const TextStyle(color: Colors.white, fontSize: 12));
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple horizontal bar comparison chart (e.g. branch performance).
class BranchBarChart extends StatelessWidget {
  final List<dynamic> branches; // BranchPerformance-like maps with name/sales
  const BranchBarChart({super.key, required this.branches});

  @override
  Widget build(BuildContext context) {
    if (branches.isEmpty) return const SizedBox(height: 180, child: Center(child: Text('No data')));
    final maxSales = branches.map((b) => (b['sales'] as num).toDouble()).fold<double>(0, (a, b) => a > b ? a : b);

    return Column(
      children: branches.map<Widget>((b) {
        final sales = (b['sales'] as num).toDouble();
        final pct = maxSales == 0 ? 0.0 : sales / maxSales;
        final growth = (b['growth_pct'] as num).toDouble();
        final color = growth >= 0 ? AppColors.success : AppColors.critical;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(b['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  Text('EGP ${sales.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.02, 1.0),
                  minHeight: 8,
                  backgroundColor: color.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

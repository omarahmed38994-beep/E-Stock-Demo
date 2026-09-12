class BranchPerformance {
  final int id;
  final String name;
  final String code;
  final String type;
  final String status;
  final double sales;
  final double profit;
  final int orders;
  final double growthPct;
  final double inventoryValue;
  final int lowStockCount;

  BranchPerformance({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.status,
    required this.sales,
    required this.profit,
    required this.orders,
    required this.growthPct,
    required this.inventoryValue,
    required this.lowStockCount,
  });

  factory BranchPerformance.fromJson(Map<String, dynamic> json) => BranchPerformance(
        id: json['id'],
        name: json['name'],
        code: json['code'],
        type: json['type'],
        status: json['status'],
        sales: (json['sales'] as num).toDouble(),
        profit: (json['profit'] as num).toDouble(),
        orders: json['orders'],
        growthPct: (json['growth_pct'] as num).toDouble(),
        inventoryValue: (json['inventory_value'] as num).toDouble(),
        lowStockCount: json['low_stock_count'],
      );
}

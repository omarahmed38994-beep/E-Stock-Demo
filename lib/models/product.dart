class ProductSummary {
  final int id;
  final String sku;
  final String? barcode;
  final String name;
  final String category;
  final double purchasePrice;
  final double sellingPrice;
  final double profitPerUnit;
  final int minimumStock;
  final int reorderLevel;
  final String status;
  final int totalStock;

  ProductSummary({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.profitPerUnit,
    required this.minimumStock,
    required this.reorderLevel,
    required this.status,
    required this.totalStock,
    this.barcode,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) => ProductSummary(
        id: json['id'],
        sku: json['sku'],
        barcode: json['barcode'],
        name: json['name'],
        category: json['category'] ?? '',
        purchasePrice: (json['purchase_price'] as num).toDouble(),
        sellingPrice: (json['selling_price'] as num).toDouble(),
        profitPerUnit: (json['profit_per_unit'] as num).toDouble(),
        minimumStock: json['minimum_stock'],
        reorderLevel: json['reorder_level'],
        status: json['status'],
        totalStock: json['total_stock'] ?? 0,
      );
}

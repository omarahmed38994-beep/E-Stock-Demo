class InventoryItem {
  final int inventoryId;
  final String branch;
  final String product;
  final int quantity;
  final double dailyVelocity;
  final double? daysOfStockLeft;
  final String status;
  final double inventoryValue;

  InventoryItem({
    required this.inventoryId,
    required this.branch,
    required this.product,
    required this.quantity,
    required this.dailyVelocity,
    required this.status,
    required this.inventoryValue,
    this.daysOfStockLeft,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        inventoryId: json['inventory_id'],
        branch: json['branch'],
        product: json['product'],
        quantity: json['quantity'],
        dailyVelocity: (json['daily_velocity'] as num).toDouble(),
        daysOfStockLeft: json['days_of_stock_left'] != null ? (json['days_of_stock_left'] as num).toDouble() : null,
        status: json['status'],
        inventoryValue: (json['inventory_value'] as num).toDouble(),
      );
}

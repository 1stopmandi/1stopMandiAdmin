class InventoryItem {
  final String? id;
  final String productId;
  final String? productName;
  final String? productUnit;
  final double purchasedQty;
  final double goodStock;
  final double recoverable;
  final double finalWaste;
  final String unit;
  final int sortOrder;
  final String? notes;

  const InventoryItem({
    this.id,
    required this.productId,
    this.productName,
    this.productUnit,
    required this.purchasedQty,
    required this.goodStock,
    required this.recoverable,
    required this.finalWaste,
    this.unit = 'kg',
    this.sortOrder = 0,
    this.notes,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String?,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String?,
      productUnit: json['product_unit'] as String?,
      purchasedQty: _toDouble(json['purchased_qty']),
      goodStock: _toDouble(json['good_stock']),
      recoverable: _toDouble(json['recoverable']),
      finalWaste: _toDouble(json['final_waste']),
      unit: (json['unit'] as String?) ?? 'kg',
      sortOrder: _toInt(json['sort_order']),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'purchased_qty': purchasedQty,
        'good_stock': goodStock,
        'recoverable': recoverable,
        'final_waste': finalWaste,
        'unit': unit,
        if (notes != null) 'notes': notes,
      };

  bool get isBalanced {
    final sum = goodStock + recoverable + finalWaste;
    return (purchasedQty - sum).abs() < 0.01;
  }

  double get balanceDifference => purchasedQty - (goodStock + recoverable + finalWaste);
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

class DamageItem {
  final String? id;
  final String productId;
  final String? productName;
  final String? productUnit;
  final String damageBy;
  final double damageQty;
  final double recoverQty;
  final double wasteQty;
  final String? notes;

  const DamageItem({
    this.id,
    required this.productId,
    this.productName,
    this.productUnit,
    required this.damageBy,
    required this.damageQty,
    required this.recoverQty,
    required this.wasteQty,
    this.notes,
  });

  factory DamageItem.fromJson(Map<String, dynamic> json) => DamageItem(
        id: json['id'] as String?,
        productId: json['product_id'] as String,
        productName: json['product_name'] as String?,
        productUnit: json['product_unit'] as String?,
        damageBy: json['damage_by'] as String? ?? 'om',
        damageQty: _toDouble(json['damage_qty']),
        recoverQty: _toDouble(json['recover_qty']),
        wasteQty: _toDouble(json['waste_qty']),
        notes: json['notes'] as String?,
      );
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

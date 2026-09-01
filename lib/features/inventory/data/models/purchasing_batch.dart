class PurchasingItem {
  final String? id;
  final String productId;
  final String? productName;
  final String? productUnit;
  final double weight;
  final double rate;
  final double amount;
  final double labourCharge;
  final String? notes;

  const PurchasingItem({
    this.id,
    required this.productId,
    this.productName,
    this.productUnit,
    required this.weight,
    required this.rate,
    required this.amount,
    required this.labourCharge,
    this.notes,
  });

  factory PurchasingItem.fromJson(Map<String, dynamic> json) => PurchasingItem(
        id: json['id'] as String?,
        productId: json['product_id'] as String,
        productName: json['product_name'] as String?,
        productUnit: json['product_unit'] as String?,
        weight: _toDouble(json['weight']),
        rate: _toDouble(json['rate']),
        amount: _toDouble(json['amount']),
        labourCharge: _toDouble(json['labour_charge']),
        notes: json['notes'] as String?,
      );
}

class PurchasingBatch {
  final String? id;
  final String purchaseSource;
  final double transportationCharge;
  final double otherCharges;
  final String? notes;
  final List<PurchasingItem> items;
  final double totalAmount;
  final double totalLabourCharge;
  final double grandTotal;

  const PurchasingBatch({
    this.id,
    required this.purchaseSource,
    required this.transportationCharge,
    required this.otherCharges,
    this.notes,
    this.items = const [],
    required this.totalAmount,
    required this.totalLabourCharge,
    required this.grandTotal,
  });

  factory PurchasingBatch.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((item) => PurchasingItem.fromJson(item as Map<String, dynamic>))
        .toList();
    final itemAmount = items.fold<double>(0, (sum, item) => sum + item.amount);
    final labour =
        items.fold<double>(0, (sum, item) => sum + item.labourCharge);
    final transportation = _toDouble(json['transportation_charge']);
    final other = _toDouble(json['other_charges']);
    return PurchasingBatch(
      id: json['id'] as String?,
      purchaseSource: json['purchase_source'] as String? ?? 'om',
      transportationCharge: transportation,
      otherCharges: other,
      notes: json['notes'] as String?,
      items: items,
      totalAmount: json['total_amount'] == null
          ? itemAmount
          : _toDouble(json['total_amount']),
      totalLabourCharge: json['total_labour_charge'] == null
          ? labour
          : _toDouble(json['total_labour_charge']),
      grandTotal: json['grand_total'] == null
          ? itemAmount + labour + transportation + other
          : _toDouble(json['grand_total']),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

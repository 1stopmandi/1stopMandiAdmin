class DispatchItem {
  final String? id;
  final String productId;
  final String? productName;
  final String? productUnit;
  final String dispatchTo;
  final int pocket;
  final double weight;
  final double rate;
  final double amount;
  final String? notes;

  const DispatchItem({
    this.id,
    required this.productId,
    this.productName,
    this.productUnit,
    required this.dispatchTo,
    required this.pocket,
    required this.weight,
    required this.rate,
    required this.amount,
    this.notes,
  });

  factory DispatchItem.fromJson(Map<String, dynamic> json) => DispatchItem(
        id: json['id'] as String?,
        productId: json['product_id'] as String,
        productName: json['product_name'] as String?,
        productUnit: json['product_unit'] as String?,
        dispatchTo: json['dispatch_to'] as String,
        pocket: _toInt(json['pocket']),
        weight: _toDouble(json['weight']),
        rate: _toDouble(json['rate']),
        amount: _toDouble(json['amount']),
        notes: json['notes'] as String?,
      );

  String get dispatchToLabel => switch (dispatchTo) {
        'quicklo_part_2' => 'Quicklo Part 2',
        'quicklo_part_3' => 'Quicklo Part 3',
        'quicklo_part_1' => 'Quicklo Part 1',
        _ => dispatchTo,
      };
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

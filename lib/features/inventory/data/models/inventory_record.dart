import 'inventory_item.dart';

class InventoryRecord {
  final String id;
  final String title;
  final String recordDate;
  final String? purchasedById;
  final String? purchasedByName;
  final String status;
  final String? notes;
  final int itemCount;
  final double totalPurchasedQty;
  final double totalGoodStock;
  final double totalRecoverable;
  final double totalFinalWaste;
  final List<InventoryItem> items;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  const InventoryRecord({
    required this.id,
    required this.title,
    required this.recordDate,
    this.purchasedById,
    this.purchasedByName,
    required this.status,
    this.notes,
    required this.itemCount,
    required this.totalPurchasedQty,
    required this.totalGoodStock,
    required this.totalRecoverable,
    required this.totalFinalWaste,
    this.items = const [],
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory InventoryRecord.fromJson(Map<String, dynamic> json) {
    return InventoryRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      recordDate: json['record_date'] as String,
      purchasedById: json['purchased_by_id'] as String?,
      purchasedByName: json['purchased_by_name'] as String?,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      itemCount: _toInt(json['item_count']),
      totalPurchasedQty: _toDouble(json['total_purchased_qty']),
      totalGoodStock: _toDouble(json['total_good_stock']),
      totalRecoverable: _toDouble(json['total_recoverable']),
      totalFinalWaste: _toDouble(json['total_final_waste']),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  bool get isDraft => status == 'draft';
  bool get isFinalized => status == 'finalized';

  double get wastePercentage =>
      totalPurchasedQty > 0 ? (totalFinalWaste / totalPurchasedQty) * 100 : 0;

  double get goodStockPercentage =>
      totalPurchasedQty > 0 ? (totalGoodStock / totalPurchasedQty) * 100 : 0;
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

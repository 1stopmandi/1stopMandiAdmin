import 'damage_item.dart';
import 'dispatch_item.dart';
import 'purchasing_batch.dart';

class InventoryRecord {
  final String id;
  final String title;
  final String recordDate;
  final String status;
  final String? notes;
  final int purchasingBatchCount;
  final int purchasingItemCount;
  final int dispatchItemCount;
  final int damageItemCount;
  final double totalPurchasedWeight;
  final double totalPurchasingAmount;
  final double totalLabourCharge;
  final double totalTransportationCharge;
  final double totalOtherCharges;
  final double purchasingGrandTotal;
  final double totalDispatchWeight;
  final double totalDispatchAmount;
  final double totalDamageQty;
  final double totalRecoverQty;
  final double totalWasteQty;
  final List<PurchasingBatch> purchasingBatches;
  final List<DispatchItem> dispatchItems;
  final List<DamageItem> damageItems;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  const InventoryRecord({
    required this.id,
    required this.title,
    required this.recordDate,
    required this.status,
    this.notes,
    required this.purchasingBatchCount,
    required this.purchasingItemCount,
    required this.dispatchItemCount,
    required this.damageItemCount,
    required this.totalPurchasedWeight,
    required this.totalPurchasingAmount,
    required this.totalLabourCharge,
    required this.totalTransportationCharge,
    required this.totalOtherCharges,
    required this.purchasingGrandTotal,
    required this.totalDispatchWeight,
    required this.totalDispatchAmount,
    required this.totalDamageQty,
    required this.totalRecoverQty,
    required this.totalWasteQty,
    this.purchasingBatches = const [],
    this.dispatchItems = const [],
    this.damageItems = const [],
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory InventoryRecord.fromJson(Map<String, dynamic> json) {
    final batches = (json['purchasing_batches'] as List<dynamic>? ?? [])
        .map((item) => PurchasingBatch.fromJson(item as Map<String, dynamic>))
        .toList();
    final dispatchItems = (json['dispatch_items'] as List<dynamic>? ?? [])
        .map((item) => DispatchItem.fromJson(item as Map<String, dynamic>))
        .toList();
    final damageItems = (json['damage_items'] as List<dynamic>? ?? [])
        .map((item) => DamageItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return InventoryRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      recordDate: json['record_date'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      purchasingBatchCount:
          _toInt(json['purchasing_batch_count'] ?? batches.length),
      purchasingItemCount: _toInt(
        json['purchasing_item_count'] ??
            batches.fold<int>(0, (sum, batch) => sum + batch.items.length),
      ),
      dispatchItemCount:
          _toInt(json['dispatch_item_count'] ?? dispatchItems.length),
      damageItemCount: _toInt(json['damage_item_count'] ?? damageItems.length),
      totalPurchasedWeight: _toDouble(json['total_purchased_weight']),
      totalPurchasingAmount: _toDouble(json['total_purchasing_amount']),
      totalLabourCharge: _toDouble(json['total_labour_charge']),
      totalTransportationCharge: _toDouble(json['total_transportation_charge']),
      totalOtherCharges: _toDouble(json['total_other_charges']),
      purchasingGrandTotal: _toDouble(json['purchasing_grand_total']),
      totalDispatchWeight: _toDouble(json['total_dispatch_weight']),
      totalDispatchAmount: _toDouble(json['total_dispatch_amount']),
      totalDamageQty: _toDouble(json['total_damage_qty']),
      totalRecoverQty: _toDouble(json['total_recover_qty']),
      totalWasteQty: _toDouble(json['total_waste_qty']),
      purchasingBatches: batches,
      dispatchItems: dispatchItems,
      damageItems: damageItems,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  bool get isDraft => status == 'draft';
  bool get isFinalized => status == 'finalized';
  String get displayTitle => title.trim().isEmpty ? 'Untitled' : title;

  int get totalRowCount =>
      purchasingItemCount + dispatchItemCount + damageItemCount;
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

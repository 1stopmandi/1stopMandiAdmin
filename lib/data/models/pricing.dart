class PricingSlabInput {
  final double minQty;
  final double? maxQty;
  final double pricePerUnit;

  const PricingSlabInput({
    required this.minQty,
    this.maxQty,
    required this.pricePerUnit,
  });

  Map<String, dynamic> toJson() => {
        'min_qty': minQty,
        if (maxQty != null) 'max_qty': maxQty,
        'price_per_unit': pricePerUnit,
      };

  factory PricingSlabInput.fromJson(Map<String, dynamic> j) => PricingSlabInput(
        minQty: _toDouble(j['min_qty']),
        maxQty: j['max_qty'] == null ? null : _toDouble(j['max_qty']),
        pricePerUnit: _toDouble(j['price_per_unit']),
      );
}

class ProductPricingRow {
  final String id;
  final String name;
  final String slug;
  final String? categoryName;
  final double? basePrice;
  final int slabCount;

  const ProductPricingRow({
    required this.id,
    required this.name,
    required this.slug,
    this.categoryName,
    this.basePrice,
    required this.slabCount,
  });

  bool get hasPricing => basePrice != null;

  factory ProductPricingRow.fromJson(Map<String, dynamic> j) => ProductPricingRow(
        id: j['id'] as String,
        name: j['name'] as String,
        slug: j['slug'] as String,
        categoryName: j['category_name'] as String?,
        basePrice: j['base_price'] == null ? null : _toDouble(j['base_price']),
        slabCount: j['slab_count'] as int? ?? 0,
      );
}

class ProductPricingDetail {
  final String productId;
  final String? pricingId;
  final double? basePrice;
  final bool isActive;
  final List<PricingSlabInput> slabs;

  const ProductPricingDetail({
    required this.productId,
    this.pricingId,
    this.basePrice,
    required this.isActive,
    this.slabs = const [],
  });

  factory ProductPricingDetail.fromJson(Map<String, dynamic> j) {
    final active = j['is_active'] as bool? ?? true;
    if (j['pricing'] == null && j['base_price'] == null && j['id'] == null) {
      return ProductPricingDetail(
        productId: j['product_id'] as String,
        isActive: false,
      );
    }
    return ProductPricingDetail(
      productId: (j['product_id'] ?? j['productId']) as String,
      pricingId: j['id'] as String?,
      basePrice: j['base_price'] == null ? null : _toDouble(j['base_price']),
      isActive: active,
      slabs: (j['slabs'] as List<dynamic>? ?? [])
          .map((e) => PricingSlabInput.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PricingAuditEntry {
  final String id;
  final DateTime? changedAt;
  final String? changedByName;
  final String? changedByPhone;

  const PricingAuditEntry({
    required this.id,
    this.changedAt,
    this.changedByName,
    this.changedByPhone,
  });

  factory PricingAuditEntry.fromJson(Map<String, dynamic> j) => PricingAuditEntry(
        id: j['id'] as String,
        changedAt: _parseDate(j['changed_at']),
        changedByName: j['changed_by_name'] as String?,
        changedByPhone: j['changed_by_phone'] as String?,
      );
}

class BulkImportPreview {
  final String batchId;
  final int total;
  final int valid;
  final bool canConfirm;
  final List<Map<String, dynamic>> preview;
  final List<Map<String, dynamic>> errors;

  const BulkImportPreview({
    required this.batchId,
    required this.total,
    required this.valid,
    required this.canConfirm,
    required this.preview,
    required this.errors,
  });

  factory BulkImportPreview.fromJson(Map<String, dynamic> j) => BulkImportPreview(
        batchId: j['batch_id'] as String,
        total: j['total'] as int? ?? 0,
        valid: j['valid'] as int? ?? 0,
        canConfirm: j['can_confirm'] as bool? ?? false,
        preview: (j['preview'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        errors: (j['errors'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}

class BulkUpdateResult {
  final bool applied;
  final int updated;
  final List<Map<String, dynamic>> failed;

  const BulkUpdateResult({
    required this.applied,
    required this.updated,
    required this.failed,
  });

  factory BulkUpdateResult.fromJson(Map<String, dynamic> j) => BulkUpdateResult(
        applied: j['applied'] as bool? ?? false,
        updated: j['updated'] as int? ?? 0,
        failed: (j['failed'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

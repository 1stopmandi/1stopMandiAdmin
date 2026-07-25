class PricingSlab {
  final double minQty;
  final double? maxQty;
  final double pricePerUnit;
  final int sortOrder;

  const PricingSlab({
    required this.minQty,
    this.maxQty,
    required this.pricePerUnit,
    required this.sortOrder,
  });

  factory PricingSlab.fromJson(Map<String, dynamic> j) => PricingSlab(
        minQty: _toDouble(j['min_qty']),
        maxQty: j['max_qty'] == null ? null : _toDouble(j['max_qty']),
        pricePerUnit: _toDouble(j['price_per_unit']),
        sortOrder: j['sort_order'] as int? ?? 0,
      );
}

class ProductPricing {
  final double basePrice;
  final List<PricingSlab> slabs;

  const ProductPricing({
    required this.basePrice,
    this.slabs = const [],
  });

  factory ProductPricing.fromJson(Map<String, dynamic> j) => ProductPricing(
        basePrice: _toDouble(j['base_price']),
        slabs: (j['slabs'] as List<dynamic>? ?? [])
            .map((e) => PricingSlab.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ProductSummary {
  final String id;
  final String name;
  final String slug;
  final String unit;
  final String? imageUrl;
  final String? categoryId;
  final String? cityId;
  final double? moq;
  final double? stock;
  final bool isActive;
  final bool isVeg;
  final String? brand;
  final double? basePrice;
  final DateTime? createdAt;

  const ProductSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.unit,
    this.imageUrl,
    this.categoryId,
    this.cityId,
    this.moq,
    this.stock,
    required this.isActive,
    required this.isVeg,
    this.brand,
    this.basePrice,
    this.createdAt,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> j) => ProductSummary(
        id: j['id'] as String,
        name: j['name'] as String,
        slug: j['slug'] as String,
        unit: j['unit'] as String,
        imageUrl: j['image_url'] as String?,
        categoryId: j['category_id'] as String?,
        cityId: j['city_id'] as String?,
        moq: j['moq'] == null ? null : _toDouble(j['moq']),
        stock: j['stock'] == null ? null : _toDouble(j['stock']),
        isActive: j['is_active'] as bool? ?? true,
        isVeg: j['is_veg'] as bool? ?? false,
        brand: j['brand'] as String?,
        basePrice: j['base_price'] == null ? null : _toDouble(j['base_price']),
        createdAt: _parseDate(j['created_at']),
      );
}

class ProductDetail extends ProductSummary {
  final String? description;
  final ProductPricing? pricing;

  const ProductDetail({
    required super.id,
    required super.name,
    required super.slug,
    required super.unit,
    super.imageUrl,
    super.categoryId,
    super.cityId,
    super.moq,
    super.stock,
    required super.isActive,
    required super.isVeg,
    super.brand,
    super.basePrice,
    super.createdAt,
    this.description,
    this.pricing,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> j) => ProductDetail(
        id: j['id'] as String,
        name: j['name'] as String,
        slug: j['slug'] as String,
        unit: j['unit'] as String,
        imageUrl: j['image_url'] as String?,
        categoryId: j['category_id'] as String?,
        cityId: j['city_id'] as String?,
        moq: j['moq'] == null ? null : _toDouble(j['moq']),
        stock: j['stock'] == null ? null : _toDouble(j['stock']),
        isActive: j['is_active'] as bool? ?? true,
        isVeg: j['is_veg'] as bool? ?? false,
        brand: j['brand'] as String?,
        basePrice: j['base_price'] == null ? null : _toDouble(j['base_price']),
        createdAt: _parseDate(j['created_at']),
        description: j['description'] as String?,
        pricing: j['pricing'] != null
            ? ProductPricing.fromJson(j['pricing'] as Map<String, dynamic>)
            : null,
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

String slugify(String name) {
  return name
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

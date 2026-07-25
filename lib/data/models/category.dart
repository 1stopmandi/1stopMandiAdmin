class Category {
  final String id;
  final String name;
  final String slug;
  final int sortOrder;
  final String? cityId;
  final bool isActive;
  final int activeProductCount;
  final DateTime? createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.sortOrder,
    this.cityId,
    required this.isActive,
    required this.activeProductCount,
    this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        slug: j['slug'] as String,
        sortOrder: j['sort_order'] as int? ?? 0,
        cityId: j['city_id'] as String?,
        isActive: j['is_active'] as bool? ?? true,
        activeProductCount: j['active_product_count'] as int? ?? 0,
        createdAt: _parseDate(j['created_at']),
      );
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

String slugifyCategory(String name) {
  return name
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

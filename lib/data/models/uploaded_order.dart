class UploadedOrderSummary {
  final String id;
  final String userId;
  final String imageUrl;
  final String status;
  final DateTime? createdAt;
  final String? userPhone;
  final String? userName;

  const UploadedOrderSummary({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.status,
    this.createdAt,
    this.userPhone,
    this.userName,
  });

  String get buyerLabel =>
      userName?.trim().isNotEmpty == true
          ? userName!
          : (userPhone ?? 'Unknown buyer');

  factory UploadedOrderSummary.fromJson(Map<String, dynamic> j) =>
      UploadedOrderSummary(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        imageUrl: j['image_url'] as String? ?? '',
        status: j['status'] as String? ?? 'processing',
        createdAt: _parseDate(j['created_at']),
        userPhone: j['phone'] as String?,
        userName: j['name'] as String?,
      );
}

class UploadedOrderItem {
  final String? id;
  final String productId;
  final String productName;
  final String unit;
  final double quantity;
  final double? pricePerUnit;
  final bool pricingAvailable;

  const UploadedOrderItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    this.pricePerUnit,
    required this.pricingAvailable,
  });

  factory UploadedOrderItem.fromJson(Map<String, dynamic> j) => UploadedOrderItem(
        id: j['id'] as String?,
        productId: j['product_id'] as String? ?? '',
        productName: j['product_name'] as String? ?? '',
        unit: j['unit'] as String? ?? '',
        quantity: _toDouble(j['quantity']),
        pricePerUnit: j['price_per_unit'] == null
            ? null
            : _toDouble(j['price_per_unit']),
        pricingAvailable: j['pricing_available'] as bool? ?? false,
      );
}

class UploadedOrderDetail {
  final String id;
  final String userId;
  final String imageUrl;
  final String status;
  final String? notes;
  final DateTime? cartReadyAt;
  final DateTime? createdAt;
  final List<UploadedOrderItem> items;

  const UploadedOrderDetail({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.status,
    this.notes,
    this.cartReadyAt,
    this.createdAt,
    this.items = const [],
  });

  factory UploadedOrderDetail.fromJson(Map<String, dynamic> j) =>
      UploadedOrderDetail(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        imageUrl: j['image_url'] as String? ?? '',
        status: j['status'] as String? ?? 'processing',
        notes: j['notes'] as String?,
        cartReadyAt: _parseDate(j['cart_ready_at']),
        createdAt: _parseDate(j['created_at']),
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => UploadedOrderItem.fromJson(e as Map<String, dynamic>))
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

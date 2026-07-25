class OrderBuyer {
  final String id;
  final String? name;
  final String? phone;
  final String? email;
  final String? businessName;
  final String? address;
  final String? pincode;
  final String? gstNumber;
  final String? fssaiNumber;

  const OrderBuyer({
    required this.id,
    this.name,
    this.phone,
    this.email,
    this.businessName,
    this.address,
    this.pincode,
    this.gstNumber,
    this.fssaiNumber,
  });

  factory OrderBuyer.fromJson(Map<String, dynamic> j) => OrderBuyer(
        id: j['id'] as String? ?? '',
        name: j['name'] as String?,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        businessName: j['business_name'] as String?,
        address: j['address'] as String?,
        pincode: j['pincode'] as String?,
        gstNumber: j['gst_number'] as String?,
        fssaiNumber: j['fssai_number'] as String?,
      );
}

class OrderItem {
  final String? id;
  final String productId;
  final String productName;
  final String unit;
  final double priceApplied;
  final double quantity;
  final double lineTotal;
  final String? imageUrl;

  const OrderItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.priceApplied,
    required this.quantity,
    required this.lineTotal,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: j['id'] as String?,
        productId: j['product_id'] as String? ?? '',
        productName: j['product_name'] as String? ?? '',
        unit: j['unit'] as String? ?? '',
        priceApplied: _toDouble(j['price_applied']),
        quantity: _toDouble(j['quantity']),
        lineTotal: _toDouble(j['line_total']),
        imageUrl: j['image_url'] as String?,
      );
}

class Order {
  final String id;
  final String orderNumber;
  final String status;
  final String source;
  final double totalAmount;
  final String? deliveryAddress;
  final String? deliveryPincode;
  final DateTime? deliverBy;
  final DateTime? proposedDeliverBy;
  final String? extensionNote;
  final String? rejectionReason;
  final String paymentStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final OrderBuyer? user;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.source,
    required this.totalAmount,
    this.deliveryAddress,
    this.deliveryPincode,
    this.deliverBy,
    this.proposedDeliverBy,
    this.extensionNote,
    this.rejectionReason,
    required this.paymentStatus,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.items = const [],
  });

  bool get isPending => status == 'pending';
  bool get isExtensionRequested => status == 'extension_requested';
  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
  bool get isDelivered => status == 'delivered';

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as String,
        orderNumber: j['order_number'] as String? ?? '',
        status: j['status'] as String? ?? 'pending',
        source: j['source'] as String? ?? 'normal',
        totalAmount: _toDouble(j['total_amount']),
        deliveryAddress: j['delivery_address'] as String?,
        deliveryPincode: j['delivery_pincode'] as String?,
        deliverBy: _parseDate(j['deliver_by']),
        proposedDeliverBy: _parseDate(j['proposed_deliver_by']),
        extensionNote: j['extension_note'] as String?,
        rejectionReason: j['rejection_reason'] as String?,
        paymentStatus: j['payment_status'] as String? ?? 'unpaid',
        createdAt: _parseDate(j['created_at']),
        updatedAt: _parseDate(j['updated_at']),
        user: j['user'] != null
            ? OrderBuyer.fromJson(j['user'] as Map<String, dynamic>)
            : null,
        items: (j['items'] as List<dynamic>?)
                ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

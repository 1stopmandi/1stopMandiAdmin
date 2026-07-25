class ClientBillingSummary {
  final double totalBilled;
  final double totalPaid;
  final double outstanding;
  final int unpaidOrders;

  const ClientBillingSummary({
    required this.totalBilled,
    required this.totalPaid,
    required this.outstanding,
    required this.unpaidOrders,
  });

  factory ClientBillingSummary.fromJson(Map<String, dynamic> j) =>
      ClientBillingSummary(
        totalBilled: _toDouble(j['total_billed']),
        totalPaid: _toDouble(j['total_paid']),
        outstanding: _toDouble(j['outstanding']),
        unpaidOrders: j['unpaid_orders'] as int? ?? 0,
      );
}

class ClientBillingOrder {
  final String id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final double totalAmount;
  final DateTime? createdAt;
  final DateTime? paidAt;

  const ClientBillingOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    this.createdAt,
    this.paidAt,
  });

  bool get isUnpaid => paymentStatus == 'unpaid';

  factory ClientBillingOrder.fromJson(Map<String, dynamic> j) =>
      ClientBillingOrder(
        id: j['id'] as String,
        orderNumber: j['order_number'] as String? ?? '',
        status: j['status'] as String? ?? '',
        paymentStatus: j['payment_status'] as String? ?? '',
        totalAmount: _toDouble(j['total_amount']),
        createdAt: _parseDate(j['created_at']),
        paidAt: _parseDate(j['paid_at']),
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

class PlatformUserSummary {
  final String id;
  final String? phone;
  final String? name;
  final String role;
  final bool isSetupCompleted;
  final DateTime? createdAt;

  const PlatformUserSummary({
    required this.id,
    this.phone,
    this.name,
    required this.role,
    required this.isSetupCompleted,
    this.createdAt,
  });

  String get displayName =>
      name?.trim().isNotEmpty == true ? name! : (phone ?? id.substring(0, 8));

  factory PlatformUserSummary.fromJson(Map<String, dynamic> j) =>
      PlatformUserSummary(
        id: j['id'] as String,
        phone: j['phone'] as String?,
        name: j['name'] as String?,
        role: j['role'] as String? ?? 'buyer',
        isSetupCompleted: j['is_setup_completed'] as bool? ?? false,
        createdAt: _parseDate(j['created_at']),
      );
}

class PlatformUserDetail {
  final String id;
  final String? phone;
  final String? email;
  final String? name;
  final String role;
  final bool isSetupCompleted;
  final String? businessName;
  final bool isBlocked;
  final String? blockedReason;
  final DateTime? createdAt;

  const PlatformUserDetail({
    required this.id,
    this.phone,
    this.email,
    this.name,
    required this.role,
    required this.isSetupCompleted,
    this.businessName,
    required this.isBlocked,
    this.blockedReason,
    this.createdAt,
  });

  factory PlatformUserDetail.fromJson(Map<String, dynamic> j) =>
      PlatformUserDetail(
        id: j['id'] as String,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        name: j['name'] as String?,
        role: j['role'] as String? ?? 'buyer',
        isSetupCompleted: j['is_setup_completed'] as bool? ?? false,
        businessName: j['business_name'] as String?,
        isBlocked: j['is_blocked'] as bool? ?? false,
        blockedReason: j['blocked_reason'] as String?,
        createdAt: _parseDate(j['created_at']),
      );
}

class PlatformUserOrder {
  final String id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final DateTime? createdAt;

  const PlatformUserOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    this.createdAt,
  });

  factory PlatformUserOrder.fromJson(Map<String, dynamic> j) =>
      PlatformUserOrder(
        id: j['id'] as String,
        orderNumber: j['order_number'] as String? ?? '',
        status: j['status'] as String? ?? '',
        totalAmount: _toDouble(j['total_amount']),
        createdAt: _parseDate(j['created_at']),
      );
}

class UsersStats {
  final int totalUsers;
  final int setupCompleted;
  final int totalAdmins;
  final int blockedUsers;
  final int newThisWeek;
  final int totalOrders;
  final int pendingOrders;

  const UsersStats({
    required this.totalUsers,
    required this.setupCompleted,
    required this.totalAdmins,
    required this.blockedUsers,
    required this.newThisWeek,
    required this.totalOrders,
    required this.pendingOrders,
  });

  factory UsersStats.fromJson(Map<String, dynamic> j) {
    final users = j['users'] as Map<String, dynamic>? ?? {};
    final orders = j['orders'] as Map<String, dynamic>? ?? {};
    return UsersStats(
      totalUsers: users['total_users'] as int? ?? 0,
      setupCompleted: users['setup_completed'] as int? ?? 0,
      totalAdmins: users['total_admins'] as int? ?? 0,
      blockedUsers: users['blocked_users'] as int? ?? 0,
      newThisWeek: users['new_this_week'] as int? ?? 0,
      totalOrders: orders['total_orders'] as int? ?? 0,
      pendingOrders: orders['pending_orders'] as int? ?? 0,
    );
  }
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

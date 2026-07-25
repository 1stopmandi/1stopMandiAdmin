class ClientSummary {
  final String id;
  final String? phone;
  final String? name;
  final String? businessName;
  final String? outletType;
  final String? cityId;
  final bool isSetupCompleted;
  final String setupApprovalStatus;
  final String accountStatus;
  final bool isBlocked;
  final double outstandingBalance;
  final DateTime? createdAt;

  const ClientSummary({
    required this.id,
    this.phone,
    this.name,
    this.businessName,
    this.outletType,
    this.cityId,
    required this.isSetupCompleted,
    required this.setupApprovalStatus,
    required this.accountStatus,
    required this.isBlocked,
    required this.outstandingBalance,
    this.createdAt,
  });

  String get displayName =>
      businessName?.trim().isNotEmpty == true
          ? businessName!
          : (name?.trim().isNotEmpty == true ? name! : phone ?? 'Unknown');

  factory ClientSummary.fromJson(Map<String, dynamic> j) => ClientSummary(
        id: j['id'] as String,
        phone: j['phone'] as String?,
        name: j['name'] as String?,
        businessName: j['business_name'] as String?,
        outletType: j['outlet_type'] as String?,
        cityId: j['city_id'] as String?,
        isSetupCompleted: j['is_setup_completed'] as bool? ?? false,
        setupApprovalStatus:
            j['setup_approval_status'] as String? ?? 'pending',
        accountStatus: j['account_status'] as String? ?? 'active',
        isBlocked: j['is_blocked'] as bool? ?? false,
        outstandingBalance: _toDouble(j['outstanding_balance']),
        createdAt: _parseDate(j['created_at']),
      );
}

class ClientDetail {
  final String id;
  final String? phone;
  final String? email;
  final String? name;
  final String role;
  final bool isSetupCompleted;
  final int? setupStep;
  final String? businessName;
  final String? ownerName;
  final String? alternateContact;
  final String? address;
  final String? pincode;
  final String? cityId;
  final String? outletType;
  final String? dailyOrderVolume;
  final String? gstNumber;
  final String? fssaiNumber;
  final String? gstCertUrl;
  final String? fssaiCertUrl;
  final String? outletImageUrl;
  final bool isBlocked;
  final String? blockedReason;
  final String accountStatus;
  final String setupApprovalStatus;
  final String? setupAdminNote;
  final DateTime? setupReviewedAt;
  final bool createdByAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClientDetail({
    required this.id,
    this.phone,
    this.email,
    this.name,
    required this.role,
    required this.isSetupCompleted,
    this.setupStep,
    this.businessName,
    this.ownerName,
    this.alternateContact,
    this.address,
    this.pincode,
    this.cityId,
    this.outletType,
    this.dailyOrderVolume,
    this.gstNumber,
    this.fssaiNumber,
    this.gstCertUrl,
    this.fssaiCertUrl,
    this.outletImageUrl,
    required this.isBlocked,
    this.blockedReason,
    required this.accountStatus,
    required this.setupApprovalStatus,
    this.setupAdminNote,
    this.setupReviewedAt,
    required this.createdByAdmin,
    this.createdAt,
    this.updatedAt,
  });

  String get displayName =>
      businessName?.trim().isNotEmpty == true
          ? businessName!
          : (name?.trim().isNotEmpty == true ? name! : phone ?? 'Unknown');

  factory ClientDetail.fromJson(Map<String, dynamic> j) => ClientDetail(
        id: j['id'] as String,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        name: j['name'] as String?,
        role: j['role'] as String? ?? 'buyer',
        isSetupCompleted: j['is_setup_completed'] as bool? ?? false,
        setupStep: j['setup_step'] as int?,
        businessName: j['business_name'] as String?,
        ownerName: j['owner_name'] as String?,
        alternateContact: j['alternate_contact'] as String?,
        address: j['address'] as String?,
        pincode: j['pincode'] as String?,
        cityId: j['city_id'] as String?,
        outletType: j['outlet_type'] as String?,
        dailyOrderVolume: j['daily_order_volume'] as String?,
        gstNumber: j['gst_number'] as String?,
        fssaiNumber: j['fssai_number'] as String?,
        gstCertUrl: j['gst_cert_url'] as String?,
        fssaiCertUrl: j['fssai_cert_url'] as String?,
        outletImageUrl: j['outlet_image_url'] as String?,
        isBlocked: j['is_blocked'] as bool? ?? false,
        blockedReason: j['blocked_reason'] as String?,
        accountStatus: j['account_status'] as String? ?? 'active',
        setupApprovalStatus:
            j['setup_approval_status'] as String? ?? 'pending',
        setupAdminNote: j['setup_admin_note'] as String?,
        setupReviewedAt: _parseDate(j['setup_reviewed_at']),
        createdByAdmin: j['created_by_admin'] != null,
        createdAt: _parseDate(j['created_at']),
        updatedAt: _parseDate(j['updated_at']),
      );

  Map<String, dynamic> toUpdatePayload() => {
        if (name != null) 'name': name,
        if (businessName != null) 'business_name': businessName,
        if (ownerName != null) 'owner_name': ownerName,
        if (alternateContact != null) 'alternate_contact': alternateContact,
        if (address != null) 'address': address,
        if (pincode != null) 'pincode': pincode,
        if (cityId != null) 'city_id': cityId,
        if (outletType != null) 'outlet_type': outletType,
        if (dailyOrderVolume != null) 'daily_order_volume': dailyOrderVolume,
        if (gstNumber != null) 'gst_number': gstNumber,
        if (fssaiNumber != null) 'fssai_number': fssaiNumber,
      };
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

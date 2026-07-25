class AdminUser {
  final String id;
  final String? name;
  final String? phone;
  final String? email;
  final String role;
  final bool isSetupCompleted;

  const AdminUser({
    required this.id,
    this.name,
    this.phone,
    this.email,
    required this.role,
    required this.isSetupCompleted,
  });

  bool get isAdmin => role == 'admin';

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: j['id'] as String,
        name: j['name'] as String?,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        role: j['role'] as String? ?? 'buyer',
        isSetupCompleted: j['is_setup_completed'] as bool? ?? false,
      );
}

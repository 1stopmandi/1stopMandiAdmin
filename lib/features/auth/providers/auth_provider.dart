import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../data/local/token_storage.dart';
import '../../../data/models/user.dart';

// null = not yet loaded, AsyncLoading = checking, data = user or null
final authProvider = AsyncNotifierProvider<AuthNotifier, AdminUser?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AdminUser?> {
  @override
  Future<AdminUser?> build() async {
    // Listen for 401s and auto-logout
    ApiClient.instance.onUnauthorized.listen((_) {
      state = const AsyncData(null);
    });

    final token = await TokenStorage.instance.read();
    if (token == null) return null;

    ApiClient.instance.setToken(token);
    try {
      final user = await ref.read(authRepositoryProvider).getMe();
      if (!user.isAdmin) {
        // Not an admin: clear and refuse
        await _clear();
        return null;
      }
      return user;
    } catch (_) {
      await _clear();
      return null;
    }
  }

  Future<void> sendOtp(String phone) =>
      ref.read(authRepositoryProvider).sendOtp(phone);

  Future<void> sendEmailOtp(String email) =>
      ref.read(authRepositoryProvider).sendEmailOtp(email);

  Future<AdminUser> verifyOtp(String phone, String otp) async {
    final user = await ref.read(authRepositoryProvider).verifyOtp(phone, otp);
    _guardAdmin(user);
    state = AsyncData(user);
    return user;
  }

  Future<AdminUser> verifyEmailOtp(String email, String otp) async {
    final user =
        await ref.read(authRepositoryProvider).verifyEmailOtp(email, otp);
    _guardAdmin(user);
    state = AsyncData(user);
    return user;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  void _guardAdmin(AdminUser user) {
    if (!user.isAdmin) {
      ApiClient.instance.clearToken();
      TokenStorage.instance.delete();
      throw Exception('Access denied: admin role required');
    }
  }

  Future<void> _clear() async {
    ApiClient.instance.clearToken();
    await TokenStorage.instance.delete();
  }
}

import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/local/token_storage.dart';
import '../../data/models/user.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<void> sendOtp(String phone) async {
    try {
      await _dio.post('/api/auth/send-otp', data: {'phone': phone});
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException(e.message ?? 'Failed to send OTP');
    }
  }

  Future<void> sendEmailOtp(String email) async {
    try {
      await _dio.post('/api/auth/send-email-otp', data: {'email': email.trim().toLowerCase()});
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(
        e.message ?? 'Failed to send OTP',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<AdminUser> verifyOtp(String phone, String otp) async {
    try {
      final res = await _dio.post(
        '/api/auth/verify-otp',
        data: {'phone': phone, 'otp': otp},
      );
      return _handleAuthResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException(e.message ?? 'Invalid OTP');
    }
  }

  Future<AdminUser> verifyEmailOtp(String email, String otp) async {
    try {
      final res = await _dio.post(
        '/api/auth/verify-email-otp',
        data: {'email': email.trim().toLowerCase(), 'otp': otp},
      );
      return _handleAuthResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException(e.message ?? 'Invalid OTP');
    }
  }

  Future<AdminUser> getMe() async {
    try {
      final res = await _dio.get('/api/auth/me');
      final data = res.data as Map<String, dynamic>;
      // Backend returns { user: {...} } — same as buyer app
      final userJson = (data['user'] ?? data['data']) as Map<String, dynamic>;
      return AdminUser.fromJson(userJson);
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException(e.message ?? 'Failed to fetch user');
    }
  }

  Future<void> logout() async {
    ApiClient.instance.clearToken();
    await TokenStorage.instance.delete();
  }

  AdminUser _handleAuthResponse(Map<String, dynamic> body) {
    final token = body['token'] as String;
    ApiClient.instance.setToken(token);
    TokenStorage.instance.write(token);
    // Backend returns { token, user: {...} } — same as buyer app
    final userJson = (body['user'] ?? body['data']) as Map<String, dynamic>;
    return AdminUser.fromJson(userJson);
  }
}

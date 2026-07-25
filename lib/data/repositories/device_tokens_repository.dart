import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class DeviceTokensRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<void> register({
    required String token,
    required String platform,
  }) async {
    await _dio.post('/api/account/devices', data: {
      'token': token,
      'platform': platform,
      'app': 'admin',
    });
  }

  Future<void> unregister(String token) async {
    await _dio.delete('/api/account/devices/$token');
  }
}

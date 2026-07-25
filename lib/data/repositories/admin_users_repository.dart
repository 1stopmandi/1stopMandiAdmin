import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../models/platform_user.dart';

class AdminUsersRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<({List<PlatformUserSummary> users, int total, int totalPages})> listUsers({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get('/api/admin/users', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final body = res.data as Map<String, dynamic>;
    final dataList = body['data'] as List<dynamic>;
    final pagination = body['pagination'] as Map<String, dynamic>;
    return (
      users: dataList
          .map((e) => PlatformUserSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination['total'] as int? ?? 0,
      totalPages: pagination['totalPages'] as int? ??
          pagination['total_pages'] as int? ??
          1,
    );
  }

  Future<PlatformUserDetail> getUser(String id) async {
    final res = await _dio.get('/api/admin/users/$id');
    return PlatformUserDetail.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<PlatformUserOrder>> getUserOrders(String id) async {
    final res = await _dio.get('/api/admin/users/$id/orders', queryParameters: {
      'limit': 20,
    });
    final dataList = res.data['data'] as List<dynamic>;
    return dataList
        .map((e) => PlatformUserOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UsersStats> getStats() async {
    final res = await _dio.get('/api/admin/users/stats');
    return UsersStats.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> setRole(String id, String role) async {
    try {
      await _dio.patch('/api/admin/users/$id/role', data: {'role': role});
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to update role');
    }
  }

  Future<void> setBlocked(String id, {required bool blocked, String? reason}) async {
    try {
      await _dio.patch('/api/admin/users/$id/block', data: {
        'blocked': blocked,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to update block status');
    }
  }

  ApiException _mapError(DioException e, String fallback) {
    if (e.error is ApiException) return e.error as ApiException;
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return ApiException(data['message'] as String, statusCode: e.response?.statusCode);
    }
    return ApiException(fallback, statusCode: e.response?.statusCode);
  }
}

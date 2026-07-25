import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../data/models/order.dart';

class OrdersRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<({List<Order> orders, int total, int totalPages})> listOrders({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
    };
    final res = await _dio.get('/api/admin/orders', queryParameters: params);
    final body = res.data as Map<String, dynamic>;
    final dataList = body['data'] as List<dynamic>;
    final pagination = body['pagination'] as Map<String, dynamic>;
    return (
      orders: dataList
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination['total'] as int? ?? 0,
      totalPages: pagination['total_pages'] as int? ?? 1,
    );
  }

  Future<Order> getOrder(String id) async {
    final res = await _dio.get('/api/admin/orders/$id');
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<Order> acceptOrder(String id) async {
    final res = await _dio.patch('/api/admin/orders/$id/accept');
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<Order> rejectOrder(String id, String reason) async {
    final res = await _dio.patch(
      '/api/admin/orders/$id/reject',
      data: {'reason': reason},
    );
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<Order> requestExtension(
    String id,
    DateTime proposedDeliverBy,
    String? note,
  ) async {
    final res = await _dio.patch(
      '/api/admin/orders/$id/request-extension',
      data: {
        'proposed_deliver_by': proposedDeliverBy.toIso8601String(),
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await _dio.get('/api/admin/orders/stats');
    return res.data['data'] as Map<String, dynamic>;
  }
}

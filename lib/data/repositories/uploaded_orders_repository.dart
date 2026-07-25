import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../models/uploaded_order.dart';

class UploadedOrdersRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<UploadedOrderSummary>> list({String status = 'processing'}) async {
    final res = await _dio.get(
      '/api/admin/uploaded-orders',
      queryParameters: {'status': status},
    );
    final dataList = res.data['data'] as List<dynamic>;
    return dataList
        .map((e) => UploadedOrderSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UploadedOrderDetail> getById(String id) async {
    final res = await _dio.get('/api/admin/uploaded-orders/$id');
    return UploadedOrderDetail.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<UploadedOrderDetail> markReady(
    String id, {
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      final res = await _dio.patch('/api/admin/uploaded-orders/$id/ready', data: {
        'items': items,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      return UploadedOrderDetail.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to mark upload ready');
    }
  }

  Future<void> markRejected(String id, {String? notes}) async {
    try {
      await _dio.patch('/api/admin/uploaded-orders/$id/rejected', data: {
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to reject upload');
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

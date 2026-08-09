import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/inventory_record.dart';

class InventoryRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<({List<InventoryRecord> records, int total, int totalPages})> list({
    String? search,
    String? date,
    String? startDate,
    String? endDate,
    String? purchasedBy,
    String? status,
    int page = 1,
    int limit = 20,
    String sortBy = 'record_date',
    String sortOrder = 'desc',
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort_by': sortBy,
      'sort_order': sortOrder,
      if (search != null && search.isNotEmpty) 'search': search,
      if (date != null) 'date': date,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (purchasedBy != null) 'purchased_by': purchasedBy,
      if (status != null) 'status': status,
    };
    final res = await _dio.get('/api/inventory-mgmt', queryParameters: params);
    final data = res.data['data'] as Map<String, dynamic>;
    final records = (data['records'] as List)
        .map((e) => InventoryRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = data['pagination'] as Map<String, dynamic>;
    return (
      records: records,
      total: pagination['total'] as int? ?? 0,
      totalPages: pagination['total_pages'] as int? ?? 1,
    );
  }

  Future<InventoryRecord> getById(String id) async {
    final res = await _dio.get('/api/inventory-mgmt/$id');
    return InventoryRecord.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<InventoryRecord> create(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/api/inventory-mgmt', data: data);
      return InventoryRecord.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to create record');
    }
  }

  Future<InventoryRecord> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/api/inventory-mgmt/$id', data: data);
      return InventoryRecord.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to update record');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/api/inventory-mgmt/$id');
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to delete record');
    }
  }

  Future<InventoryRecord> restore(String id) async {
    try {
      final res = await _dio.post('/api/inventory-mgmt/$id/restore');
      return InventoryRecord.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to restore record');
    }
  }

  Future<InventoryRecord> finalize(String id) async {
    try {
      final res = await _dio.post('/api/inventory-mgmt/$id/finalize');
      return InventoryRecord.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to finalize record');
    }
  }

  Future<InventoryRecord> unfinalize(String id) async {
    try {
      final res = await _dio.post('/api/inventory-mgmt/$id/unfinalize');
      return InventoryRecord.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to un-finalize record');
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

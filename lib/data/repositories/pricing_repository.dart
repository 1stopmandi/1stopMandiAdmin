import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../models/pricing.dart';

class PricingRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ProductPricingRow>> listPricingProducts({
    bool unpricedOnly = false,
  }) async {
    final res = await _dio.get(
      '/api/admin/pricing/products',
      queryParameters: {if (unpricedOnly) 'unpriced_only': 'true'},
    );
    final dataList = res.data['data'] as List<dynamic>;
    return dataList
        .map((e) => ProductPricingRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductPricingDetail> getProductPricing(String productId) async {
    final res = await _dio.get('/api/admin/pricing/$productId');
    final data = res.data['data'] as Map<String, dynamic>;
    if (data['product_id'] == null && data['id'] != null) {
      data['product_id'] = productId;
    }
    return ProductPricingDetail.fromJson(data);
  }

  Future<List<PricingAuditEntry>> getAuditLog(String productId) async {
    final res = await _dio.get('/api/admin/pricing/$productId/audit');
    final dataList = res.data['data'] as List<dynamic>;
    return dataList
        .map((e) => PricingAuditEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductPricingDetail> updatePricing({
    required String productId,
    required double basePrice,
    List<PricingSlabInput> slabs = const [],
  }) async {
    try {
      final res = await _dio.post('/api/admin/pricing/update', data: {
        'product_id': productId,
        'base_price': basePrice,
        'slabs': slabs.map((s) => s.toJson()).toList(),
      });
      final data = res.data['data'] as Map<String, dynamic>;
      data['product_id'] = data['product_id'] ?? productId;
      return ProductPricingDetail.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to update pricing');
    }
  }

  Future<void> deactivatePricing(String productId) async {
    try {
      await _dio.delete('/api/admin/pricing/$productId');
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to deactivate pricing');
    }
  }

  Future<String> exportCsv({String? categoryId}) async {
    final res = await _dio.get(
      '/api/admin/pricing/export',
      queryParameters: {if (categoryId != null) 'category_id': categoryId},
      options: Options(responseType: ResponseType.plain),
    );
    return res.data as String;
  }

  Future<BulkImportPreview> importPreview(Uint8List bytes, String filename) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final res = await _dio.post('/api/admin/pricing/import', data: form);
      return BulkImportPreview.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to preview CSV import');
    }
  }

  Future<int> confirmImport(String batchId) async {
    try {
      final res = await _dio.post('/api/admin/pricing/import/confirm', data: {
        'batch_id': batchId,
      });
      return res.data['data']['updated'] as int? ?? 0;
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to confirm import');
    }
  }

  Future<BulkUpdateResult> bulkUpdate(List<Map<String, dynamic>> items) async {
    try {
      final res = await _dio.post('/api/admin/pricing/bulk-update', data: {
        'items': items,
      });
      return BulkUpdateResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Bulk update failed');
    }
  }

  Future<void> revertPricing(String productId) async {
    try {
      await _dio.post('/api/admin/pricing/$productId/revert');
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to revert pricing');
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

import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../models/product.dart';

class ProductsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<({List<ProductSummary> products, int total, int totalPages})> listProducts({
    String? search,
    String? categoryId,
    bool? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category_id': categoryId,
      if (isActive != null) 'is_active': isActive,
    };
    final res = await _dio.get('/api/admin/products', queryParameters: params);
    final body = res.data as Map<String, dynamic>;
    final dataList = body['data'] as List<dynamic>;
    final pagination = body['pagination'] as Map<String, dynamic>;
    return (
      products: dataList
          .map((e) => ProductSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination['total'] as int? ?? 0,
      totalPages: pagination['total_pages'] as int? ?? 1,
    );
  }

  Future<ProductDetail> getProduct(String id) async {
    final res = await _dio.get('/api/admin/products/$id');
    return ProductDetail.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ProductDetail> createProduct({
    required String name,
    required String slug,
    required String unit,
    String? categoryId,
    double? moq,
    double? stock,
    bool isVeg = false,
    String? brand,
    String? description,
    double? basePrice,
  }) async {
    try {
      final res = await _dio.post('/api/admin/products', data: {
        'name': name,
        'slug': slug,
        'unit': unit,
        if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
        if (moq != null) 'moq': moq,
        if (stock != null) 'stock': stock,
        'is_veg': isVeg,
        if (brand != null && brand.isNotEmpty) 'brand': brand,
        if (description != null && description.isNotEmpty) 'description': description,
        if (basePrice != null) 'base_price': basePrice,
      });
      return ProductDetail.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to create product');
    }
  }

  Future<ProductDetail> updateProduct(
    String id,
    Map<String, dynamic> fields,
  ) async {
    try {
      final res = await _dio.patch('/api/admin/products/$id', data: fields);
      return ProductDetail.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to update product');
    }
  }

  Future<void> deactivateProduct(String id) async {
    try {
      await _dio.delete('/api/admin/products/$id');
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to deactivate product');
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

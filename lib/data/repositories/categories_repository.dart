import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../models/category.dart';

class CategoriesRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Category>> listCategories({bool includeInactive = false}) async {
    final res = await _dio.get(
      '/api/admin/categories',
      queryParameters: {
        if (includeInactive) 'include_inactive': true,
      },
    );
    final dataList = res.data['data'] as List<dynamic>;
    return dataList
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Category> getCategory(String id) async {
    final categories = await listCategories(includeInactive: true);
    return categories.firstWhere(
      (c) => c.id == id,
      orElse: () => throw ApiException('Category not found', statusCode: 404),
    );
  }

  Future<Category> createCategory({
    required String name,
    required String slug,
    int sortOrder = 0,
  }) async {
    try {
      final res = await _dio.post('/api/admin/categories', data: {
        'name': name,
        'slug': slug,
        'sort_order': sortOrder,
      });
      final json = res.data['data'] as Map<String, dynamic>;
      return Category.fromJson({
        ...json,
        'active_product_count': 0,
      });
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to create category');
    }
  }

  Future<Category> updateCategory(
    String id,
    Map<String, dynamic> fields,
  ) async {
    try {
      final res = await _dio.patch('/api/admin/categories/$id', data: fields);
      final json = res.data['data'] as Map<String, dynamic>;
      final existing = await getCategory(id);
      return Category.fromJson({
        ...json,
        'active_product_count': existing.activeProductCount,
        'created_at': existing.createdAt?.toIso8601String(),
      });
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to update category');
    }
  }

  Future<void> deactivateCategory(String id) async {
    try {
      await _dio.delete('/api/admin/categories/$id');
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to deactivate category');
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

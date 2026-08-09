import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/employee.dart';

class EmployeeRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<({List<Employee> employees, int total, int totalPages})> list({
    String? search,
    String status = 'all',
    String designation = 'all',
    int page = 1,
    int limit = 20,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'status': status,
      'designation': designation,
      'sort_by': sortBy,
      'sort_order': sortOrder,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await _dio.get('/api/employees', queryParameters: params);
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final list = (data['employees'] as List)
        .map((e) => Employee.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = data['pagination'] as Map<String, dynamic>;
    return (
      employees: list,
      total: pagination['total'] as int? ?? 0,
      totalPages: pagination['total_pages'] as int? ?? 1,
    );
  }

  Future<Employee> getById(String id) async {
    final res = await _dio.get('/api/employees/$id');
    return Employee.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<Employee> create(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/api/employees', data: data);
      return Employee.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to create employee');
    }
  }

  Future<Employee> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/api/employees/$id', data: data);
      return Employee.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to update employee');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/api/employees/$id');
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to delete employee');
    }
  }

  Future<void> updateStatus(String id, String status, {String? notes}) async {
    try {
      await _dio.patch('/api/employees/$id/status', data: {
        'status': status,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to update status');
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

import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/salary.dart';

class SalaryRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<SalaryBreakdown>> generate({
    required String periodStart,
    required String periodEnd,
    List<String>? employeeIds,
  }) async {
    final res = await _dio.post('/api/salary/generate', data: {
      'period_start': periodStart,
      'period_end': periodEnd,
      if (employeeIds != null && employeeIds.isNotEmpty) 'employee_ids': employeeIds,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    return (data['salary_breakdown'] as List)
        .map((e) => SalaryBreakdown.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> confirm({
    required String periodStart,
    required String periodEnd,
    List<String>? employeeIds,
  }) async {
    try {
      await _dio.post('/api/salary/confirm', data: {
        'period_start': periodStart,
        'period_end': periodEnd,
        if (employeeIds != null && employeeIds.isNotEmpty) 'employee_ids': employeeIds,
      });
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to confirm salary');
    }
  }

  Future<({List<SalaryPeriod> periods, int total, int totalPages})> listPeriods({
    String? employeeId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (employeeId != null) 'employee_id': employeeId,
      if (status != null) 'status': status,
    };
    final res = await _dio.get('/api/salary', queryParameters: params);
    final data = res.data['data'] as Map<String, dynamic>;
    final periods = (data['salary_periods'] as List)
        .map((e) => SalaryPeriod.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = data['pagination'] as Map<String, dynamic>;
    return (
      periods: periods,
      total: pagination['total'] as int? ?? 0,
      totalPages: pagination['total_pages'] as int? ?? 1,
    );
  }

  Future<SalaryPeriod> getById(String id) async {
    final res = await _dio.get('/api/salary/$id');
    return SalaryPeriod.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> recalculate(String id) async {
    try {
      await _dio.post('/api/salary/$id/recalculate');
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to recalculate');
    }
  }

  Future<void> recordPayment({
    required String salaryPeriodId,
    required double amountPaid,
    required String paymentMethod,
    required String paymentDate,
    String? transactionReference,
    String? notes,
  }) async {
    try {
      await _dio.post('/api/salary-payments', data: {
        'salary_period_id': salaryPeriodId,
        'amount_paid': amountPaid,
        'payment_method': paymentMethod,
        'payment_date': paymentDate,
        if (transactionReference != null && transactionReference.isNotEmpty)
          'transaction_reference': transactionReference,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to record payment');
    }
  }

  Future<({List<SalaryPayment> payments, int total, int totalPages})> getPaymentHistory({
    String? employeeId,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (employeeId != null) 'employee_id': employeeId,
    };
    final res = await _dio.get('/api/salary-payments/history', queryParameters: params);
    final data = res.data['data'] as Map<String, dynamic>;
    final payments = (data['payments'] as List)
        .map((e) => SalaryPayment.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = data['pagination'] as Map<String, dynamic>;
    return (
      payments: payments,
      total: pagination['total'] as int? ?? 0,
      totalPages: pagination['total_pages'] as int? ?? 1,
    );
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

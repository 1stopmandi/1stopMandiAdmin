import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/attendance.dart';

class AttendanceRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<({AttendanceSummary summary, List<AttendanceRecord> records, List<UnmarkedEmployee> unmarked})> getByDate(String date) async {
    final res = await _dio.get('/api/attendance', queryParameters: {'date': date});
    final data = res.data['data'] as Map<String, dynamic>;
    final summary = AttendanceSummary.fromJson(data['summary'] as Map<String, dynamic>);
    final records = (data['records'] as List)
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    final unmarked = (data['unmarked'] as List)
        .map((e) => UnmarkedEmployee.fromJson(e as Map<String, dynamic>))
        .toList();
    return (summary: summary, records: records, unmarked: unmarked);
  }

  Future<AttendanceRecord> markSingle({
    required String employeeId,
    required String date,
    required String status,
    String? checkInTime,
    String? checkOutTime,
    String? notes,
  }) async {
    try {
      final res = await _dio.post('/api/attendance', data: {
        'employee_id': employeeId,
        'date': date,
        'status': status,
        if (checkInTime != null) 'check_in_time': checkInTime,
        if (checkOutTime != null) 'check_out_time': checkOutTime,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      return AttendanceRecord.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to mark attendance');
    }
  }

  Future<List<AttendanceRecord>> markBulk({
    required String date,
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      final res = await _dio.post('/api/attendance/bulk', data: {
        'date': date,
        'records': records,
      });
      return (res.data['data'] as List)
          .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to mark bulk attendance');
    }
  }

  Future<AttendanceRecord> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/api/attendance/$id', data: data);
      return AttendanceRecord.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to update attendance');
    }
  }

  Future<({List<AttendanceRecord> records, Map<String, int> summary})> getEmployeeHistory(
    String employeeId, String startDate, String endDate,
  ) async {
    final res = await _dio.get('/api/attendance/employee/$employeeId', queryParameters: {
      'start_date': startDate,
      'end_date': endDate,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    final records = (data['records'] as List)
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    final summaryJson = data['summary'] as Map<String, dynamic>;
    final summary = summaryJson.map((k, v) => MapEntry(k, v as int));
    return (records: records, summary: summary);
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

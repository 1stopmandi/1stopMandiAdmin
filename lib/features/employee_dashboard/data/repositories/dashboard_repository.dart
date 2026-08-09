import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class EmployeeDashboardMetrics {
  final int totalEmployees;
  final int activeEmployees;
  final int todayPresent;
  final int todayAbsent;
  final int todayHalfDay;
  final int todayLeave;
  final int todayHoliday;
  final int todayUnmarked;
  final int salaryPendingCount;
  final double salaryPendingAmount;
  final double salaryPaidThisMonth;
  final double attendancePercentage;
  final String month;

  const EmployeeDashboardMetrics({
    this.totalEmployees = 0,
    this.activeEmployees = 0,
    this.todayPresent = 0,
    this.todayAbsent = 0,
    this.todayHalfDay = 0,
    this.todayLeave = 0,
    this.todayHoliday = 0,
    this.todayUnmarked = 0,
    this.salaryPendingCount = 0,
    this.salaryPendingAmount = 0,
    this.salaryPaidThisMonth = 0,
    this.attendancePercentage = 0,
    this.month = '',
  });

  factory EmployeeDashboardMetrics.fromJson(Map<String, dynamic> json) {
    return EmployeeDashboardMetrics(
      totalEmployees: json['total_employees'] as int? ?? 0,
      activeEmployees: json['active_employees'] as int? ?? 0,
      todayPresent: json['today_present'] as int? ?? 0,
      todayAbsent: json['today_absent'] as int? ?? 0,
      todayHalfDay: json['today_half_day'] as int? ?? 0,
      todayLeave: json['today_leave'] as int? ?? 0,
      todayHoliday: json['today_holiday'] as int? ?? 0,
      todayUnmarked: json['today_unmarked'] as int? ?? 0,
      salaryPendingCount: json['salary_pending_count'] as int? ?? 0,
      salaryPendingAmount: (json['salary_pending_amount'] as num?)?.toDouble() ?? 0,
      salaryPaidThisMonth: (json['salary_paid_this_month'] as num?)?.toDouble() ?? 0,
      attendancePercentage: (json['attendance_percentage'] as num?)?.toDouble() ?? 0,
      month: json['month'] as String? ?? '',
    );
  }
}

class EmployeeDashboardRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<EmployeeDashboardMetrics> getMetrics() async {
    final res = await _dio.get('/api/dashboard/employees');
    return EmployeeDashboardMetrics.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}

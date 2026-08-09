import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/attendance.dart';
import '../data/repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) => AttendanceRepository());

// ─── Daily attendance state ─────────────────────────────────────────────────

class DailyAttendanceState {
  final String date;
  final AttendanceSummary summary;
  final List<AttendanceRecord> records;
  final List<UnmarkedEmployee> unmarked;

  const DailyAttendanceState({
    required this.date,
    this.summary = const AttendanceSummary(),
    this.records = const [],
    this.unmarked = const [],
  });
}

final dailyAttendanceDateProvider = StateProvider<String>((ref) {
  return DateTime.now().toString().split(' ')[0];
});

final dailyAttendanceProvider =
    AsyncNotifierProvider<DailyAttendanceNotifier, DailyAttendanceState>(
        DailyAttendanceNotifier.new);

class DailyAttendanceNotifier extends AsyncNotifier<DailyAttendanceState> {
  @override
  Future<DailyAttendanceState> build() async {
    final date = ref.watch(dailyAttendanceDateProvider);
    return _fetch(date);
  }

  Future<DailyAttendanceState> _fetch(String date) async {
    final repo = ref.read(attendanceRepositoryProvider);
    final result = await repo.getByDate(date);
    return DailyAttendanceState(
      date: date,
      summary: result.summary,
      records: result.records,
      unmarked: result.unmarked,
    );
  }

  Future<void> refresh() async {
    final date = ref.read(dailyAttendanceDateProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(date));
  }

  Future<void> markAttendance({
    required String employeeId,
    required String status,
    String? checkInTime,
    String? checkOutTime,
    String? notes,
  }) async {
    final date = ref.read(dailyAttendanceDateProvider);
    final repo = ref.read(attendanceRepositoryProvider);
    await repo.markSingle(
      employeeId: employeeId,
      date: date,
      status: status,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      notes: notes,
    );
    await refresh();
  }

  Future<void> markBulk(List<Map<String, dynamic>> records) async {
    final date = ref.read(dailyAttendanceDateProvider);
    final repo = ref.read(attendanceRepositoryProvider);
    await repo.markBulk(date: date, records: records);
    await refresh();
  }
}

// ─── Employee attendance history ────────────────────────────────────────────

class EmployeeAttendanceHistoryState {
  final String employeeId;
  final String startDate;
  final String endDate;
  final List<AttendanceRecord> records;
  final Map<String, int> summary;

  const EmployeeAttendanceHistoryState({
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    this.records = const [],
    this.summary = const {},
  });
}

final employeeAttendanceHistoryProvider = AsyncNotifierProviderFamily<
    EmployeeAttendanceHistoryNotifier,
    EmployeeAttendanceHistoryState,
    ({String employeeId, String startDate, String endDate})>(
  EmployeeAttendanceHistoryNotifier.new,
);

class EmployeeAttendanceHistoryNotifier extends FamilyAsyncNotifier<
    EmployeeAttendanceHistoryState,
    ({String employeeId, String startDate, String endDate})> {
  @override
  Future<EmployeeAttendanceHistoryState> build(
      ({String employeeId, String startDate, String endDate}) params) async {
    final repo = ref.read(attendanceRepositoryProvider);
    final result = await repo.getEmployeeHistory(
        params.employeeId, params.startDate, params.endDate);
    return EmployeeAttendanceHistoryState(
      employeeId: params.employeeId,
      startDate: params.startDate,
      endDate: params.endDate,
      records: result.records,
      summary: result.summary,
    );
  }
}

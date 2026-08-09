class AttendanceRecord {
  final String? id;
  final String employeeId;
  final String? employeeName;
  final String? employeeCode;
  final String? designation;
  final String date;
  final String? status;
  final String? checkInTime;
  final String? checkOutTime;
  final double? totalWorkingHours;
  final String? notes;

  const AttendanceRecord({
    this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    this.designation,
    required this.date,
    this.status,
    this.checkInTime,
    this.checkOutTime,
    this.totalWorkingHours,
    this.notes,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String?,
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String?,
      employeeCode: json['employee_code'] as String?,
      designation: json['designation'] as String?,
      date: json['date'] as String,
      status: json['status'] as String?,
      checkInTime: json['check_in_time'] as String?,
      checkOutTime: json['check_out_time'] as String?,
      totalWorkingHours: json['total_working_hours'] != null
          ? _toDouble(json['total_working_hours'])
          : null,
      notes: json['notes'] as String?,
    );
  }

  bool get isMarked => status != null;

  String get statusLabel {
    if (status == null) return 'Unmarked';
    return status!.replaceAll('_', ' ').split(' ').map(
      (w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
    ).join(' ');
  }
}

class AttendanceSummary {
  final int totalEmployees;
  final int present;
  final int halfDay;
  final int absent;
  final int leave;
  final int holiday;
  final int unmarked;

  const AttendanceSummary({
    this.totalEmployees = 0,
    this.present = 0,
    this.halfDay = 0,
    this.absent = 0,
    this.leave = 0,
    this.holiday = 0,
    this.unmarked = 0,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalEmployees: json['total_employees'] as int? ?? 0,
      present: json['present'] as int? ?? 0,
      halfDay: json['half_day'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      leave: json['leave'] as int? ?? 0,
      holiday: json['holiday'] as int? ?? 0,
      unmarked: json['unmarked'] as int? ?? 0,
    );
  }
}

class UnmarkedEmployee {
  final String id;
  final String employeeCode;
  final String fullName;
  final String designation;

  const UnmarkedEmployee({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    required this.designation,
  });

  factory UnmarkedEmployee.fromJson(Map<String, dynamic> json) {
    return UnmarkedEmployee(
      id: json['id'] as String,
      employeeCode: json['employee_code'] as String,
      fullName: json['full_name'] as String,
      designation: json['designation'] as String,
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

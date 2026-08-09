class SalaryBreakdown {
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final double monthlySalary;
  final int daysInMonth;
  final double dailyWage;
  final int presentDays;
  final int halfDays;
  final int absentDays;
  final int leaveDays;
  final int holidayDays;
  final double payableDays;
  final double totalWorkingHours;
  final double grossSalary;
  final double previousPending;
  final double advances;
  final double finalPayable;

  const SalaryBreakdown({
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.monthlySalary,
    required this.daysInMonth,
    required this.dailyWage,
    required this.presentDays,
    required this.halfDays,
    required this.absentDays,
    required this.leaveDays,
    required this.holidayDays,
    required this.payableDays,
    required this.totalWorkingHours,
    required this.grossSalary,
    required this.previousPending,
    required this.advances,
    required this.finalPayable,
  });

  factory SalaryBreakdown.fromJson(Map<String, dynamic> json) {
    return SalaryBreakdown(
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String,
      employeeCode: json['employee_code'] as String,
      monthlySalary: _toDouble(json['monthly_salary']),
      daysInMonth: _toInt(json['days_in_month']),
      dailyWage: _toDouble(json['daily_wage']),
      presentDays: _toInt(json['present_days']),
      halfDays: _toInt(json['half_days']),
      absentDays: _toInt(json['absent_days']),
      leaveDays: _toInt(json['leave_days']),
      holidayDays: _toInt(json['holiday_days']),
      payableDays: _toDouble(json['payable_days']),
      totalWorkingHours: _toDouble(json['total_working_hours']),
      grossSalary: _toDouble(json['gross_salary']),
      previousPending: _toDouble(json['previous_pending']),
      advances: _toDouble(json['advances']),
      finalPayable: _toDouble(json['final_payable']),
    );
  }
}

class SalaryPeriod {
  final String id;
  final String employeeId;
  final String? employeeName;
  final String? employeeCode;
  final String periodStart;
  final String periodEnd;
  final double dailyWage;
  final double presentDays;
  final double halfDays;
  final double absentDays;
  final double leaveDays;
  final double holidayDays;
  final double? totalWorkingHours;
  final double grossSalary;
  final double previousPending;
  final double advances;
  final double finalPayable;
  final String status;
  final List<SalaryPayment> payments;
  final double? totalPaid;
  final double? remaining;

  const SalaryPeriod({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    required this.periodStart,
    required this.periodEnd,
    required this.dailyWage,
    required this.presentDays,
    required this.halfDays,
    required this.absentDays,
    required this.leaveDays,
    required this.holidayDays,
    this.totalWorkingHours,
    required this.grossSalary,
    required this.previousPending,
    required this.advances,
    required this.finalPayable,
    required this.status,
    this.payments = const [],
    this.totalPaid,
    this.remaining,
  });

  factory SalaryPeriod.fromJson(Map<String, dynamic> json) {
    return SalaryPeriod(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String?,
      employeeCode: json['employee_code'] as String?,
      periodStart: json['period_start'] as String,
      periodEnd: json['period_end'] as String,
      dailyWage: _toDouble(json['daily_wage']),
      presentDays: _toDouble(json['present_days']),
      halfDays: _toDouble(json['half_days']),
      absentDays: _toDouble(json['absent_days']),
      leaveDays: _toDouble(json['leave_days']),
      holidayDays: _toDouble(json['holiday_days']),
      totalWorkingHours: json['total_working_hours'] != null
          ? _toDouble(json['total_working_hours'])
          : null,
      grossSalary: _toDouble(json['gross_salary']),
      previousPending: _toDouble(json['previous_pending']),
      advances: _toDouble(json['advances']),
      finalPayable: _toDouble(json['final_payable']),
      status: json['status'] as String,
      payments: json['payments'] != null
          ? (json['payments'] as List)
              .map((e) => SalaryPayment.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      totalPaid: json['total_paid'] != null ? _toDouble(json['total_paid']) : null,
      remaining: json['remaining'] != null ? _toDouble(json['remaining']) : null,
    );
  }

  String get statusLabel => status[0].toUpperCase() + status.substring(1);
}

class SalaryPayment {
  final String id;
  final String? salaryPeriodId;
  final double amountPaid;
  final String paymentMethod;
  final String paymentDate;
  final String? transactionReference;
  final String? notes;
  final String? createdAt;
  final String? employeeName;
  final String? employeeCode;
  final String? periodStart;
  final String? periodEnd;

  const SalaryPayment({
    required this.id,
    this.salaryPeriodId,
    required this.amountPaid,
    required this.paymentMethod,
    required this.paymentDate,
    this.transactionReference,
    this.notes,
    this.createdAt,
    this.employeeName,
    this.employeeCode,
    this.periodStart,
    this.periodEnd,
  });

  factory SalaryPayment.fromJson(Map<String, dynamic> json) {
    return SalaryPayment(
      id: json['id'] as String,
      salaryPeriodId: json['salary_period_id'] as String?,
      amountPaid: _toDouble(json['amount_paid']),
      paymentMethod: json['payment_method'] as String,
      paymentDate: json['payment_date'] as String,
      transactionReference: json['transaction_reference'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
      employeeName: json['employee_name'] as String?,
      employeeCode: json['employee_code'] as String?,
      periodStart: json['period_start'] as String?,
      periodEnd: json['period_end'] as String?,
    );
  }

  String get methodLabel => paymentMethod.replaceAll('_', ' ').split(' ').map(
    (w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
  ).join(' ');
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

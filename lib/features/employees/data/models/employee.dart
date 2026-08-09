class Employee {
  final String id;
  final String employeeCode;
  final String fullName;
  final String mobileNumber;
  final String? alternateNumber;
  final String? address;
  final String? aadhaarNumber;
  final String? photoUrl;
  final String? emergencyContact;
  final String? joiningDate;
  final String status;
  final String employeeType;
  final String designation;
  final double monthlySalary;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  const Employee({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    required this.mobileNumber,
    this.alternateNumber,
    this.address,
    this.aadhaarNumber,
    this.photoUrl,
    this.emergencyContact,
    this.joiningDate,
    required this.status,
    required this.employeeType,
    required this.designation,
    required this.monthlySalary,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      employeeCode: json['employee_code'] as String,
      fullName: json['full_name'] as String,
      mobileNumber: json['mobile_number'] as String,
      alternateNumber: json['alternate_number'] as String?,
      address: json['address'] as String?,
      aadhaarNumber: json['aadhaar_number'] as String?,
      photoUrl: json['photo_url'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      joiningDate: json['joining_date'] as String?,
      status: json['status'] as String,
      employeeType: json['employee_type'] as String,
      designation: json['designation'] as String,
      monthlySalary: _toDouble(json['monthly_salary']),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  String get designationLabel => designation.replaceAll('_', ' ').split(' ').map(
    (w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
  ).join(' ');

  String get statusLabel => status[0].toUpperCase() + status.substring(1);
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

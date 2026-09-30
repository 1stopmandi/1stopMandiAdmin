import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../providers/employees_provider.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  final String? employeeId;
  const EmployeeFormScreen({super.key, this.employeeId});

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEdit = false;

  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _altMobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _joiningDateCtrl = TextEditingController();

  String _employeeType = 'daily_wage';
  String _designation = 'helper';

  static const _designations = [
    ('packing_staff', 'Packing Staff'),
    ('loader', 'Loader'),
    ('helper', 'Helper'),
    ('cleaner', 'Cleaner'),
    ('warehouse_staff', 'Warehouse Staff'),
    ('other', 'Other'),
  ];

  static const _employeeTypes = [
    ('daily_wage', 'Daily Wage'),
    ('monthly', 'Monthly'),
    ('contract', 'Contract'),
  ];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.employeeId != null;
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEmployee());
    } else {
      _joiningDateCtrl.text = DateTime.now().toString().split(' ')[0];
    }
  }

  Future<void> _loadEmployee() async {
    final emp = await ref.read(employeeRepositoryProvider).getById(widget.employeeId!);
    _nameCtrl.text = emp.fullName;
    _mobileCtrl.text = emp.mobileNumber;
    _altMobileCtrl.text = emp.alternateNumber ?? '';
    _addressCtrl.text = emp.address ?? '';
    _aadhaarCtrl.text = '';
    _emergencyCtrl.text = emp.emergencyContact ?? '';
    _salaryCtrl.text = emp.monthlySalary.toStringAsFixed(0);
    _notesCtrl.text = emp.notes ?? '';
    _joiningDateCtrl.text = emp.joiningDate ?? '';
    setState(() {
      _employeeType = emp.employeeType;
      _designation = emp.designation;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _altMobileCtrl.dispose();
    _addressCtrl.dispose();
    _aadhaarCtrl.dispose();
    _emergencyCtrl.dispose();
    _salaryCtrl.dispose();
    _notesCtrl.dispose();
    _joiningDateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Employee' : 'Add Employee'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.length < 2) ? 'Min 2 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobileCtrl,
                decoration: const InputDecoration(labelText: 'Mobile Number *', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                validator: (v) => (v == null || v.length != 10) ? 'Must be 10 digits' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _altMobileCtrl,
                decoration: const InputDecoration(labelText: 'Alternate Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergencyCtrl,
                decoration: const InputDecoration(labelText: 'Emergency Contact *', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                validator: (v) => (v == null || v.length != 10) ? 'Must be 10 digits' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Address *', border: OutlineInputBorder()),
                maxLines: 2,
                validator: (v) => (v == null || v.length < 10) ? 'Min 10 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aadhaarCtrl,
                decoration: InputDecoration(
                  labelText: _isEdit ? 'Aadhaar (re-enter to update)' : 'Aadhaar Number',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _employeeType,
                      decoration: const InputDecoration(labelText: 'Type *', border: OutlineInputBorder()),
                      items: _employeeTypes.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2))).toList(),
                      onChanged: (v) => setState(() => _employeeType = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _designation,
                      decoration: const InputDecoration(labelText: 'Designation *', border: OutlineInputBorder()),
                      items: _designations.map((d) => DropdownMenuItem(value: d.$1, child: Text(d.$2))).toList(),
                      onChanged: (v) => setState(() => _designation = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _salaryCtrl,
                decoration: const InputDecoration(labelText: 'Monthly Salary (₹) *', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0 || n > 200000) return '1 - 200000';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _joiningDateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Joining Date *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _pickDate,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Update Employee' : 'Create Employee'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_joiningDateCtrl.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _joiningDateCtrl.text = picked.toString().split(' ')[0];
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'full_name': _nameCtrl.text.trim(),
      'mobile_number': _mobileCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'emergency_contact': _emergencyCtrl.text.trim(),
      'joining_date': _joiningDateCtrl.text,
      'employee_type': _employeeType,
      'designation': _designation,
      'monthly_salary': int.parse(_salaryCtrl.text.trim()),
    };

    if (_altMobileCtrl.text.trim().isNotEmpty) data['alternate_number'] = _altMobileCtrl.text.trim();
    if (_aadhaarCtrl.text.trim().isNotEmpty) data['aadhaar_number'] = _aadhaarCtrl.text.trim();
    if (_notesCtrl.text.trim().isNotEmpty) data['notes'] = _notesCtrl.text.trim();

    try {
      final repo = ref.read(employeeRepositoryProvider);
      if (_isEdit) {
        await repo.update(widget.employeeId!, data);
        ref.read(employeeDetailProvider(widget.employeeId!).notifier).refresh();
      } else {
        await repo.create(data);
      }
      ref.read(employeesListProvider.notifier).refresh();
      if (mounted) {
        AppToast.success(
          context,
          _isEdit ? 'Employee updated' : 'Employee created',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

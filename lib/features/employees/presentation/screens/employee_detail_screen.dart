import 'package:flutter/material.dart';
import '../../../../shared/widgets/skeleton_card.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/utils/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/employees_provider.dart';

class EmployeeDetailScreen extends ConsumerWidget {
  final String employeeId;
  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(employeeDetailProvider(employeeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Detail'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          detailAsync.whenOrNull(
                data: (emp) => PopupMenuButton<String>(
                  onSelected: (action) => _handleAction(context, ref, action),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (emp.status == 'active')
                      const PopupMenuItem(value: 'inactive', child: Text('Mark Inactive')),
                    if (emp.status == 'inactive')
                      const PopupMenuItem(value: 'active', child: Text('Re-activate')),
                    if (emp.status != 'left')
                      const PopupMenuItem(value: 'left', child: Text('Mark as Left')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: detailAsync.when(
        loading: () => const ContentSkeleton(type: ContentSkeletonType.detail),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(employeeDetailProvider(employeeId)),
        ),
        data: (emp) => RefreshIndicator(
          onRefresh: () => ref.read(employeeDetailProvider(employeeId).notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.green[100],
                  child: Text(
                    emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 32, color: Colors.green[800]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(emp.fullName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Center(child: Text(emp.employeeCode, style: TextStyle(color: Colors.grey[600]))),
              const SizedBox(height: 24),
              _InfoCard(children: [
                _InfoRow('Status', emp.statusLabel),
                _InfoRow('Designation', emp.designationLabel),
                _InfoRow('Type', emp.employeeType.replaceAll('_', ' ')),
                _InfoRow('Monthly Salary', '₹${emp.monthlySalary.toStringAsFixed(0)}'),
                _InfoRow('Joining Date', emp.joiningDate ?? '-'),
              ]),
              const SizedBox(height: 12),
              _InfoCard(children: [
                _InfoRow('Mobile', emp.mobileNumber),
                _InfoRow('Alternate', emp.alternateNumber ?? '-'),
                _InfoRow('Emergency', emp.emergencyContact ?? '-'),
                _InfoRow('Address', emp.address ?? '-'),
              ]),
              const SizedBox(height: 12),
              _InfoCard(children: [
                _InfoRow('Aadhaar', emp.aadhaarNumber ?? '-'),
                if (emp.notes != null && emp.notes!.isNotEmpty) _InfoRow('Notes', emp.notes!),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) async {
    final notifier = ref.read(employeeDetailProvider(employeeId).notifier);
    try {
      switch (action) {
        case 'edit':
          context.push('/employees/$employeeId/edit');
        case 'active':
          await notifier.updateStatus('active');
          if (context.mounted) AppToast.success(context, 'Employee activated');
        case 'inactive':
          await notifier.updateStatus('inactive');
          if (context.mounted) AppToast.success(context, 'Employee marked inactive');
        case 'left':
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Confirm'),
              content: const Text('Mark employee as left? This cannot be undone.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
              ],
            ),
          );
          if (confirm == true) {
            await notifier.updateStatus('left');
            if (context.mounted) AppToast.success(context, 'Employee marked as left');
          }
        case 'delete':
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Delete Employee?'),
              content: const Text('This will soft-delete the employee. They can be restored later.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
              ],
            ),
          );
          if (confirm == true) {
            await notifier.deleteEmployee();
            if (context.mounted) {
              AppToast.success(context, 'Employee deleted');
              context.pop();
            }
          }
      }
    } catch (error) {
      if (context.mounted) AppToast.error(context, error.toString());
    }
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

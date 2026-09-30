import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../data/models/attendance.dart';
import '../../../../core/widgets/admin_menu_button.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/skeleton_card.dart';
import '../../../../shared/widgets/error_view.dart';

class AttendanceMarkScreen extends ConsumerWidget {
  const AttendanceMarkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(dailyAttendanceDateProvider);
    final attendanceAsync = ref.watch(dailyAttendanceProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Mark Attendance'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dailyAttendanceProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          _DateSelector(date: date),
          attendanceAsync.when(
            loading: () => const Expanded(child: ContentSkeleton(type: ContentSkeletonType.list)),
            error: (e, _) => Expanded(child: ErrorView(message: e.toString())),
            data: (state) => Expanded(
              child: Column(
                children: [
                  _SummaryBar(summary: state.summary),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => ref.read(dailyAttendanceProvider.notifier).refresh(),
                      child: ListView(
                        children: [
                          if (state.unmarked.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(
                                'Unmarked (${state.unmarked.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            ...state.unmarked.map((emp) => _UnmarkedTile(
                              employee: emp,
                              date: state.date,
                            )),
                            const Divider(height: 24),
                          ],
                          if (state.records.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                              child: Text(
                                'Marked (${state.records.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            ...state.records.map((r) => _MarkedTile(record: r)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends ConsumerWidget {
  final String date;
  const _DateSelector({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatted = DateFormat('EEE, dd MMM yyyy').format(DateTime.parse(date));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green[50],
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final prev = DateTime.parse(date).subtract(const Duration(days: 1));
              ref.read(dailyAttendanceDateProvider.notifier).state =
                  prev.toString().split(' ')[0];
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.parse(date),
                  firstDate: DateTime.now().subtract(const Duration(days: 7)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  ref.read(dailyAttendanceDateProvider.notifier).state =
                      picked.toString().split(' ')[0];
                }
              },
              child: Text(
                formatted,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final next = DateTime.parse(date).add(const Duration(days: 1));
              if (!next.isAfter(DateTime.now())) {
                ref.read(dailyAttendanceDateProvider.notifier).state =
                    next.toString().split(' ')[0];
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final AttendanceSummary summary;
  const _SummaryBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _chip('P: ${summary.present}', Colors.green),
          _chip('H: ${summary.halfDay}', Colors.orange),
          _chip('A: ${summary.absent}', Colors.red),
          _chip('L: ${summary.leave}', Colors.blue),
          _chip('??: ${summary.unmarked}', Colors.grey),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color),
      backgroundColor: color.withValues(alpha: 0.05),
    );
  }
}

class _UnmarkedTile extends ConsumerWidget {
  final UnmarkedEmployee employee;
  final String date;
  const _UnmarkedTile({required this.employee, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey[200],
          child: Text(employee.fullName[0], style: const TextStyle(fontSize: 14)),
        ),
        title: Text(employee.fullName, style: const TextStyle(fontSize: 14)),
        subtitle: Text(employee.employeeCode, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusButton(
              label: 'P',
              color: Colors.green,
              onTap: () => _showTimeDialog(context, ref, 'present'),
            ),
            const SizedBox(width: 4),
            _StatusButton(
              label: 'H',
              color: Colors.orange,
              onTap: () => _showTimeDialog(context, ref, 'half_day'),
            ),
            const SizedBox(width: 4),
            _StatusButton(
              label: 'A',
              color: Colors.red,
              onTap: () => _markDirect(context, ref, 'absent'),
            ),
            const SizedBox(width: 4),
            _StatusButton(
              label: 'L',
              color: Colors.blue,
              onTap: () => _markDirect(context, ref, 'leave'),
            ),
          ],
        ),
      ),
    );
  }

  void _markDirect(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref.read(dailyAttendanceProvider.notifier).markAttendance(
            employeeId: employee.id,
            status: status,
          );
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, '$e');
      }
    }
  }

  void _showTimeDialog(BuildContext context, WidgetRef ref, String status) {
    TimeOfDay? checkIn = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay? checkOut = status == 'half_day'
        ? const TimeOfDay(hour: 13, minute: 0)
        : const TimeOfDay(hour: 18, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('${status == 'present' ? 'Present' : 'Half Day'} - ${employee.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Check In'),
                trailing: Text(
                  checkIn != null ? _formatTime(checkIn!) : 'Not set',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: checkIn!);
                  if (picked != null) setDialogState(() => checkIn = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Check Out'),
                trailing: Text(
                  checkOut != null ? _formatTime(checkOut!) : 'Not set',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: checkOut!);
                  if (picked != null) setDialogState(() => checkOut = picked);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'You can skip times and just mark ${status == 'present' ? 'present' : 'half day'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _markWithTime(context, ref, status, null, null);
              },
              child: const Text('Skip Time'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _markWithTime(context, ref, status, checkIn, checkOut);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _markWithTime(BuildContext context, WidgetRef ref, String status, TimeOfDay? checkIn, TimeOfDay? checkOut) async {
    try {
      await ref.read(dailyAttendanceProvider.notifier).markAttendance(
            employeeId: employee.id,
            status: status,
            checkInTime: checkIn != null ? _formatTime(checkIn) : null,
            checkOutTime: checkOut != null ? _formatTime(checkOut) : null,
          );
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, '$e');
      }
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _StatusButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}

class _MarkedTile extends StatelessWidget {
  final AttendanceRecord record;
  const _MarkedTile({required this.record});

  Color _statusColor() {
    switch (record.status) {
      case 'present': return Colors.green;
      case 'half_day': return Colors.orange;
      case 'absent': return Colors.red;
      case 'leave': return Colors.blue;
      case 'holiday': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: _statusColor().withValues(alpha: 0.15),
          child: Text(
            record.status?[0].toUpperCase() ?? '?',
            style: TextStyle(color: _statusColor(), fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        title: Text(record.employeeName ?? '', style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          '${record.employeeCode ?? ''} • ${record.statusLabel}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: record.totalWorkingHours != null
            ? Text('${record.totalWorkingHours!.toStringAsFixed(1)}h',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]))
            : null,
      ),
    );
  }
}

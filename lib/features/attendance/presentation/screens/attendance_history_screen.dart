import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_card.dart';

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  final String employeeId;
  final String employeeName;
  const AttendanceHistoryScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  ConsumerState<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends ConsumerState<AttendanceHistoryScreen> {
  late String _startDate;
  late String _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1).toString().split(' ')[0];
    _endDate = now.toString().split(' ')[0];
  }

  @override
  Widget build(BuildContext context) {
    final params = (employeeId: widget.employeeId, startDate: _startDate, endDate: _endDate);
    final historyAsync = ref.watch(employeeAttendanceHistoryProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.employeeName} - Attendance'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_startDate),
                    onPressed: () => _pickDate(isStart: true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('to'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_endDate),
                    onPressed: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => const ContentSkeleton(type: ContentSkeletonType.list),
              error: (e, _) => ErrorView(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(employeeAttendanceHistoryProvider(params)),
              ),
              data: (state) => Column(
                children: [
                  _SummaryRow(summary: state.summary),
                  const Divider(height: 1),
                  Expanded(
                    child: state.records.isEmpty
                        ? const EmptyStateView(
                            icon: Icons.event_busy_outlined,
                            title: 'No attendance records',
                            subtitle: 'There are no entries for this date range.',
                          )
                        : ListView.builder(
                            itemCount: state.records.length,
                            itemBuilder: (_, i) {
                              final r = state.records[i];
                              return ListTile(
                                dense: true,
                                leading: _statusIcon(r.status),
                                title: Text(
                                  DateFormat('EEE, dd MMM').format(DateTime.parse(r.date)),
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: r.checkInTime != null
                                    ? Text('${r.checkInTime} - ${r.checkOutTime ?? '?'}',
                                        style: const TextStyle(fontSize: 12))
                                    : null,
                                trailing: Text(
                                  r.statusLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _statusColor(r.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
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

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(isStart ? _startDate : _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked.toString().split(' ')[0];
        } else {
          _endDate = picked.toString().split(' ')[0];
        }
      });
    }
  }

  Widget _statusIcon(String? status) {
    final color = _statusColor(status);
    final letter = status != null ? status[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(letter, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'present': return Colors.green;
      case 'half_day': return Colors.orange;
      case 'absent': return Colors.red;
      case 'leave': return Colors.blue;
      case 'holiday': return Colors.purple;
      default: return Colors.grey;
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final Map<String, int> summary;
  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 12,
        children: [
          _item('Present', summary['present'] ?? 0, Colors.green),
          _item('Half', summary['half_day'] ?? 0, Colors.orange),
          _item('Absent', summary['absent'] ?? 0, Colors.red),
          _item('Leave', summary['leave'] ?? 0, Colors.blue),
          _item('Holiday', summary['holiday'] ?? 0, Colors.purple),
        ],
      ),
    );
  }

  Widget _item(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

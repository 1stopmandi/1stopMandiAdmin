import 'package:flutter/material.dart';
import '../../../../shared/widgets/skeleton_card.dart';
import '../../../../shared/widgets/error_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/dashboard_provider.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../../../core/widgets/admin_menu_button.dart';

class EmployeeDashboardScreen extends ConsumerWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(employeeDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Employee Dashboard'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(employeeDashboardProvider.notifier).refresh(),
          ),
        ],
      ),
      body: metricsAsync.when(
        loading: () => const ContentSkeleton(type: ContentSkeletonType.dashboard),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (metrics) => RefreshIndicator(
          onRefresh: () => ref.read(employeeDashboardProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionTitle('Workforce'),
              Row(
                children: [
                  Expanded(child: _StatCard(
                    label: 'Total',
                    value: '${metrics.totalEmployees}',
                    icon: Icons.people,
                    color: Colors.blue,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(
                    label: 'Active',
                    value: '${metrics.activeEmployees}',
                    icon: Icons.person,
                    color: Colors.green,
                  )),
                ],
              ),
              const SizedBox(height: 16),
              _SectionTitle("Today's Attendance"),
              Row(
                children: [
                  Expanded(child: _StatCard(
                    label: 'Present',
                    value: '${metrics.todayPresent}',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(
                    label: 'Half Day',
                    value: '${metrics.todayHalfDay}',
                    icon: Icons.timelapse,
                    color: Colors.orange,
                  )),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _StatCard(
                    label: 'Absent',
                    value: '${metrics.todayAbsent}',
                    icon: Icons.cancel,
                    color: Colors.red,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(
                    label: 'Unmarked',
                    value: '${metrics.todayUnmarked}',
                    icon: Icons.help_outline,
                    color: Colors.grey,
                  )),
                ],
              ),
              const SizedBox(height: 8),
              _AttendanceBar(metrics: metrics),
              const SizedBox(height: 16),
              _SectionTitle('Salary (${metrics.month})'),
              Row(
                children: [
                  Expanded(child: _StatCard(
                    label: 'Pending',
                    value: '₹${_compact(metrics.salaryPendingAmount)}',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                    subtitle: '${metrics.salaryPendingCount} periods',
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(
                    label: 'Paid',
                    value: '₹${_compact(metrics.salaryPaidThisMonth)}',
                    icon: Icons.paid,
                    color: Colors.green,
                  )),
                ],
              ),
              const SizedBox(height: 24),
              _QuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  String _compact(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(subtitle!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceBar extends StatelessWidget {
  final EmployeeDashboardMetrics metrics;
  const _AttendanceBar({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Attendance Rate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('${metrics.attendancePercentage}%',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green[700])),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: metrics.attendancePercentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                color: Colors.green[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionChip(
              label: 'Mark Attendance',
              icon: Icons.fact_check,
              onTap: () => context.go('/attendance'),
            ),
            _ActionChip(
              label: 'View Employees',
              icon: Icons.badge,
              onTap: () => context.go('/employees'),
            ),
            _ActionChip(
              label: 'Generate Salary',
              icon: Icons.calculate,
              onTap: () => context.push('/salary/generate'),
            ),
            _ActionChip(
              label: 'Salary Periods',
              icon: Icons.account_balance_wallet,
              onTap: () => context.go('/salary'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

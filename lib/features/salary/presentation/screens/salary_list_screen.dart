import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/salary_provider.dart';
import '../../data/models/salary.dart';
import '../../../../core/widgets/admin_menu_button.dart';

class SalaryListScreen extends ConsumerWidget {
  const SalaryListScreen({super.key});

  static const _statusFilters = [
    (null, 'All'),
    ('generated', 'Generated'),
    ('partial', 'Partial'),
    ('paid', 'Paid'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(salaryPeriodsListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Salary Periods'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(salaryPeriodsListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/salary/generate'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.calculate),
        label: const Text('Generate'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.map((f) {
                  final selected = (listAsync.valueOrNull?.statusFilter) == f.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(f.$2),
                      selected: selected,
                      onSelected: (_) =>
                          ref.read(salaryPeriodsListProvider.notifier).setStatusFilter(f.$1),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (state) {
                if (state.periods.isEmpty) {
                  return const Center(child: Text('No salary periods found'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(salaryPeriodsListProvider.notifier).refresh(),
                  child: ListView.builder(
                    itemCount: state.periods.length + (state.currentPage < state.totalPages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.periods.length) {
                        ref.read(salaryPeriodsListProvider.notifier).nextPage();
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _PeriodCard(period: state.periods[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final SalaryPeriod period;
  const _PeriodCard({required this.period});

  Color _statusColor() {
    switch (period.status) {
      case 'generated': return Colors.blue;
      case 'partial': return Colors.orange;
      case 'paid': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text(
          period.employeeName ?? 'Employee',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${period.periodStart} → ${period.periodEnd}\n${period.employeeCode ?? ''}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${period.finalPayable.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusColor()),
              ),
              child: Text(
                period.statusLabel,
                style: TextStyle(fontSize: 11, color: _statusColor(), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        onTap: () => context.push('/salary/${period.id}'),
      ),
    );
  }
}

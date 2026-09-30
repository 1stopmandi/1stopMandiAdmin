import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/employees_provider.dart';
import '../../../../core/widgets/admin_menu_button.dart';
import '../../data/models/employee.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_card.dart';

class EmployeesListScreen extends ConsumerStatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  ConsumerState<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends ConsumerState<EmployeesListScreen> {
  final _searchCtrl = TextEditingController();

  static const _statusFilters = [
    ('all', 'All'),
    ('active', 'Active'),
    ('inactive', 'Inactive'),
    ('left', 'Left'),
  ];


  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(employeesListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Employees'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(employeesListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/employees/new'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search name or mobile...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(employeesListProvider.notifier).search('');
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) => ref.read(employeesListProvider.notifier).search(v),
              onChanged: (v) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statusFilters.map((f) {
                        final selected = (listAsync.valueOrNull?.statusFilter ?? 'all') == f.$1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(f.$2),
                            selected: selected,
                            onSelected: (_) =>
                                ref.read(employeesListProvider.notifier).setStatusFilter(f.$1),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const ContentSkeleton(type: ContentSkeletonType.list),
              error: (e, _) => ErrorView(
                message: friendlyError(e),
                onRetry: () => ref.read(employeesListProvider.notifier).refresh(),
              ),
              data: (state) {
                if (state.employees.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.badge_outlined,
                    title: 'No employees found',
                    subtitle: 'Add an employee or change the active filters.',
                    actionLabel: 'Add employee',
                    onAction: () => context.push('/employees/new'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(employeesListProvider.notifier).refresh(),
                  child: ListView.builder(
                    itemCount: state.employees.length + (state.currentPage < state.totalPages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.employees.length) {
                        ref.read(employeesListProvider.notifier).nextPage();
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: SizedBox(height: 90, child: ContentSkeleton(type: ContentSkeletonType.list, itemCount: 1, padding: EdgeInsets.zero)),
                        );
                      }
                      final emp = state.employees[index];
                      return _EmployeeCard(employee: emp);
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

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  const _EmployeeCard({required this.employee});

  Color _statusColor() {
    switch (employee.status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'left':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Text(
            employee.fullName.isNotEmpty ? employee.fullName[0].toUpperCase() : '?',
            style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(employee.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${employee.employeeCode} • ${employee.designationLabel}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusColor()),
              ),
              child: Text(
                employee.statusLabel,
                style: TextStyle(fontSize: 11, color: _statusColor(), fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${employee.monthlySalary.toStringAsFixed(0)}/mo',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () => context.push('/employees/${employee.id}'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_reports_provider.dart';
import '../../../../core/widgets/admin_menu_button.dart';

class InventoryReportsHomeScreen extends ConsumerWidget {
  const InventoryReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportsDateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Inventory Reports'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DateRangePicker(start: range.start, end: range.end),
          const SizedBox(height: 16),
          _ReportTile(
            icon: Icons.summarize,
            title: 'Inventory Summary',
            subtitle: 'Total records, quantities, percentages',
            onTap: () => context.push('/inventory-mgmt/reports/summary'),
          ),
          _ReportTile(
            icon: Icons.eco,
            title: 'Product-wise Summary',
            subtitle: 'Per-product breakdown across all records',
            onTap: () => context.push('/inventory-mgmt/reports/products'),
          ),
          _ReportTile(
            icon: Icons.delete_outline,
            title: 'Waste Summary',
            subtitle: 'Products with highest waste percentage',
            onTap: () => context.push('/inventory-mgmt/reports/waste'),
          ),
          _ReportTile(
            icon: Icons.recycling,
            title: 'Recoverable Summary',
            subtitle: 'Recoverable stock for hotel/bulk sales',
            onTap: () => context.push('/inventory-mgmt/reports/recoverable'),
          ),
          _ReportTile(
            icon: Icons.person,
            title: 'Employee Purchase Summary',
            subtitle: 'Who purchased how much, waste per buyer',
            onTap: () => context.push('/inventory-mgmt/reports/employees'),
          ),
        ],
      ),
    );
  }
}

class _DateRangePicker extends ConsumerWidget {
  final String start;
  final String end;
  const _DateRangePicker({required this.start, required this.end});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.date_range, size: 20, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => _pickRange(context, ref),
                child: Text(
                  '${_formatDate(start)}  —  ${_formatDate(end)}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
            ),
            TextButton(
              onPressed: () => _pickRange(context, ref),
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  void _pickRange(BuildContext context, WidgetRef ref) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.parse(start),
        end: DateTime.parse(end),
      ),
    );
    if (picked != null) {
      ref.read(reportsDateRangeProvider.notifier).state = (
        start: DateFormat('yyyy-MM-dd').format(picked.start),
        end: DateFormat('yyyy-MM-dd').format(picked.end),
      );
    }
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ReportTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.green[800]),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

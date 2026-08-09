import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_reports_provider.dart';

class InventoryReportViewScreen extends ConsumerWidget {
  final String reportType;
  const InventoryReportViewScreen({super.key, required this.reportType});

  String get _title {
    switch (reportType) {
      case 'summary':
        return 'Inventory Summary';
      case 'products':
        return 'Product-wise Summary';
      case 'waste':
        return 'Waste Summary';
      case 'recoverable':
        return 'Recoverable Summary';
      case 'employees':
        return 'Employee Summary';
      default:
        return 'Report';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportsDateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${_formatDate(range.start)}  —  ${_formatDate(range.end)}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(child: _buildReport(ref)),
        ],
      ),
    );
  }

  Widget _buildReport(WidgetRef ref) {
    switch (reportType) {
      case 'summary':
        return _SummaryReport();
      case 'products':
        return _ProductReport();
      case 'waste':
        return _WasteReport();
      case 'recoverable':
        return _RecoverableReport();
      case 'employees':
        return _EmployeeReport();
      default:
        return const Center(child: Text('Unknown report type'));
    }
  }

  String _formatDate(String date) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
}

class _SummaryReport extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(inventorySummaryReportProvider);
    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (summary) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard('Total Records', '${summary.totalRecords}', Icons.description),
          _SummaryCard('Total Purchased', '${summary.totalPurchasedQty.toStringAsFixed(0)} kg', Icons.shopping_cart),
          _SummaryCard('Good Stock', '${summary.totalGoodStock.toStringAsFixed(0)} kg (${summary.goodStockPercentage.toStringAsFixed(1)}%)', Icons.check_circle, color: Colors.green),
          _SummaryCard('Recoverable', '${summary.totalRecoverable.toStringAsFixed(0)} kg (${summary.recoverablePercentage.toStringAsFixed(1)}%)', Icons.recycling, color: Colors.orange),
          _SummaryCard('Final Waste', '${summary.totalFinalWaste.toStringAsFixed(0)} kg (${summary.wastePercentage.toStringAsFixed(1)}%)', Icons.delete_outline, color: Colors.red),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  const _SummaryCard(this.title, this.value, this.icon, {this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.green),
        title: Text(title),
        trailing: Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}

class _ProductReport extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(productReportProvider);
    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (products) => products.isEmpty
          ? const Center(child: Text('No data for this period'))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 14,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 36,
                  headingRowHeight: 40,
                  columns: const [
                    DataColumn(label: Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Purchased', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
                    DataColumn(label: Text('Good', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
                    DataColumn(label: Text('Recover.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
                    DataColumn(label: Text('Waste', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
                    DataColumn(label: Text('Waste%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
                    DataColumn(label: Text('Records', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
                  ],
                  rows: products.map((p) => DataRow(cells: [
                    DataCell(Text('${p.productName} (${p.unit})', style: const TextStyle(fontSize: 12))),
                    DataCell(Text(p.totalPurchased.toStringAsFixed(0), style: const TextStyle(fontSize: 12))),
                    DataCell(Text(p.totalGoodStock.toStringAsFixed(0), style: const TextStyle(fontSize: 12, color: Colors.green))),
                    DataCell(Text(p.totalRecoverable.toStringAsFixed(0), style: const TextStyle(fontSize: 12, color: Colors.orange))),
                    DataCell(Text(p.totalWaste.toStringAsFixed(0), style: const TextStyle(fontSize: 12, color: Colors.red))),
                    DataCell(Text('${p.wastePercentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12))),
                    DataCell(Text('${p.recordCount}', style: const TextStyle(fontSize: 12))),
                  ])).toList(),
                ),
              ),
            ),
    );
  }
}

class _WasteReport extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(wasteReportProvider);
    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (products) => products.isEmpty
          ? const Center(child: Text('No data for this period'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              itemBuilder: (ctx, i) {
                final p = products[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: _wasteColor(p.wastePercentage).withValues(alpha: 0.15),
                      child: Text('${i + 1}', style: TextStyle(fontSize: 11, color: _wasteColor(p.wastePercentage))),
                    ),
                    title: Text(p.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: Text('Purchased: ${p.totalPurchased.toStringAsFixed(0)} ${p.unit} | Waste: ${p.totalWaste.toStringAsFixed(0)} ${p.unit}',
                        style: const TextStyle(fontSize: 11)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _wasteColor(p.wastePercentage).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${p.wastePercentage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _wasteColor(p.wastePercentage)),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _wasteColor(double pct) {
    if (pct > 7) return Colors.red;
    if (pct > 4) return Colors.orange;
    return Colors.green;
  }
}

class _RecoverableReport extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(recoverableReportProvider);
    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (products) => products.isEmpty
          ? const Center(child: Text('No data for this period'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              itemBuilder: (ctx, i) {
                final p = products[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.orange.withValues(alpha: 0.15),
                      child: Text('${i + 1}', style: const TextStyle(fontSize: 11, color: Colors.orange)),
                    ),
                    title: Text(p.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      'Purchased: ${p.totalPurchased.toStringAsFixed(0)} ${p.unit} | Recoverable: ${p.totalRecoverable.toStringAsFixed(0)} ${p.unit}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      '${p.recoverablePercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _EmployeeReport extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(employeeReportProvider);
    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (employees) => employees.isEmpty
          ? const Center(child: Text('No data for this period'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: employees.length,
              itemBuilder: (ctx, i) {
                final e = employees[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.green.withValues(alpha: 0.15),
                      child: Text(e.employeeName[0], style: const TextStyle(fontSize: 12, color: Colors.green)),
                    ),
                    title: Text(e.employeeName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      'Records: ${e.recordCount} | Purchased: ${e.totalPurchased.toStringAsFixed(0)} kg | Waste: ${e.totalWaste.toStringAsFixed(0)} kg',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      '${e.avgWastePercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: e.avgWastePercentage > 5 ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

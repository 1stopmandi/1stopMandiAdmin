import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_provider.dart';
import '../../data/models/inventory_record.dart';
import '../../data/models/inventory_item.dart';
import '../utils/inventory_export.dart';

class InventoryDetailScreen extends ConsumerWidget {
  final String recordId;
  const InventoryDetailScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(inventoryDetailProvider(recordId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Detail'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          detailAsync.whenOrNull(
                data: (record) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => context.push('/inventory-mgmt/${record.id}/edit'),
                      child: const Text('Edit', style: TextStyle(color: Colors.white)),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (action) => _handleAction(context, ref, action, record),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        if (record.isFinalized) ...[
                          const PopupMenuItem(value: 'share_pdf', child: Text('Share as PDF')),
                          const PopupMenuItem(value: 'share_csv', child: Text('Share as CSV')),
                        ],
                        if (record.isDraft)
                          const PopupMenuItem(value: 'finalize', child: Text('Finalize')),
                        if (record.isFinalized)
                          const PopupMenuItem(value: 'unfinalize', child: Text('Un-finalize')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      floatingActionButton: detailAsync.whenOrNull(
        data: (record) => record.isFinalized
            ? FloatingActionButton.extended(
                onPressed: () => _showShareOptions(context, record),
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              )
            : FloatingActionButton.extended(
                onPressed: () => context.push('/inventory-mgmt/${record.id}/edit'),
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                icon: const Icon(Icons.edit),
                label: const Text('Edit Record'),
              ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (record) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderSection(record: record),
              const SizedBox(height: 16),
              _ItemsTable(items: record.items),
              const SizedBox(height: 16),
              _SummarySection(record: record),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareOptions(BuildContext context, InventoryRecord record) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Share', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Share as PDF'),
              subtitle: const Text('Professional report with summary'),
              onTap: () {
                Navigator.pop(ctx);
                _shareExport(context, record, 'pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Share as CSV'),
              subtitle: const Text('Spreadsheet-friendly format'),
              onTap: () {
                Navigator.pop(ctx);
                _shareExport(context, record, 'csv');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _shareExport(BuildContext context, InventoryRecord record, String format) async {
    try {
      final file = format == 'pdf'
          ? await InventoryExport.generatePdf(record)
          : await InventoryExport.generateCsv(record);

      await InventoryExport.shareFile(
        file,
        '1StopMandi Inventory: ${record.title}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action, InventoryRecord record) async {
    switch (action) {
      case 'edit':
        context.push('/inventory-mgmt/${record.id}/edit');
        break;
      case 'share_pdf':
        _shareExport(context, record, 'pdf');
        break;
      case 'share_csv':
        _shareExport(context, record, 'csv');
        break;
      case 'finalize':
        try {
          await ref.read(inventoryDetailProvider(recordId).notifier).finalizeRecord();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Record finalized'), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e'), backgroundColor: Colors.red),
            );
          }
        }
        break;
      case 'unfinalize':
        try {
          await ref.read(inventoryDetailProvider(recordId).notifier).unfinalizeRecord();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Record un-finalized'), backgroundColor: Colors.orange),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e'), backgroundColor: Colors.red),
            );
          }
        }
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Record?'),
            content: const Text('This will soft-delete the record. It can be restored later.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          try {
            await ref.read(inventoryDetailProvider(recordId).notifier).deleteRecord();
            if (context.mounted) context.pop();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$e'), backgroundColor: Colors.red),
              );
            }
          }
        }
        break;
    }
  }
}

class _HeaderSection extends StatelessWidget {
  final InventoryRecord record;
  const _HeaderSection({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(_formatDate(record.recordDate), style: TextStyle(color: Colors.grey[700])),
                const SizedBox(width: 16),
                if (record.purchasedByName != null) ...[
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(record.purchasedByName!, style: TextStyle(color: Colors.grey[700])),
                ],
              ],
            ),
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(record.notes!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: record.isDraft
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                record.isDraft ? 'Draft' : 'Finalized',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: record.isDraft ? Colors.orange[800] : Colors.green[800],
                ),
              ),
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
}

class _ItemsTable extends StatelessWidget {
  final List<InventoryItem> items;
  const _ItemsTable({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Products (${items.length})',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 36,
                headingRowHeight: 36,
                columns: const [
                  DataColumn(label: Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Purchased', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
                  DataColumn(label: Text('Good', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
                  DataColumn(label: Text('Recover.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
                  DataColumn(label: Text('Waste', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
                ],
                rows: items.map((item) => DataRow(cells: [
                  DataCell(Text('${item.productName ?? ''} (${item.unit})', style: const TextStyle(fontSize: 12))),
                  DataCell(Text(item.purchasedQty.toStringAsFixed(1), style: const TextStyle(fontSize: 12))),
                  DataCell(Text(item.goodStock.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: Colors.green))),
                  DataCell(Text(item.recoverable.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: Colors.orange))),
                  DataCell(Text(item.finalWaste.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: Colors.red))),
                ])).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final InventoryRecord record;
  const _SummarySection({required this.record});

  @override
  Widget build(BuildContext context) {
    final goodPct = record.goodStockPercentage;
    final wastePct = record.wastePercentage;
    final recoverPct = record.totalPurchasedQty > 0
        ? (record.totalRecoverable / record.totalPurchasedQty) * 100
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Summary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            _BarStat('Good Stock', goodPct, Colors.green),
            const SizedBox(height: 8),
            _BarStat('Recoverable', recoverPct, Colors.orange),
            const SizedBox(height: 8),
            _BarStat('Waste', wastePct, Colors.red),
            const SizedBox(height: 12),
            Row(
              children: [
                _TotalChip('Total: ${record.totalPurchasedQty.toStringAsFixed(0)} kg'),
                const SizedBox(width: 8),
                _TotalChip('Good: ${record.totalGoodStock.toStringAsFixed(0)} kg'),
                const SizedBox(width: 8),
                _TotalChip('Waste: ${record.totalFinalWaste.toStringAsFixed(0)} kg'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BarStat extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;
  const _BarStat(this.label, this.percentage, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (percentage / 100).clamp(0.0, 1.0),
          backgroundColor: Colors.grey[200],
          color: color,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}

class _TotalChip extends StatelessWidget {
  final String text;
  const _TotalChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

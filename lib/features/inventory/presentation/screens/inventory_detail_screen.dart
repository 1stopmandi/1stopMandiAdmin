import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/inventory_record.dart';
import '../../providers/inventory_provider.dart';
import '../utils/inventory_export.dart';

class InventoryDetailScreen extends ConsumerWidget {
  final String recordId;

  const InventoryDetailScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(inventoryDetailProvider(recordId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Detail'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          detail.whenOrNull(
                data: (record) => PopupMenuButton<String>(
                  onSelected: (action) =>
                      _handleAction(context, ref, action, record),
                  itemBuilder: (_) => [
                    if (record.isDraft)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (record.isFinalized) ...[
                      const PopupMenuItem(
                        value: 'share_pdf',
                        child: Text('Share as PDF'),
                      ),
                      const PopupMenuItem(
                        value: 'share_csv',
                        child: Text('Share as CSV'),
                      ),
                      const PopupMenuItem(
                        value: 'unfinalize',
                        child: Text('Unfinalize'),
                      ),
                    ],
                    if (record.isDraft)
                      const PopupMenuItem(
                        value: 'finalize',
                        child: Text('Finalize'),
                      ),
                    if (record.isDraft)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                  ],
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      floatingActionButton: detail.whenOrNull(
        data: (record) => record.isDraft
            ? FloatingActionButton.extended(
                onPressed: () =>
                    context.push('/inventory-mgmt/${record.id}/edit'),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Record'),
              )
            : FloatingActionButton.extended(
                onPressed: () => _showShareOptions(context, record),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (record) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _Header(record: record),
            const SizedBox(height: 12),
            _PurchasingSection(record: record),
            const SizedBox(height: 12),
            _DispatchSection(record: record),
            const SizedBox(height: 12),
            _DamageSection(record: record),
            const SizedBox(height: 12),
            _Summary(record: record),
          ],
        ),
      ),
    );
  }

  void _showShareOptions(BuildContext context, InventoryRecord record) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Share as PDF'),
              onTap: () {
                Navigator.pop(sheetContext);
                _share(context, record, 'pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Share as CSV'),
              onTap: () {
                Navigator.pop(sheetContext);
                _share(context, record, 'csv');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share(
    BuildContext context,
    InventoryRecord record,
    String format,
  ) async {
    try {
      final file = format == 'pdf'
          ? await InventoryExport.generatePdf(record)
          : await InventoryExport.generateCsv(record);
      await InventoryExport.shareFile(
        file,
        '1StopMandi Inventory: ${record.displayTitle}',
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    InventoryRecord record,
  ) async {
    if (action == 'edit') {
      context.push('/inventory-mgmt/${record.id}/edit');
      return;
    }
    if (action == 'share_pdf' || action == 'share_csv') {
      await _share(context, record, action == 'share_pdf' ? 'pdf' : 'csv');
      return;
    }
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete Record?'),
          content: const Text('This record can be restored later.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await ref.read(inventoryDetailProvider(recordId).notifier).deleteRecord();
      if (context.mounted) context.pop();
      return;
    }

    try {
      final notifier = ref.read(inventoryDetailProvider(recordId).notifier);
      if (action == 'finalize') {
        await notifier.finalizeRecord();
      } else if (action == 'unfinalize') {
        await notifier.unfinalizeRecord();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'finalize' ? 'Record finalized' : 'Record unfinalized',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _Header extends StatelessWidget {
  final InventoryRecord record;

  const _Header({required this.record});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.displayTitle,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_date(record.recordDate)),
              if (record.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(record.notes!),
              ],
              const SizedBox(height: 8),
              Chip(
                label: Text(record.isDraft ? 'Draft' : 'Finalized'),
                backgroundColor:
                    record.isDraft ? Colors.orange[50] : Colors.green[50],
              ),
            ],
          ),
        ),
      );
}

class _PurchasingSection extends StatelessWidget {
  final InventoryRecord record;

  const _PurchasingSection({required this.record});

  @override
  Widget build(BuildContext context) => _DetailSection(
        title: 'Purchasing (${record.purchasingBatchCount} batches)',
        initiallyExpanded: true,
        children: record.purchasingBatches.isEmpty
            ? const [Text('No purchasing batches')]
            : record.purchasingBatches
                .map(
                  (batch) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_source(batch.purchaseSource)} • '
                          'Grand total ₹${batch.grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        _table(
                          const [
                            'Product',
                            'Weight',
                            'Rate',
                            'Amount',
                            'Labour'
                          ],
                          batch.items
                              .map(
                                (item) => [
                                  item.productName ?? '',
                                  '${item.weight.toStringAsFixed(2)} kg',
                                  '₹${item.rate.toStringAsFixed(2)}',
                                  '₹${item.amount.toStringAsFixed(2)}',
                                  '₹${item.labourCharge.toStringAsFixed(2)}',
                                ],
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Items ₹${batch.totalAmount.toStringAsFixed(2)} • '
                          'Labour ₹${batch.totalLabourCharge.toStringAsFixed(2)} • '
                          'Transport ₹${batch.transportationCharge.toStringAsFixed(2)} • '
                          'Other ₹${batch.otherCharges.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      );
}

class _DispatchSection extends StatelessWidget {
  final InventoryRecord record;

  const _DispatchSection({required this.record});

  @override
  Widget build(BuildContext context) => _DetailSection(
        title: 'Dispatch (${record.dispatchItemCount})',
        children: [
          if (record.dispatchItems.isEmpty)
            const Text('No dispatch rows')
          else
            _table(
              const [
                'Product',
                'Dispatch To',
                'Pocket',
                'Weight',
                'Rate',
                'Amount'
              ],
              record.dispatchItems
                  .map(
                    (item) => [
                      item.productName ?? '',
                      item.dispatchToLabel,
                      '${item.pocket}',
                      '${item.weight.toStringAsFixed(2)} kg',
                      '₹${item.rate.toStringAsFixed(2)}',
                      '₹${item.amount.toStringAsFixed(2)}',
                    ],
                  )
                  .toList(),
            ),
          if (record.dispatchItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Total ${record.totalDispatchWeight.toStringAsFixed(2)} kg • '
                '₹${record.totalDispatchAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      );
}

class _DamageSection extends StatelessWidget {
  final InventoryRecord record;

  const _DamageSection({required this.record});

  @override
  Widget build(BuildContext context) => _DetailSection(
        title: 'Damage (${record.damageItemCount})',
        children: [
          if (record.damageItems.isEmpty)
            const Text('No damage rows')
          else
            _table(
              const ['Product', 'By', 'Damage', 'Recovered', 'Waste'],
              record.damageItems
                  .map(
                    (item) => [
                      item.productName ?? '',
                      _source(item.damageBy),
                      '${item.damageQty.toStringAsFixed(2)} kg',
                      '${item.recoverQty.toStringAsFixed(2)} kg',
                      '${item.wasteQty.toStringAsFixed(2)} kg',
                    ],
                  )
                  .toList(),
            ),
        ],
      );
}

class _Summary extends StatelessWidget {
  final InventoryRecord record;

  const _Summary({required this.record});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _stat('Purchase grand total',
                  '₹${record.purchasingGrandTotal.toStringAsFixed(2)}'),
              _stat('Purchased weight',
                  '${record.totalPurchasedWeight.toStringAsFixed(2)} kg'),
              _stat('Dispatch total',
                  '₹${record.totalDispatchAmount.toStringAsFixed(2)}'),
              _stat('Dispatch weight',
                  '${record.totalDispatchWeight.toStringAsFixed(2)} kg'),
              _stat(
                  'Damaged', '${record.totalDamageQty.toStringAsFixed(2)} kg'),
              _stat('Recovered',
                  '${record.totalRecoverQty.toStringAsFixed(2)} kg'),
              _stat('Waste', '${record.totalWasteQty.toStringAsFixed(2)} kg'),
            ],
          ),
        ),
      );
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  const _DetailSection({
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: children,
        ),
      );
}

Widget _table(List<String> headings, List<List<String>> rows) =>
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: headings
            .map(
              (heading) => DataColumn(
                label: Text(
                  heading,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
            .toList(),
        rows: rows
            .map(
              (row) => DataRow(
                cells: row.map((value) => DataCell(Text(value))).toList(),
              ),
            )
            .toList(),
      ),
    );

Widget _stat(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );

String _source(String value) => value == 'quicklo' ? 'Quicklo' : 'Om';

String _date(String value) {
  final parsed = DateTime.tryParse(value);
  return parsed == null ? value : DateFormat('dd MMM yyyy').format(parsed);
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/models/inventory_record.dart';

class InventoryExport {
  static Future<File> generatePdf(InventoryRecord record) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Text(
            '1StopMandi - Inventory Report',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            record.displayTitle,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Date: ${_formatDate(record.recordDate)}'),
          pw.Text('Status: ${record.isFinalized ? 'Finalized' : 'Draft'}'),
          if (record.notes?.isNotEmpty == true)
            pw.Text('Notes: ${record.notes}'),
          pw.SizedBox(height: 16),
          _heading('Purchasing'),
          if (record.purchasingBatches.isEmpty)
            pw.Text('No purchasing batches')
          else
            ...record.purchasingBatches.asMap().entries.expand(
                  (entry) => [
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Batch ${entry.key + 1} - ${_source(entry.value.purchaseSource)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    _table(
                      ['Product', 'Weight kg', 'Rate', 'Amount', 'Labour'],
                      entry.value.items
                          .map(
                            (item) => [
                              item.productName ?? '',
                              item.weight.toStringAsFixed(2),
                              item.rate.toStringAsFixed(2),
                              item.amount.toStringAsFixed(2),
                              item.labourCharge.toStringAsFixed(2),
                            ],
                          )
                          .toList(),
                    ),
                    pw.Text(
                      'Items: Rs ${entry.value.totalAmount.toStringAsFixed(2)}  |  '
                      'Labour: Rs ${entry.value.totalLabourCharge.toStringAsFixed(2)}  |  '
                      'Transport: Rs ${entry.value.transportationCharge.toStringAsFixed(2)}  |  '
                      'Other: Rs ${entry.value.otherCharges.toStringAsFixed(2)}  |  '
                      'Grand total: Rs ${entry.value.grandTotal.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
          pw.SizedBox(height: 16),
          _heading('Dispatch'),
          if (record.dispatchItems.isEmpty)
            pw.Text('No dispatch rows')
          else
            _table(
              [
                'Product',
                'Dispatch To',
                'Pocket',
                'Weight kg',
                'Rate',
                'Amount'
              ],
              record.dispatchItems
                  .map(
                    (item) => [
                      item.productName ?? '',
                      item.dispatchToLabel,
                      item.pocket.toString(),
                      item.weight.toStringAsFixed(2),
                      item.rate.toStringAsFixed(2),
                      item.amount.toStringAsFixed(2),
                    ],
                  )
                  .toList(),
            ),
          pw.Text(
            'Dispatch total: ${record.totalDispatchWeight.toStringAsFixed(2)} kg  |  '
            'Rs ${record.totalDispatchAmount.toStringAsFixed(2)}',
          ),
          pw.SizedBox(height: 16),
          _heading('Damage'),
          if (record.damageItems.isEmpty)
            pw.Text('No damage rows')
          else
            _table(
              ['Product', 'By', 'Damage kg', 'Recovered kg', 'Waste kg'],
              record.damageItems
                  .map(
                    (item) => [
                      item.productName ?? '',
                      _source(item.damageBy),
                      item.damageQty.toStringAsFixed(2),
                      item.recoverQty.toStringAsFixed(2),
                      item.wasteQty.toStringAsFixed(2),
                    ],
                  )
                  .toList(),
            ),
          pw.SizedBox(height: 16),
          _heading('Summary'),
          pw.Text(
            'Purchased: ${record.totalPurchasedWeight.toStringAsFixed(2)} kg  |  '
            'Purchase grand total: Rs ${record.purchasingGrandTotal.toStringAsFixed(2)}',
          ),
          pw.Text(
            'Dispatched: ${record.totalDispatchWeight.toStringAsFixed(2)} kg  |  '
            'Dispatch total: Rs ${record.totalDispatchAmount.toStringAsFixed(2)}',
          ),
          pw.Text(
            'Damage: ${record.totalDamageQty.toStringAsFixed(2)} kg  |  '
            'Recovered: ${record.totalRecoverQty.toStringAsFixed(2)} kg  |  '
            'Waste: ${record.totalWasteQty.toStringAsFixed(2)} kg',
          ),
        ],
      ),
    );

    final file = await _outputFile(record, 'pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<File> generateCsv(InventoryRecord record) async {
    final output = StringBuffer()
      ..writeln('1StopMandi - Inventory Report')
      ..writeln('Title,${_csv(record.displayTitle)}')
      ..writeln('Date,${_csv(_formatDate(record.recordDate))}')
      ..writeln('Status,${record.isFinalized ? 'Finalized' : 'Draft'}')
      ..writeln('Notes,${_csv(record.notes ?? '')}')
      ..writeln()
      ..writeln('PURCHASING');

    for (final entry in record.purchasingBatches.asMap().entries) {
      final batch = entry.value;
      output
        ..writeln(
          'Batch,${entry.key + 1},Source,${_source(batch.purchaseSource)}',
        )
        ..writeln('Product,Weight kg,Rate,Amount,Labour Charge,Notes');
      for (final item in batch.items) {
        output.writeln(
          [
            item.productName ?? '',
            item.weight,
            item.rate,
            item.amount,
            item.labourCharge,
            item.notes ?? '',
          ].map((value) => _csv('$value')).join(','),
        );
      }
      output
        ..writeln(
          'Batch totals,,Items,${batch.totalAmount},Labour,${batch.totalLabourCharge},'
          'Transportation,${batch.transportationCharge},Other,${batch.otherCharges},'
          'Grand Total,${batch.grandTotal}',
        )
        ..writeln();
    }

    output
      ..writeln('DISPATCH')
      ..writeln('Product,Dispatch To,Pocket,Weight kg,Rate,Amount');
    for (final item in record.dispatchItems) {
      output.writeln(
        [
          item.productName ?? '',
          item.dispatchToLabel,
          item.pocket,
          item.weight,
          item.rate,
          item.amount,
        ].map((value) => _csv('$value')).join(','),
      );
    }
    output
      ..writeln('Dispatch total,,,,,${record.totalDispatchAmount}')
      ..writeln()
      ..writeln('DAMAGE')
      ..writeln('Product,Damage By,Damage kg,Recovered kg,Waste kg,Notes');
    for (final item in record.damageItems) {
      output.writeln(
        [
          item.productName ?? '',
          _source(item.damageBy),
          item.damageQty,
          item.recoverQty,
          item.wasteQty,
          item.notes ?? '',
        ].map((value) => _csv('$value')).join(','),
      );
    }
    output
      ..writeln()
      ..writeln('SUMMARY')
      ..writeln('Total purchased kg,${record.totalPurchasedWeight}')
      ..writeln('Purchase grand total,${record.purchasingGrandTotal}')
      ..writeln('Total dispatched kg,${record.totalDispatchWeight}')
      ..writeln('Dispatch total,${record.totalDispatchAmount}')
      ..writeln('Total damage kg,${record.totalDamageQty}')
      ..writeln('Total recovered kg,${record.totalRecoverQty}')
      ..writeln('Total waste kg,${record.totalWasteQty}');

    final file = await _outputFile(record, 'csv');
    await file.writeAsString(output.toString());
    return file;
  }

  static Future<void> shareFile(File file, String subject) async {
    try {
      await Share.shareXFiles([XFile(file.path)], subject: subject);
    } catch (error) {
      debugPrint('Share failed (expected on simulator): $error');
      rethrow;
    }
  }

  static pw.Widget _heading(String text) => pw.Text(
        text,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      );

  static pw.Widget _table(List<String> headers, List<List<String>> data) =>
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: data,
        headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 8),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      );

  static Future<File> _outputFile(
    InventoryRecord record,
    String extension,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final title = record.displayTitle
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(' ', '_');
    return File(
      '${directory.path}/inventory_${title}_${record.recordDate}.$extension',
    );
  }

  static String _csv(String value) =>
      '"${value.replaceAll('"', '""').replaceAll('\n', ' ')}"';

  static String _source(String value) => value == 'quicklo' ? 'Quicklo' : 'Om';

  static String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? value : DateFormat('dd MMM yyyy').format(date);
  }
}

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
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('1StopMandi - Inventory Report',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text(record.title,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Row(children: [
              pw.Text('Date: ${_formatDate(record.recordDate)}',
                  style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(width: 24),
              if (record.purchasedByName != null)
                pw.Text('Purchased By: ${record.purchasedByName}',
                    style: const pw.TextStyle(fontSize: 12)),
            ]),
            pw.SizedBox(height: 4),
            pw.Text('Status: Finalized',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700)),
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text('Notes: ${record.notes}', style: const pw.TextStyle(fontSize: 11)),
            ],
            pw.SizedBox(height: 20),
            pw.Text('Products',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _buildTable(record),
            pw.SizedBox(height: 20),
            pw.Text('Summary',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _buildSummary(record),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final sanitized = record.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');
    final file = File('${dir.path}/inventory_${sanitized}_${record.recordDate}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<File> generateCsv(InventoryRecord record) async {
    final buffer = StringBuffer();
    buffer.writeln('1StopMandi - Inventory Report');
    buffer.writeln('Title,${record.title}');
    buffer.writeln('Date,${_formatDate(record.recordDate)}');
    if (record.purchasedByName != null) {
      buffer.writeln('Purchased By,${record.purchasedByName}');
    }
    buffer.writeln('Status,Finalized');
    buffer.writeln();
    buffer.writeln('Product,Unit,Purchased,Good Stock,Recoverable,Waste');
    for (final item in record.items) {
      buffer.writeln(
        '${item.productName ?? ""},${item.unit},${item.purchasedQty},${item.goodStock},${item.recoverable},${item.finalWaste}',
      );
    }
    buffer.writeln();
    buffer.writeln('Total,,${record.totalPurchasedQty},${record.totalGoodStock},${record.totalRecoverable},${record.totalFinalWaste}');

    final dir = await getApplicationDocumentsDirectory();
    final sanitized = record.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');
    final file = File('${dir.path}/inventory_${sanitized}_${record.recordDate}.csv');
    await file.writeAsString(buffer.toString());
    return file;
  }

  static Future<void> shareFile(File file, String subject) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
      );
    } catch (e) {
      debugPrint('Share failed (expected on simulator): $e');
      rethrow;
    }
  }

  static pw.Widget _buildTable(InventoryRecord record) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
      headers: ['Product', 'Unit', 'Purchased', 'Good Stock', 'Recoverable', 'Waste'],
      data: [
        ...record.items.map((item) => [
          item.productName ?? '',
          item.unit,
          item.purchasedQty.toStringAsFixed(1),
          item.goodStock.toStringAsFixed(1),
          item.recoverable.toStringAsFixed(1),
          item.finalWaste.toStringAsFixed(1),
        ]),
        [
          'TOTAL', '',
          record.totalPurchasedQty.toStringAsFixed(1),
          record.totalGoodStock.toStringAsFixed(1),
          record.totalRecoverable.toStringAsFixed(1),
          record.totalFinalWaste.toStringAsFixed(1),
        ],
      ],
    );
  }

  static pw.Widget _buildSummary(InventoryRecord record) {
    final goodPct = record.goodStockPercentage.toStringAsFixed(1);
    final recoverPct = record.totalPurchasedQty > 0
        ? ((record.totalRecoverable / record.totalPurchasedQty) * 100).toStringAsFixed(1)
        : '0.0';
    final wastePct = record.wastePercentage.toStringAsFixed(1);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Good Stock: $goodPct%', style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 4),
        pw.Text('Recoverable: $recoverPct%', style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 4),
        pw.Text('Waste: $wastePct%', style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 8),
        pw.Text(
          'Total: ${record.totalPurchasedQty.toStringAsFixed(0)} kg  |  '
          'Good: ${record.totalGoodStock.toStringAsFixed(0)} kg  |  '
          'Waste: ${record.totalFinalWaste.toStringAsFixed(0)} kg',
          style: const pw.TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  static String _formatDate(String date) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
}

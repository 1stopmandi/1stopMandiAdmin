import 'package:flutter/material.dart';
import '../../../../shared/widgets/skeleton_card.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../core/network/api_exceptions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/salary_provider.dart';
import '../../data/models/salary.dart';

class SalaryDetailScreen extends ConsumerWidget {
  final String periodId;
  const SalaryDetailScreen({super.key, required this.periodId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(salaryPeriodDetailProvider(periodId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Detail'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          detailAsync.whenOrNull(
                data: (sp) => sp.status == 'generated' || sp.status == 'partial'
                    ? IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Recalculate',
                        onPressed: () => _recalculate(context, ref),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      floatingActionButton: detailAsync.whenOrNull(
        data: (sp) => sp.status != 'paid' && sp.status != 'cancelled'
            ? FloatingActionButton.extended(
                onPressed: () => _showPaymentDialog(context, ref, sp),
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                icon: const Icon(Icons.payment),
                label: const Text('Pay'),
              )
            : null,
      ),
      body: detailAsync.when(
        loading: () => const ContentSkeleton(type: ContentSkeletonType.detail),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(salaryPeriodDetailProvider(periodId)),
        ),
        data: (sp) => RefreshIndicator(
          onRefresh: () => ref.read(salaryPeriodDetailProvider(periodId).notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(period: sp),
              const SizedBox(height: 12),
              _BreakdownCard(period: sp),
              const SizedBox(height: 12),
              _PaymentSummaryCard(period: sp),
              if (sp.payments.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...sp.payments.map((p) => _PaymentTile(payment: p)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _recalculate(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(salaryPeriodDetailProvider(periodId).notifier)
          .recalculate();
      if (context.mounted) {
        AppToast.success(context, 'Salary recalculated');
      }
    } catch (error) {
      if (context.mounted) {
        AppToast.error(context, friendlyError(error));
      }
    }
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, SalaryPeriod sp) {
    final amountCtrl = TextEditingController(text: (sp.remaining ?? sp.finalPayable).toStringAsFixed(0));
    final refCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String method = 'cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Record Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  decoration: const InputDecoration(labelText: 'Method', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                  ],
                  onChanged: (v) => setDialogState(() => method = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refCtrl,
                  decoration: const InputDecoration(labelText: 'Transaction Ref', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || amount <= 0) {
                  AppToast.error(context, 'Enter a valid payment amount');
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(salaryPeriodDetailProvider(periodId).notifier)
                      .recordPayment(
                        amount: amount,
                        method: method,
                        date: DateTime.now().toString().split(' ')[0],
                        reference: refCtrl.text.trim().isNotEmpty
                            ? refCtrl.text.trim()
                            : null,
                        notes: notesCtrl.text.trim().isNotEmpty
                            ? notesCtrl.text.trim()
                            : null,
                      );
                  if (context.mounted) {
                    AppToast.success(context, 'Payment recorded');
                  }
                } catch (error) {
                  if (context.mounted) {
                    AppToast.error(context, friendlyError(error));
                  }
                }
              },
              child: const Text('Pay'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final SalaryPeriod period;
  const _HeaderCard({required this.period});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(period.employeeName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${period.employeeCode ?? ''} • ${period.periodStart} to ${period.periodEnd}'),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final SalaryPeriod period;
  const _BreakdownCard({required this.period});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(),
            _row('Daily Wage', '₹${period.dailyWage.toStringAsFixed(2)}'),
            _row('Present Days', '${period.presentDays}'),
            _row('Half Days', '${period.halfDays}'),
            _row('Absent Days', '${period.absentDays}'),
            _row('Leave Days', '${period.leaveDays}'),
            _row('Holiday Days', '${period.holidayDays}'),
            if (period.totalWorkingHours != null)
              _row('Working Hours', '${period.totalWorkingHours!.toStringAsFixed(1)}h'),
            const Divider(),
            _row('Gross Salary', '₹${period.grossSalary.toStringAsFixed(0)}'),
            _row('Previous Pending', '₹${period.previousPending.toStringAsFixed(0)}'),
            _row('Advances', '-₹${period.advances.toStringAsFixed(0)}'),
            const Divider(),
            _row('Final Payable', '₹${period.finalPayable.toStringAsFixed(0)}', bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : null)),
        ],
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  final SalaryPeriod period;
  const _PaymentSummaryCard({required this.period});

  @override
  Widget build(BuildContext context) {
    final paid = period.totalPaid ?? 0;
    final remaining = period.remaining ?? period.finalPayable;
    return Card(
      color: period.status == 'paid' ? Colors.green[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _metric('Paid', '₹${paid.toStringAsFixed(0)}', Colors.green),
            _metric('Remaining', '₹${remaining.toStringAsFixed(0)}', Colors.orange),
            _metric('Status', period.statusLabel, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final SalaryPayment payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.payment, size: 20),
        title: Text('₹${payment.amountPaid.toStringAsFixed(0)} via ${payment.methodLabel}'),
        subtitle: Text(payment.paymentDate),
        trailing: payment.transactionReference != null
            ? Text(payment.transactionReference!, style: const TextStyle(fontSize: 11))
            : null,
      ),
    );
  }
}

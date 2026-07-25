import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/orders_provider.dart';
import '../../../../data/models/order.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Detail'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (order) => _OrderDetailBody(order: order, orderId: orderId),
      ),
    );
  }
}

class _OrderDetailBody extends ConsumerWidget {
  final Order order;
  final String orderId;
  const _OrderDetailBody({required this.order, required this.orderId});

  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
  static const _rupee = '₹';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(orderDetailProvider(orderId).notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status banner
        _StatusBanner(status: order.status),
        const SizedBox(height: 16),

        // Order meta
        _SectionCard(
          title: 'Order Info',
          children: [
            _Row('Order #', order.orderNumber),
            _Row('Status', _formatStatus(order.status)),
            if (order.createdAt != null)
              _Row('Placed', _dateFmt.format(order.createdAt!.toLocal())),
            if (order.deliverBy != null)
              _Row('Deliver By',
                  _dateFmt.format(order.deliverBy!.toLocal()),
                  valueColor: Colors.orange),
            if (order.proposedDeliverBy != null)
              _Row('Proposed Time',
                  _dateFmt.format(order.proposedDeliverBy!.toLocal()),
                  valueColor: Colors.purple),
            if (order.extensionNote != null && order.extensionNote!.isNotEmpty)
              _Row('Extension Note', order.extensionNote!),
            if (order.rejectionReason != null)
              _Row('Rejection Reason', order.rejectionReason!,
                  valueColor: Colors.red),
            _Row('Total', '$_rupee${order.totalAmount.toStringAsFixed(2)}',
                bold: true),
          ],
        ),
        const SizedBox(height: 12),

        // Buyer info
        if (order.user != null) ...[
          _SectionCard(
            title: 'Buyer',
            children: [
              if (order.user!.businessName != null)
                _Row('Business', order.user!.businessName!),
              if (order.user!.name != null) _Row('Name', order.user!.name!),
              if (order.user!.phone != null) _Row('Phone', order.user!.phone!),
              if (order.user!.email != null) _Row('Email', order.user!.email!),
              if (order.user!.address != null)
                _Row('Address',
                    '${order.user!.address}, ${order.user!.pincode ?? ''}'),
              if (order.user!.gstNumber != null)
                _Row('GST', order.user!.gstNumber!),
              if (order.user!.fssaiNumber != null)
                _Row('FSSAI', order.user!.fssaiNumber!),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Delivery address
        if (order.deliveryAddress != null) ...[
          _SectionCard(
            title: 'Delivery Address',
            children: [
              _Row('Address',
                  '${order.deliveryAddress}, ${order.deliveryPincode ?? ''}'),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Items
        _SectionCard(
          title: 'Items (${order.items.length})',
          children: order.items
              .map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                              '${item.productName} (${item.unit})'),
                        ),
                        Text(
                          '${item.quantity.toStringAsFixed(1)} × $_rupee${item.priceApplied.toStringAsFixed(2)} = $_rupee${item.lineTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),

        // Action buttons
        _ActionButtons(order: order, notifier: notifier),
        const SizedBox(height: 32),
      ],
    );
  }

  static String _formatStatus(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

// ─── Action buttons (context-sensitive) ──────────────────────────────────────

class _ActionButtons extends ConsumerWidget {
  final Order order;
  final OrderDetailNotifier notifier;
  const _ActionButtons({required this.order, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (order.isPending) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Accept Order'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () => _accept(context),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule),
            label: const Text('Request Delivery Extension'),
            onPressed: () => _requestExtension(context),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Reject Order'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => _reject(context),
          ),
        ],
      );
    }

    if (order.isExtensionRequested) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Accept Original Time & Confirm'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () => _accept(context),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Reject Order'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => _reject(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Waiting for buyer to approve the proposed extension.',
            style: TextStyle(color: Colors.purple[700], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _accept(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Accept Order'),
        content: const Text('Confirm this order and notify the buyer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(_, true),
              child: const Text('Accept')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await notifier.accept();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Order accepted!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _reject(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                  hintText: 'e.g. We don\'t have all items',
                  border: OutlineInputBorder()),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(_, true);
            },
            child: const Text('Reject',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await notifier.reject(reasonCtrl.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Order rejected.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
    reasonCtrl.dispose();
  }

  Future<void> _requestExtension(BuildContext context) async {
    DateTime? picked;
    final noteCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Request Delivery Extension'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Select a new proposed delivery date & time:'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(picked != null
                    ? _fmt(picked!)
                    : 'Pick date & time'),
                onPressed: () async {
                  final now = DateTime.now();
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: now.add(const Duration(hours: 2)),
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 30)),
                  );
                  if (date == null) return;
                  final time = await showTimePicker(
                      context: ctx, initialTime: TimeOfDay.now());
                  if (time == null) return;
                  setDialogState(() {
                    picked = DateTime(date.year, date.month, date.day,
                        time.hour, time.minute);
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                    hintText: 'Note (optional)',
                    border: OutlineInputBorder()),
                minLines: 2,
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: picked == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Send Request'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || picked == null) return;
    try {
      await notifier.requestExtension(picked!, noteCtrl.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Extension request sent to buyer.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
    noteCtrl.dispose();
  }

  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
  static String _fmt(DateTime d) => _dateFmt.format(d);
}

// ─── UI components ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(_icon(status), color: color),
          const SizedBox(width: 10),
          Text(
            _label(status),
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static Color _color(String s) => switch (s) {
        'pending' => Colors.orange,
        'extension_requested' => Colors.purple,
        'confirmed' => Colors.blue,
        'out_for_delivery' => Colors.indigo,
        'delivered' => Colors.green,
        'rejected' => Colors.red,
        'cancelled' => Colors.grey,
        _ => Colors.grey,
      };

  static IconData _icon(String s) => switch (s) {
        'pending' => Icons.hourglass_empty,
        'extension_requested' => Icons.schedule,
        'confirmed' => Icons.check_circle,
        'out_for_delivery' => Icons.delivery_dining,
        'delivered' => Icons.done_all,
        'rejected' => Icons.cancel,
        'cancelled' => Icons.block,
        _ => Icons.info,
      };

  static String _label(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const Divider(),
              ...children,
            ],
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _Row(this.label, this.value,
      {this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontWeight: bold ? FontWeight.bold : null,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
}

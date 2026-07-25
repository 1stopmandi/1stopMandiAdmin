import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../providers/clients_provider.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/client_billing.dart';

class ClientDetailScreen extends ConsumerWidget {
  final String clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(clientDetailProvider(clientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Detail'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await context.push<bool>('/clients/$clientId/edit');
              if (updated == true) {
                ref.read(clientDetailProvider(clientId).notifier).refresh();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(clientDetailProvider(clientId).notifier).refresh(),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (state) => _ClientDetailBody(
          state: state,
          clientId: clientId,
        ),
      ),
    );
  }
}

class _ClientDetailBody extends ConsumerWidget {
  final ClientDetailState state;
  final String clientId;

  const _ClientDetailBody({required this.state, required this.clientId});

  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = state.client;
    final notifier = ref.read(clientDetailProvider(clientId).notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderBanner(client: client),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Profile',
          children: [
            _Row('Business', client.businessName),
            _Row('Contact', client.name),
            _Row('Owner', client.ownerName),
            _Row('Phone', client.phone),
            _Row('Email', client.email),
            _Row('Outlet type', client.outletType),
            _Row('Address', client.address != null
                ? '${client.address}${client.pincode != null ? ', ${client.pincode}' : ''}'
                : null),
            _Row('GST', client.gstNumber),
            _Row('FSSAI', client.fssaiNumber),
            _Row('Account', _label(client.accountStatus)),
            _Row('Setup completed', client.isSetupCompleted ? 'Yes' : 'No'),
            if (client.createdAt != null)
              _Row('Joined', _dateFmt.format(client.createdAt!.toLocal())),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Setup approval',
          children: [
            _Row('Status', _label(client.setupApprovalStatus)),
            if (client.setupAdminNote != null && client.setupAdminNote!.isNotEmpty)
              _Row('Admin note', client.setupAdminNote),
            if (client.setupReviewedAt != null)
              _Row(
                'Reviewed',
                _dateFmt.format(client.setupReviewedAt!.toLocal()),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (client.setupApprovalStatus != 'approved')
                  _ActionChip(
                    label: 'Approve',
                    color: Colors.green,
                    onTap: () => _setupApproval(context, notifier, 'approved'),
                  ),
                if (client.setupApprovalStatus != 'rejected')
                  _ActionChip(
                    label: 'Reject',
                    color: Colors.red,
                    onTap: () => _setupApproval(context, notifier, 'rejected'),
                  ),
                if (client.setupApprovalStatus != 'pending')
                  _ActionChip(
                    label: 'Reset pending',
                    color: Colors.orange,
                    onTap: () => _setupApproval(context, notifier, 'pending'),
                  ),
              ],
            ),
          ],
        ),
        if (state.billing != null) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Billing (all time)',
            children: [
              _Row(
                'Total billed',
                '₹${state.billing!.totalBilled.toStringAsFixed(2)}',
              ),
              _Row(
                'Total paid',
                '₹${state.billing!.totalPaid.toStringAsFixed(2)}',
              ),
              _Row(
                'Outstanding',
                '₹${state.billing!.outstanding.toStringAsFixed(2)}',
                valueColor: state.billing!.outstanding > 0
                    ? Colors.orange
                    : Colors.green,
                bold: true,
              ),
              _Row('Unpaid orders', '${state.billing!.unpaidOrders}'),
            ],
          ),
        ],
        if (state.billingOrders.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Recent orders (billing)',
            children: state.billingOrders.take(20).map((o) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${o.orderNumber}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${_label(o.status)} · ${_label(o.paymentStatus)} · ₹${o.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (o.isUnpaid)
                      TextButton(
                        onPressed: () =>
                            _markPaid(context, notifier, o),
                        child: const Text('Mark paid'),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 20),
        if (client.isBlocked)
          OutlinedButton.icon(
            icon: const Icon(Icons.lock_open),
            label: const Text('Unblock client'),
            onPressed: () => _toggleBlock(context, notifier, false),
          )
        else
          OutlinedButton.icon(
            icon: const Icon(Icons.block, color: Colors.red),
            label: const Text('Block client',
                style: TextStyle(color: Colors.red)),
            onPressed: () => _toggleBlock(context, notifier, true),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  static String _label(String? s) {
    if (s == null || s.isEmpty) return '—';
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Future<void> _setupApproval(
    BuildContext context,
    ClientDetailNotifier notifier,
    String status,
  ) async {
    String? note;
    if (status == 'rejected') {
      final noteCtrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Reject setup'),
          content: TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(
              hintText: 'Reason (optional)',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(_, true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      note = noteCtrl.text.trim();
    } else if (status == 'approved') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Approve setup'),
          content: const Text('Mark this client\'s setup as approved?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(_, true),
              child: const Text('Approve'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    try {
      await notifier.setSetupApproval(status, note: note);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup marked as ${_label(status)}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    }
  }

  Future<void> _toggleBlock(
    BuildContext context,
    ClientDetailNotifier notifier,
    bool block,
  ) async {
    String? reason;
    if (block) {
      final reasonCtrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Block client'),
          content: TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(
              hintText: 'Reason (optional)',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(_, true),
              child: const Text('Block', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (ok != true) return;
      reason = reasonCtrl.text.trim();
    }

    try {
      await notifier.setBlocked(block, reason: reason);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(block ? 'Client blocked' : 'Client unblocked')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    }
  }

  Future<void> _markPaid(
    BuildContext context,
    ClientDetailNotifier notifier,
    ClientBillingOrder order,
  ) async {
    final refCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Mark #${order.orderNumber} paid'),
        content: TextField(
          controller: refCtrl,
          decoration: const InputDecoration(
            labelText: 'Payment reference (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(_, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await notifier.markOrderPaid(
        order.id,
        reference: refCtrl.text.trim().isEmpty ? null : refCtrl.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order marked as paid')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    }
  }
}

class _HeaderBanner extends StatelessWidget {
  final ClientDetail client;

  const _HeaderBanner({required this.client});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String status;
    if (client.isBlocked) {
      bg = Colors.red.shade50;
      status = 'Blocked';
    } else if (client.setupApprovalStatus == 'approved') {
      bg = Colors.green.shade50;
      status = 'Approved';
    } else if (client.setupApprovalStatus == 'rejected') {
      bg = Colors.red.shade50;
      status = 'Setup rejected';
    } else {
      bg = Colors.orange.shade50;
      status = 'Setup pending';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            client.displayName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(status, style: TextStyle(color: Colors.grey[800])),
          if (client.isBlocked && client.blockedReason != null)
            Text(
              client.blockedReason!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String? value;
  final Color? valueColor;
  final bool bold;

  const _Row(
    this.label,
    this.value, {
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty || value == '—') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value!,
              style: TextStyle(
                color: valueColor,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide(color: color),
      onPressed: onTap,
    );
  }
}

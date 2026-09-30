import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/client_billing.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/app_async_view.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/skeleton_card.dart';
import '../../providers/clients_provider.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  late final ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrolled = _scrollController.hasClients && _scrollController.offset > 40;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(clientDetailProvider(widget.clientId));

    return detailAsync.when(
      data: (state) {
        return AppPageScaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'Client Details',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: Colors.black87,
              onPressed: () => Navigator.of(context).pop(),
            ),
            elevation: _isScrolled ? 0.5 : 0,
            scrolledUnderElevation: 0,
            backgroundColor: _isScrolled
                ? Colors.white.withValues(alpha: 0.96)
                : Colors.transparent,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                onPressed: () async {
                  final updated = await context.push<bool>('/clients/${widget.clientId}/edit');
                  if (updated == true) {
                    ref.read(clientDetailProvider(widget.clientId).notifier).refresh();
                  }
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
            onRefresh: () async {
              ref.invalidate(clientDetailProvider(widget.clientId));
              await ref.read(clientDetailProvider(widget.clientId).future);
            },
            child: _ClientDetailBody(
              state: state,
              clientId: widget.clientId,
              scrollController: _scrollController,
            ),
          ),
        );
      },
      loading: () => AppPageScaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Client Details',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: Colors.black87,
            onPressed: () => Navigator.of(context).pop(),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: const AdminClientDetailSkeleton(),
      ),
      error: (e, st) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppToast.error(context, friendlyError(e));
        });
        return AppPageScaffold(
          title: 'Client Details',
          body: ErrorView(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(clientDetailProvider(widget.clientId)),
          ),
        );
      },
    );
  }
}

class _ClientDetailBody extends ConsumerWidget {
  final ClientDetailState state;
  final String clientId;
  final ScrollController scrollController;

  const _ClientDetailBody({
    required this.state,
    required this.clientId,
    required this.scrollController,
  });

  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = state.client;
    final notifier = ref.read(clientDetailProvider(clientId).notifier);

    return SingleChildScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero Status Banner ─────────────────────────────────────
          _HeaderBanner(client: client),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Profile Information'),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
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
                      _Row('Setup', client.isSetupCompleted ? 'Completed' : 'Pending'),
                      if (client.createdAt != null)
                        _Row('Joined', _dateFmt.format(client.createdAt!.toLocal())),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                const SectionHeader(title: 'Setup Approval'),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Row('Status', _label(client.setupApprovalStatus)),
                      if (client.setupAdminNote != null && client.setupAdminNote!.isNotEmpty)
                        _Row('Admin note', client.setupAdminNote),
                      if (client.setupReviewedAt != null)
                        _Row(
                          'Reviewed',
                          _dateFmt.format(client.setupReviewedAt!.toLocal()),
                        ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (client.setupApprovalStatus != 'approved')
                            OutlinedButton.icon(
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Approve'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                              ),
                              onPressed: () => _setupApproval(context, notifier, 'approved'),
                            ),
                          if (client.setupApprovalStatus != 'rejected')
                            OutlinedButton.icon(
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              onPressed: () => _setupApproval(context, notifier, 'rejected'),
                            ),
                          if (client.setupApprovalStatus != 'pending')
                            OutlinedButton.icon(
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Reset'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange.shade700,
                                side: BorderSide(color: Colors.orange.shade700),
                              ),
                              onPressed: () => _setupApproval(context, notifier, 'pending'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (state.billing != null) ...[
                  const SectionHeader(title: 'Billing (all time)'),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
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
                              ? Colors.orange.shade800
                              : AppColors.primary,
                          bold: true,
                        ),
                        _Row('Unpaid orders', '${state.billing!.unpaidOrders}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (state.billingOrders.isNotEmpty) ...[
                  const SectionHeader(title: 'Recent Orders (Billing)'),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: state.billingOrders.length > 20 ? 20 : state.billingOrders.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final o = state.billingOrders[index];
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '#${o.orderNumber}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        AppChip(label: _label(o.status), color: Colors.grey.shade700),
                                        AppChip(
                                          label: _label(o.paymentStatus),
                                          color: o.isUnpaid ? Colors.orange.shade800 : AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${o.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  if (o.isUnpaid) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                        minimumSize: const Size(0, 32),
                                        foregroundColor: AppColors.primary,
                                      ),
                                      onPressed: () => _markPaid(context, notifier, o),
                                      child: const Text('Mark paid'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),
                if (client.isBlocked)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Unblock client'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      onPressed: () => _toggleBlock(context, notifier, false),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.block, color: Colors.red),
                      label: const Text('Block client',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => _toggleBlock(context, notifier, true),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(_, true),
              child: const Text('Reject', style: TextStyle(color: Colors.white)),
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
        AppToast.success(context, 'Setup marked as ${_label(status)}');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, friendlyError(e));
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
    } else {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Unblock client'),
          content: const Text('Are you sure you want to unblock this client?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(_, true),
              child: const Text('Unblock'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    try {
      await notifier.setBlocked(block, reason: reason);
      if (context.mounted) {
        AppToast.success(context, block ? 'Client blocked' : 'Client unblocked');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, friendlyError(e));
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
        AppToast.success(context, 'Order marked as paid');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, friendlyError(e));
      }
    }
  }
}

class _HeaderBanner extends StatelessWidget {
  final ClientDetail client;

  const _HeaderBanner({required this.client});

  @override
  Widget build(BuildContext context) {
    Color color;
    String status;
    IconData icon;
    
    if (client.isBlocked) {
      color = Colors.red;
      status = 'Blocked';
      icon = Icons.block;
    } else if (client.setupApprovalStatus == 'approved') {
      color = AppColors.primary;
      status = 'Approved';
      icon = Icons.check_circle_rounded;
    } else if (client.setupApprovalStatus == 'rejected') {
      color = Colors.red;
      status = 'Setup Rejected';
      icon = Icons.cancel_rounded;
    } else {
      color = Colors.orange;
      status = 'Setup Pending';
      icon = Icons.hourglass_empty_rounded;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
        bottom: 28,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Large icon bubble
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: color),
          ),
          const SizedBox(height: 14),
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Name
          Text(
            client.displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          if (client.isBlocked && client.blockedReason != null)
            Text(
              client.blockedReason!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value!,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

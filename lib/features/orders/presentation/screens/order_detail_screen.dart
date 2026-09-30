import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/order.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/skeleton_card.dart';
import '../../providers/orders_provider.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late final ScrollController _scrollController;
  bool _isScrolled = false;

  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  static final _dateFormat = DateFormat('dd MMM yyyy, HH:mm');

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
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return orderAsync.when(
      data: (order) {
        final statusColor = OrderStatusChip.colorForStatus(order.status);
        final statusText = OrderStatusChip.labelForStatus(order.status);
        final statusIcon = OrderStatusChip.iconForStatus(order.status);

        return AppPageScaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'Order Details',
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
          ),
          body: RefreshIndicator(
            edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
            onRefresh: () async {
              ref.invalidate(orderDetailProvider(widget.orderId));
              await ref.read(orderDetailProvider(widget.orderId).future);
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Hero Status Banner ─────────────────────────────────────
                  Container(
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
                          statusColor.withValues(alpha: 0.18),
                          statusColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Large status icon bubble
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(statusIcon, size: 44, color: statusColor),
                        ),
                        const SizedBox(height: 14),
                        // Status pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Order number
                        Text(
                          'Order #${order.orderNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Date
                        if (order.createdAt != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 13, color: Colors.grey.shade600),
                              const SizedBox(width: 5),
                              Text(
                                _dateFormat.format(order.createdAt!),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        // Payment chip + deliver-by
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            PaymentChip(paymentStatus: order.paymentStatus),
                            if (order.deliverBy != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.schedule,
                                        size: 13, color: Colors.orange.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      'By ${_dateFormat.format(order.deliverBy!.toLocal())}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Scrollable Content ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Banners
                        if (order.isExtensionRequested) ...[
                          _ExtensionBanner(order: order, orderId: widget.orderId),
                          const SizedBox(height: 4),
                        ],
                        if (order.isRejected && order.rejectionReason != null) ...[
                          _RejectionBanner(reason: order.rejectionReason!),
                          const SizedBox(height: 4),
                        ],

                        // Buyer info
                        if (order.user != null) ...[
                          const SectionHeader(title: 'Buyer Details'),
                          const SizedBox(height: 8),
                          AppCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (order.user!.businessName != null)
                                  _Row('Business', order.user!.businessName!),
                                if (order.user!.name != null) _Row('Name', order.user!.name!),
                                if (order.user!.phone != null) _Row('Phone', order.user!.phone!),
                                if (order.user!.email != null) _Row('Email', order.user!.email!),
                                if (order.user!.address != null)
                                  _Row('Address', '${order.user!.address}, ${order.user!.pincode ?? ''}'),
                                if (order.user!.gstNumber != null)
                                  _Row('GST', order.user!.gstNumber!),
                                if (order.user!.fssaiNumber != null)
                                  _Row('FSSAI', order.user!.fssaiNumber!),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Delivery address
                        if (order.deliveryAddress != null) ...[
                          const SectionHeader(title: 'Delivery Address'),
                          const SizedBox(height: 8),
                          AppCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Row('Address', '${order.deliveryAddress}, ${order.deliveryPincode ?? ''}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        const SectionHeader(title: 'Items in Order'),
                        const SizedBox(height: 8),

                        // Items container
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: order.items.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (context, index) {
                              final item = order.items[index];
                              final qtyLabel =
                                  item.quantity == item.quantity.roundToDouble()
                                      ? '${item.quantity.toInt()}x'
                                      : '${item.quantity}x';
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Qty bubble
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        qtyLabel,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.unit} • ${_currency.format(item.priceApplied)}/unit',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _currency.format(item.lineTotal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Total row
                        AppCard(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                          borderColor: AppColors.primary.withValues(alpha: 0.12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _currency.format(order.totalAmount),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Action buttons
                        _ActionButtons(order: order, orderId: widget.orderId),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => AppPageScaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Order Details',
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
        body: const AdminOrderDetailSkeleton(),
      ),
      error: (e, st) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppToast.error(context, friendlyError(e));
        });
        return AppPageScaffold(
          title: 'Order Details',
          body: ErrorView(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
          ),
        );
      },
    );
  }
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
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Text(
                value,
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

// ─── Action buttons (context-sensitive) ──────────────────────────────────────

class _ActionButtons extends ConsumerWidget {
  final Order order;
  final String orderId;
  const _ActionButtons({required this.order, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(orderDetailProvider(orderId).notifier);
    
    if (order.isPending) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Accept Order'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () => _accept(context, notifier),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule),
            label: const Text('Request Delivery Extension'),
            onPressed: () => _requestExtension(context, notifier),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Reject Order'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            onPressed: () => _reject(context, notifier),
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
                backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
            onPressed: () => _accept(context, notifier),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Reject Order'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            onPressed: () => _reject(context, notifier),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _accept(BuildContext context, OrderDetailNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Accept Order'),
        content: const Text('Confirm this order and notify the buyer?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        AppToast.success(context, 'Order accepted successfully');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Failed to accept order: $e');
      }
    }
  }

  Future<void> _reject(BuildContext context, OrderDetailNotifier notifier) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Order'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                  hintText: 'e.g. Out of stock',
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
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await notifier.reject(reasonCtrl.text.trim());
      if (context.mounted) {
        AppToast.info(context, 'Order rejected');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Failed to reject order: $e');
      }
    }
    reasonCtrl.dispose();
  }

  Future<void> _requestExtension(BuildContext context, OrderDetailNotifier notifier) async {
    DateTime? picked;
    final noteCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Request Delivery Extension'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Select a new proposed delivery date & time:'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(picked != null
                    ? DateFormat('dd MMM, hh:mm a').format(picked!)
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
              const SizedBox(height: 16),
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
        AppToast.success(context, 'Extension request sent to buyer');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Error: $e');
      }
    }
    noteCtrl.dispose();
  }
}

// ─── Extension banner ─────────────────────────────────────────────────────────

class _ExtensionBanner extends ConsumerWidget {
  final Order order;
  final String orderId;
  const _ExtensionBanner({required this.order, required this.orderId});

  static final _dateFmt = DateFormat('dd MMM yyyy, HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposed = order.proposedDeliverBy;

    return AppCard(
      backgroundColor: Colors.purple.shade50,
      borderColor: Colors.purple.shade200,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.edit_calendar_rounded, color: Colors.purple.shade700),
              const SizedBox(width: 8),
              Text(
                'Delivery Time Change Requested',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (proposed != null)
            Text(
              'Admin proposes: ${_dateFmt.format(proposed.toLocal())}',
              style: const TextStyle(fontSize: 13),
            ),
          if (order.extensionNote != null && order.extensionNote!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Note: ${order.extensionNote}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Waiting for buyer to approve or reject the proposed extension.',
            style: TextStyle(fontSize: 12, color: Colors.purple.shade700),
          ),
        ],
      ),
    );
  }
}

// ─── Rejection banner ─────────────────────────────────────────────────────────

class _RejectionBanner extends StatelessWidget {
  final String reason;
  const _RejectionBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: Colors.red.shade50,
      borderColor: Colors.red.shade200,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel_rounded, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'Order Not Fulfilled',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red.shade700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reason: $reason',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

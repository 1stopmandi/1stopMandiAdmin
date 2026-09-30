import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/orders_provider.dart';
import '../../../../data/models/order.dart';
import '../../../../core/widgets/admin_menu_button.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_async_view.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/skeleton_card.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  static const _statusFilters = [
    null,
    'pending',
    'extension_requested',
    'confirmed',
    'out_for_delivery',
    'delivered',
    'rejected',
    'cancelled',
  ];

  static const _statusLabels = {
    null: 'All',
    'pending': 'Pending',
    'extension_requested': 'Extension',
    'confirmed': 'Confirmed',
    'out_for_delivery': 'Out for Delivery',
    'delivered': 'Delivered',
    'rejected': 'Rejected',
    'cancelled': 'Cancelled',
  };

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersListProvider);
    final currentFilter = ordersAsync.valueOrNull?.statusFilter;

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Orders'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ordersListProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildFilterBar(currentFilter),
        ),
      ),
      body: AppAsyncView<OrdersListState>(
        asyncValue: ordersAsync,
        skeleton: const AdminSkeletonListView.orders(),
        onRefresh: () => ref.read(ordersListProvider.notifier).refresh(),
        onRetry: () => ref.read(ordersListProvider.notifier).refresh(),
        isEmpty: (state) => state.orders.isEmpty,
        emptyState: const EmptyStateView(
          icon: Icons.receipt_long_outlined,
          title: 'No orders found',
          subtitle: 'Orders from buyers will appear here.',
        ),
        builder: (context, state) {
          final orders = state.orders;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: orders.length + (state.currentPage < state.totalPages ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == orders.length) {
                // We reached the bottom, trigger load more if not already loading
                if (!state.loading) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(ordersListProvider.notifier).nextPage();
                  });
                }
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: AdminOrderCardSkeleton(),
                  ),
                );
              }
              return _OrderCard(order: orders[i]);
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(String? current) {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _statusFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final filter = _statusFilters[i];
          final selected = filter == current;
          return FilterChip(
            label: Text(_statusLabels[filter] ?? ''),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) =>
                ref.read(ordersListProvider.notifier).setFilter(filter),
            selectedColor: AppColors.primary.withOpacity(0.15),
            labelStyle: TextStyle(
              color: selected ? AppColors.primary : Colors.black87,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: selected ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/orders/${order.id}'),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent strip
            Container(
              width: 5,
              color: OrderStatusChip.colorForStatus(order.status),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: order number + status chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '#${order.orderNumber}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        OrderStatusChip(status: order.status),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    // Buyer line
                    if (order.user != null)
                      Text(
                        order.user!.businessName ??
                            order.user!.name ??
                            'Unknown buyer',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade100,
                    ),
                    const SizedBox(height: 12),

                    // Bottom row: amount + deliver by
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _currency.format(order.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AppColors.primary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        if (order.deliverBy != null) ...[
                          Icon(
                            Icons.schedule,
                            size: 13,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _dateFmt.format(order.deliverBy!.toLocal()),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (order.createdAt != null)
                      Text(
                        'Placed: ${_dateFmt.format(order.createdAt!.toLocal())}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

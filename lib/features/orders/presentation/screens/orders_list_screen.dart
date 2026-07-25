import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/orders_provider.dart';
import '../../../../data/models/order.dart';
import '../../../../core/widgets/admin_menu_button.dart';
import '../../../../features/auth/providers/auth_provider.dart';

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

  static Color _statusColor(String status) => switch (status) {
        'pending' => Colors.orange,
        'extension_requested' => Colors.purple,
        'confirmed' => Colors.blue,
        'out_for_delivery' => Colors.indigo,
        'delivered' => Colors.green,
        'rejected' => Colors.red,
        'cancelled' => Colors.grey,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersListProvider);
    final user = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Orders'),
        backgroundColor: Colors.green[800],
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
          child: _buildFilterBar(ordersAsync.valueOrNull?.statusFilter),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(e.toString()),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(ordersListProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (state) => state.orders.isEmpty
            ? const Center(child: Text('No orders found'))
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(ordersListProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.orders.length +
                      (state.currentPage < state.totalPages ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == state.orders.length) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: ElevatedButton(
                            onPressed: () =>
                                ref.read(ordersListProvider.notifier).nextPage(),
                            child: const Text('Load more'),
                          ),
                        ),
                      );
                    }
                    return _OrderCard(order: state.orders[i]);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildFilterBar(String? current) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _statusFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final filter = _statusFilters[i];
          final selected = filter == current;
          return FilterChip(
            label: Text(_statusLabels[filter] ?? ''),
            selected: selected,
            onSelected: (_) =>
                ref.read(ordersListProvider.notifier).setFilter(filter),
            selectedColor: Colors.green[200],
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  Widget build(BuildContext context) {
    final status = order.status;
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${order.orderNumber}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      _label(status),
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (order.user != null)
                Text(
                  order.user!.businessName ??
                      order.user!.name ??
                      'Unknown buyer',
                  style: const TextStyle(color: Colors.black87),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.currency_rupee, size: 14, color: Colors.grey),
                  Text(
                    order.totalAmount.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  if (order.deliverBy != null) ...[
                    const Icon(Icons.schedule, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      'By ${_dateFmt.format(order.deliverBy!.toLocal())}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.orange),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              if (order.createdAt != null)
                Text(
                  _dateFmt.format(order.createdAt!.toLocal()),
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _label(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  static Color _statusColor(String status) => switch (status) {
        'pending' => Colors.orange,
        'extension_requested' => Colors.purple,
        'confirmed' => Colors.blue,
        'out_for_delivery' => Colors.indigo,
        'delivered' => Colors.green,
        'rejected' => Colors.red,
        'cancelled' => Colors.grey,
        _ => Colors.grey,
      };
}

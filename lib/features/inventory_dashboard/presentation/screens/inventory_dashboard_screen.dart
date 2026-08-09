import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/inventory_dashboard_provider.dart';
import '../../../../core/widgets/admin_menu_button.dart';

class InventoryDashboardScreen extends ConsumerWidget {
  const InventoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(inventoryDashboardProvider);
    final period = ref.watch(inventoryDashboardPeriodProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Inventory Dashboard'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(inventoryDashboardProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          _PeriodSelector(current: period),
          Expanded(
            child: dashAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (data) => RefreshIndicator(
                onRefresh: () => ref.read(inventoryDashboardProvider.notifier).refresh(),
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _MetricCards(metrics: data.metrics),
                    const SizedBox(height: 16),
                    _TopProducts(products: data.topPurchasedProducts),
                    const SizedBox(height: 16),
                    _WasteProducts(products: data.highestWasteProducts),
                    const SizedBox(height: 16),
                    _RecoverableProducts(products: data.highestRecoverableProducts),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends ConsumerWidget {
  final String current;
  const _PeriodSelector({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.green[50],
      child: Row(
        children: [
          _periodChip(ref, 'Today', 'today'),
          const SizedBox(width: 6),
          _periodChip(ref, 'This Week', 'this_week'),
          const SizedBox(width: 6),
          _periodChip(ref, 'This Month', 'this_month'),
          const SizedBox(width: 6),
          _periodChip(ref, 'Last Month', 'last_month'),
        ],
      ),
    );
  }

  Widget _periodChip(WidgetRef ref, String label, String value) {
    final selected = current == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: selected ? Colors.white : null)),
      selected: selected,
      selectedColor: Colors.green[700],
      onSelected: (v) {
        if (v) ref.read(inventoryDashboardPeriodProvider.notifier).state = value;
      },
      visualDensity: VisualDensity.compact,
    );
  }
}

class _MetricCards extends StatelessWidget {
  final Map<String, dynamic> metrics;
  const _MetricCards({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetricCard('Records', '${_toInt(metrics['total_records'])}', Icons.description, Colors.blue),
        _MetricCard('Purchased', '${_toDouble(metrics['total_purchased_qty']).toStringAsFixed(0)} kg', Icons.shopping_cart, Colors.green[700]!),
        _MetricCard('Good Stock', '${_toDouble(metrics['total_good_stock']).toStringAsFixed(0)} kg\n(${_toDouble(metrics['good_stock_percentage']).toStringAsFixed(1)}%)', Icons.check_circle, Colors.green),
        _MetricCard('Recoverable', '${_toDouble(metrics['total_recoverable']).toStringAsFixed(0)} kg', Icons.recycling, Colors.orange),
        _MetricCard('Waste', '${_toDouble(metrics['total_final_waste']).toStringAsFixed(0)} kg\n(${_toDouble(metrics['waste_percentage']).toStringAsFixed(1)}%)', Icons.delete_outline, Colors.red),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 40) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 6),
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopProducts extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const _TopProducts({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final maxQty = _toDouble(products.first['total_qty']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Purchased Products', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            ...products.asMap().entries.map((entry) {
              final p = entry.value;
              final qty = _toDouble(p['total_qty']);
              final fraction = maxQty > 0 ? qty / maxQty : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${entry.key + 1}. ${p['product_name']}', style: const TextStyle(fontSize: 12)),
                        Text('${qty.toStringAsFixed(0)} ${p['unit']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    LinearProgressIndicator(
                      value: fraction,
                      backgroundColor: Colors.grey[200],
                      color: Colors.green,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _WasteProducts extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const _WasteProducts({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Highest Waste', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            ...products.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p['product_name'] as String, style: const TextStyle(fontSize: 12)),
                  Row(
                    children: [
                      Text('${_toDouble(p['waste_qty']).toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_toDouble(p['waste_pct']).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _RecoverableProducts extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const _RecoverableProducts({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Highest Recoverable', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            ...products.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p['product_name'] as String, style: const TextStyle(fontSize: 12)),
                  Text('${_toDouble(p['recoverable_qty']).toStringAsFixed(0)} kg (${_toDouble(p['pct']).toStringAsFixed(1)}%)',
                      style: const TextStyle(fontSize: 12, color: Colors.orange)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

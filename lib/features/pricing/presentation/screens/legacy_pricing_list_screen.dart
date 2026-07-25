import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/pricing_provider.dart';
import '../../../../core/widgets/admin_menu_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../data/models/pricing.dart';

class LegacyPricingListScreen extends ConsumerWidget {
  const LegacyPricingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(legacyPricingListProvider);
    final unpricedOnly =
        ref.read(legacyPricingListProvider.notifier).unpricedOnly;

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Legacy Pricing'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(legacyPricingListProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All products'),
                  selected: !unpricedOnly,
                  onSelected: (_) => ref
                      .read(legacyPricingListProvider.notifier)
                      .setUnpricedOnly(false),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Unpriced only'),
                  selected: unpricedOnly,
                  onSelected: (_) => ref
                      .read(legacyPricingListProvider.notifier)
                      .setUnpricedOnly(true),
                ),
              ],
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (rows) => rows.isEmpty
                  ? const Center(child: Text('No products'))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(legacyPricingListProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: rows.length,
                        itemBuilder: (_, i) => _PricingRowCard(row: rows[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingRowCard extends StatelessWidget {
  final ProductPricingRow row;
  const _PricingRowCard({required this.row});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/pricing/legacy/${row.id}'),
        title: Text(row.name),
        subtitle: Text(
          '${row.slug}${row.categoryName != null ? ' · ${row.categoryName}' : ''}',
        ),
        trailing: row.hasPricing
            ? Text('₹${row.basePrice!.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green))
            : const Text('No price', style: TextStyle(color: Colors.orange)),
      ),
    );
  }
}

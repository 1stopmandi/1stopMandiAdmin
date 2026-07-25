import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../providers/products_provider.dart';
import '../../../categories/providers/categories_provider.dart';
import '../../../../data/models/product.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Detail'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated =
                  await context.push<bool>('/products/$productId/edit');
              if (updated == true) {
                ref.read(productDetailProvider(productId).notifier).refresh();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(productDetailProvider(productId).notifier).refresh(),
          ),
        ],
      ),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (product) => _ProductDetailBody(
          product: product,
          productId: productId,
        ),
      ),
    );
  }
}

class _ProductDetailBody extends ConsumerWidget {
  final ProductDetail product;
  final String productId;

  const _ProductDetailBody({
    required this.product,
    required this.productId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryNames = ref.watch(categoryNameMapProvider);
    final categoryName = product.categoryId != null
        ? categoryNames[product.categoryId]
        : null;
    final notifier = ref.read(productDetailProvider(productId).notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              product.imageUrl!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
          const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _VegBadge(isVeg: product.isVeg),
          ],
        ),
        const SizedBox(height: 4),
        Text(product.slug, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _StatusChip(
              label: product.isActive ? 'Active' : 'Inactive',
              color: product.isActive ? Colors.green : Colors.grey,
            ),
            if (categoryName != null)
              _StatusChip(label: categoryName, color: Colors.blue),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Details',
          children: [
            _Row('Unit', product.unit),
            _Row('Brand', product.brand),
            _Row('MOQ', product.moq?.toString()),
            _Row('Stock', product.stock?.toString()),
            if (product.description != null && product.description!.isNotEmpty)
              _Row('Description', product.description),
          ],
        ),
        if (product.pricing != null) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Pricing',
            children: [
              _Row(
                'Base price',
                '₹${product.pricing!.basePrice.toStringAsFixed(2)}',
                bold: true,
              ),
              if (product.pricing!.slabs.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Quantity slabs',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                ...product.pricing!.slabs.map((s) {
                  final max = s.maxQty == null
                      ? '+'
                      : '–${s.maxQty!.toStringAsFixed(0)}';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${s.minQty.toStringAsFixed(0)}$max ${product.unit}: '
                      '₹${s.pricePerUnit.toStringAsFixed(2)}/${product.unit}',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  );
                }),
              ],
            ],
          ),
        ],
        const SizedBox(height: 20),
        if (product.isActive)
          OutlinedButton.icon(
            icon: const Icon(Icons.visibility_off, color: Colors.red),
            label: const Text('Deactivate product',
                style: TextStyle(color: Colors.red)),
            onPressed: () => _deactivate(context, notifier),
          )
        else
          ElevatedButton.icon(
            icon: const Icon(Icons.visibility),
            label: const Text('Reactivate product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () => _reactivate(context, notifier),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _deactivate(BuildContext context, ProductDetailNotifier notifier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate product'),
        content: const Text(
          'This hides the product from the catalog but preserves order history. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await notifier.deactivate();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deactivated')),
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

  Future<void> _reactivate(BuildContext context, ProductDetailNotifier notifier) async {
    try {
      await notifier.reactivate();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product reactivated')),
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
  final bool bold;

  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value!,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _VegBadge extends StatelessWidget {
  final bool isVeg;

  const _VegBadge({required this.isVeg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: isVeg ? Colors.green : Colors.red, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isVeg ? 'VEG' : 'NON-VEG',
        style: TextStyle(
          color: isVeg ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

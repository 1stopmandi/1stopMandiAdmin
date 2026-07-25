import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../providers/categories_provider.dart';
import '../../../../data/models/category.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryDetailProvider(categoryId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Detail'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated =
                  await context.push<bool>('/categories/$categoryId/edit');
              if (updated == true) {
                ref.read(categoryDetailProvider(categoryId).notifier).refresh();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(categoryDetailProvider(categoryId).notifier).refresh(),
          ),
        ],
      ),
      body: categoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (category) => _CategoryDetailBody(
          category: category,
          categoryId: categoryId,
        ),
      ),
    );
  }
}

class _CategoryDetailBody extends ConsumerWidget {
  final Category category;
  final String categoryId;

  const _CategoryDetailBody({
    required this.category,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(categoryDetailProvider(categoryId).notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: category.isActive
                ? Colors.green.shade50
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(category.slug, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _Chip(
                    label: category.isActive ? 'Active' : 'Inactive',
                    color: category.isActive ? Colors.green : Colors.grey,
                  ),
                  _Chip(
                    label: 'Sort ${category.sortOrder}',
                    color: Colors.blue,
                  ),
                  _Chip(
                    label:
                        '${category.activeProductCount} active product${category.activeProductCount == 1 ? '' : 's'}',
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Divider(),
                if (category.cityId != null)
                  _Row('City ID', category.cityId!),
                if (category.createdAt != null)
                  _Row(
                    'Created',
                    category.createdAt!.toLocal().toString().substring(0, 16),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (category.isActive)
          OutlinedButton.icon(
            icon: const Icon(Icons.visibility_off, color: Colors.red),
            label: const Text('Deactivate category',
                style: TextStyle(color: Colors.red)),
            onPressed: category.activeProductCount > 0
                ? null
                : () => _deactivate(context, notifier, category),
          )
        else
          ElevatedButton.icon(
            icon: const Icon(Icons.visibility),
            label: const Text('Reactivate category'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () => _reactivate(context, notifier),
          ),
        if (category.isActive && category.activeProductCount > 0) ...[
          const SizedBox(height: 12),
          Text(
            'Cannot deactivate while ${category.activeProductCount} active '
            'product(s) use this category. Reassign or deactivate them first.',
            style: TextStyle(color: Colors.orange[800], fontSize: 13),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _deactivate(
    BuildContext context,
    CategoryDetailNotifier notifier,
    Category category,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate category'),
        content: Text(
          'Hide "${category.name}" from the catalog? '
          'This is blocked if active products still reference it.',
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
          const SnackBar(content: Text('Category deactivated')),
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

  Future<void> _reactivate(
    BuildContext context,
    CategoryDetailNotifier notifier,
  ) async {
    try {
      await notifier.reactivate();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category reactivated')),
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

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

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

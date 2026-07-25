import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/products_provider.dart';
import '../../../categories/providers/categories_provider.dart';
import '../../../../core/widgets/admin_menu_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/product.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);
    final categoriesAsync = ref.watch(sharedCategoriesProvider);
    final categoryNames = ref.watch(categoryNameMapProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Products'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(productsListProvider.notifier).refresh(),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/products/new'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search name or slug…',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref.read(productsListProvider.notifier).search('');
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (v) =>
                        ref.read(productsListProvider.notifier).search(v),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () =>
                      ref.read(productsListProvider.notifier).search(_searchCtrl.text),
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          _FilterBar(
            categoryFilter: productsAsync.valueOrNull?.categoryFilter,
            activeFilter: productsAsync.valueOrNull?.activeFilter,
            categories: categoriesAsync.valueOrNull ?? [],
            onCategoryChanged: (v) =>
                ref.read(productsListProvider.notifier).setCategoryFilter(v),
            onActiveChanged: (v) =>
                ref.read(productsListProvider.notifier).setActiveFilter(v),
          ),
          Expanded(
            child: productsAsync.when(
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
                      onPressed: () =>
                          ref.read(productsListProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (state) => state.products.isEmpty
                  ? const Center(child: Text('No products found'))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(productsListProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.products.length +
                            (state.currentPage < state.totalPages ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == state.products.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: ElevatedButton(
                                  onPressed: () => ref
                                      .read(productsListProvider.notifier)
                                      .nextPage(),
                                  child: const Text('Load more'),
                                ),
                              ),
                            );
                          }
                          final product = state.products[i];
                          return _ProductCard(
                            product: product,
                            categoryName: product.categoryId != null
                                ? categoryNames[product.categoryId]
                                : null,
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? categoryFilter;
  final bool? activeFilter;
  final List<Category> categories;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<bool?> onActiveChanged;

  const _FilterBar({
    required this.categoryFilter,
    required this.activeFilter,
    required this.categories,
    required this.onCategoryChanged,
    required this.onActiveChanged,
  });

  String get _categoryLabel {
    if (categoryFilter == null) return 'All categories';
    for (final c in categories) {
      if (c.id == categoryFilter) return c.name;
    }
    return 'Category';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          FilterChip(
            label: const Text('All'),
            selected: activeFilter == null,
            onSelected: (_) => onActiveChanged(null),
            selectedColor: Colors.green[200],
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Active'),
            selected: activeFilter == true,
            onSelected: (_) => onActiveChanged(true),
            selectedColor: Colors.green[200],
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Inactive'),
            selected: activeFilter == false,
            onSelected: (_) => onActiveChanged(false),
            selectedColor: Colors.grey[300],
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.category, size: 18),
              label: Text(_categoryLabel),
              onPressed: () async {
                final picked = await showModalBottomSheet<String?>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('All categories'),
                          onTap: () => Navigator.pop(ctx, null),
                        ),
                        ...categories.map(
                          (c) => ListTile(
                            title: Text(c.name),
                            trailing: categoryFilter == c.id
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () => Navigator.pop(ctx, c.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                if (picked != categoryFilter) onCategoryChanged(picked);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductSummary product;
  final String? categoryName;

  const _ProductCard({required this.product, this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/products/${product.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductThumb(imageUrl: product.imageUrl, isVeg: product.isVeg),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: product.isActive
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        if (!product.isActive)
                          const _Badge('Inactive', Colors.grey),
                      ],
                    ),
                    Text(
                      product.slug,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (product.basePrice != null)
                          _Badge(
                            '₹${product.basePrice!.toStringAsFixed(2)}/${product.unit}',
                            Colors.green,
                          ),
                        if (categoryName != null)
                          _Badge(categoryName!, Colors.blue),
                        if (product.stock != null)
                          _Badge(
                            'Stock ${product.stock!.toStringAsFixed(0)}',
                            Colors.orange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final String? imageUrl;
  final bool isVeg;

  const _ProductThumb({this.imageUrl, required this.isVeg});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isVeg ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
        width: 56,
        height: 56,
        color: Colors.grey[200],
        child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

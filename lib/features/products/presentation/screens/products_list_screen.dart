import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/products_provider.dart';
import '../../../categories/providers/categories_provider.dart';
import '../../../../core/widgets/admin_menu_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_async_view.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/skeleton_card.dart';

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
    final currentState = productsAsync.valueOrNull;
    final categoriesAsync = ref.watch(sharedCategoriesProvider);
    final categoryNames = ref.watch(categoryNameMapProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Products'),
        backgroundColor: AppColors.primary,
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search name or slug…',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
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
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: () =>
                      ref.read(productsListProvider.notifier).search(_searchCtrl.text),
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          _FilterBar(
            categoryFilter: currentState?.categoryFilter,
            activeFilter: currentState?.activeFilter,
            categories: categoriesAsync.valueOrNull ?? [],
            onCategoryChanged: (v) =>
                ref.read(productsListProvider.notifier).setCategoryFilter(v),
            onActiveChanged: (v) =>
                ref.read(productsListProvider.notifier).setActiveFilter(v),
          ),
          Expanded(
            child: AppAsyncView<ProductsListState>(
              asyncValue: productsAsync,
              skeleton: const AdminSkeletonListView.products(),
              onRefresh: () => ref.read(productsListProvider.notifier).refresh(),
              onRetry: () => ref.read(productsListProvider.notifier).refresh(),
              isEmpty: (state) => state.products.isEmpty,
              emptyState: const EmptyStateView(
                icon: Icons.inventory_2_outlined,
                title: 'No products found',
                subtitle: 'Try adjusting your filters or search query.',
              ),
              builder: (context, state) {
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  itemCount: state.products.length +
                      (state.currentPage < state.totalPages ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == state.products.length) {
                      if (!state.loading) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref.read(productsListProvider.notifier).nextPage();
                        });
                      }
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: AdminProductCardSkeleton(),
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
                );
              },
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
    if (categoryFilter == null) return 'All Categories';
    for (final c in categories) {
      if (c.id == categoryFilter) return c.name;
    }
    return 'Category';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          FilterChip(
            label: const Text('All'),
            selected: activeFilter == null,
            showCheckmark: false,
            onSelected: (_) => onActiveChanged(null),
            selectedColor: AppColors.primary.withOpacity(0.15),
            labelStyle: TextStyle(
              color: activeFilter == null ? AppColors.primary : Colors.black87,
              fontWeight: activeFilter == null ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: activeFilter == null ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Active'),
            selected: activeFilter == true,
            showCheckmark: false,
            onSelected: (_) => onActiveChanged(true),
            selectedColor: AppColors.primary.withOpacity(0.15),
            labelStyle: TextStyle(
              color: activeFilter == true ? AppColors.primary : Colors.black87,
              fontWeight: activeFilter == true ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: activeFilter == true ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Inactive'),
            selected: activeFilter == false,
            showCheckmark: false,
            onSelected: (_) => onActiveChanged(false),
            selectedColor: Colors.grey.shade200,
            labelStyle: TextStyle(
              color: activeFilter == false ? Colors.black87 : Colors.black87,
              fontWeight: activeFilter == false ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: activeFilter == false ? Colors.grey.shade500 : Colors.grey.shade300,
              ),
            ),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(width: 8),
            ActionChip(
              avatar: Icon(Icons.category_outlined, size: 16, color: categoryFilter != null ? AppColors.primary : Colors.black87),
              label: Text(_categoryLabel),
              labelStyle: TextStyle(
                color: categoryFilter != null ? AppColors.primary : Colors.black87,
                fontWeight: categoryFilter != null ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: categoryFilter != null ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
              side: BorderSide(
                color: categoryFilter != null ? AppColors.primary : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () async {
                final picked = await showModalBottomSheet<String?>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('All categories', style: TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () => Navigator.pop(ctx, null),
                        ),
                        const Divider(height: 1),
                        ...categories.map(
                          (c) => ListTile(
                            title: Text(c.name),
                            trailing: categoryFilter == c.id
                                ? const Icon(Icons.check, color: AppColors.primary)
                                : null,
                            onTap: () => Navigator.pop(ctx, c.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                if (picked != categoryFilter && picked != 'cancel') onCategoryChanged(picked);
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
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.push('/products/${product.id}'),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductThumb(imageUrl: product.imageUrl, isVeg: product.isVeg),
          const SizedBox(width: 14),
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
                          fontSize: 16,
                          color: product.isActive ? Colors.black87 : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    if (!product.isActive)
                      const AppChip(label: 'Inactive', color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  product.slug,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (product.basePrice != null)
                      AppChip(
                        label: '₹${product.basePrice!.toStringAsFixed(2)}/${product.unit}',
                        color: AppColors.primary,
                      ),
                    if (categoryName != null)
                      AppChip(label: categoryName!, color: Colors.blue.shade700),
                    if (product.stock != null)
                      AppChip(
                        label: 'Stock: ${product.stock!.toStringAsFixed(0)}',
                        color: product.stock! <= 0 ? Colors.red : Colors.orange.shade800,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isVeg ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 28);
}

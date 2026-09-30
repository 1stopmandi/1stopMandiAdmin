import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/admin_menu_button.dart';
import '../../../../data/models/category.dart';
import '../../../../shared/widgets/app_async_view.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/skeleton_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/categories_provider.dart';

class CategoriesListScreen extends ConsumerWidget {
  const CategoriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Categories'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(categoriesListProvider.notifier).refresh(),
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
        onPressed: () => context.push('/categories/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Show inactive categories', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                Switch(
                  value: categoriesAsync.valueOrNull?.showInactive ?? true,
                  activeColor: AppColors.primary,
                  onChanged: categoriesAsync.isLoading
                      ? null
                      : (v) => ref.read(categoriesListProvider.notifier).setShowInactive(v),
                ),
              ],
            ),
          ),
          Expanded(
            child: AppAsyncView<CategoriesListState>(
              asyncValue: categoriesAsync,
              skeleton: const AdminSkeletonListView.categories(),
              onRefresh: () => ref.read(categoriesListProvider.notifier).refresh(),
              onRetry: () => ref.read(categoriesListProvider.notifier).refresh(),
              isEmpty: (state) => state.visible.isEmpty,
              emptyState: const EmptyStateView(
                icon: Icons.category_outlined,
                title: 'No categories found',
                subtitle: 'Create a new category to organize your products.',
              ),
              builder: (context, state) {
                final items = state.visible;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => _CategoryCard(category: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.push('/categories/${category.id}'),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: category.isActive ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: category.isActive ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade300),
            ),
            alignment: Alignment.center,
            child: Text(
              '${category.sortOrder}',
              style: TextStyle(
                color: category.isActive ? AppColors.primaryDark : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: category.isActive ? Colors.black87 : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    if (!category.isActive)
                      const AppChip(label: 'Inactive', color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  category.slug,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                AppChip(
                  label: '${category.activeProductCount} active product${category.activeProductCount == 1 ? '' : 's'}',
                  color: Colors.blue.shade700,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

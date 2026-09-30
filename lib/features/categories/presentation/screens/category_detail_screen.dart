import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/category.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/skeleton_card.dart';
import '../../providers/categories_provider.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryDetailProvider(categoryId));

    return categoryAsync.when(
      data: (category) => AppPageScaffold(
        appBar: AppBar(
          title: const Text('Category Details'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final updated = await context.push<bool>('/categories/$categoryId/edit');
                if (updated == true) {
                  ref.read(categoryDetailProvider(categoryId).notifier).refresh();
                }
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoryDetailProvider(categoryId));
            await ref.read(categoryDetailProvider(categoryId).future);
          },
          child: _CategoryDetailBody(
            category: category,
            categoryId: categoryId,
          ),
        ),
      ),
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Category Details'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const AdminCategoryDetailSkeleton(),
      ),
      error: (e, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppToast.error(context, friendlyError(e));
        });
        return Scaffold(
          appBar: AppBar(
            title: const Text('Category Details'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: ErrorView(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(categoryDetailProvider(categoryId)),
          ),
        );
      },
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

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: category.isActive
                    ? [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)]
                    : [Colors.grey.shade200, Colors.grey.shade100],
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: category.isActive ? AppColors.primary.withOpacity(0.5) : Colors.grey.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${category.sortOrder}',
                        style: TextStyle(
                          color: category.isActive ? AppColors.primaryDark : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(category.slug, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppChip(
                      label: category.isActive ? 'Active' : 'Inactive',
                      color: category.isActive ? Colors.green : Colors.grey,
                      variant: AppChipVariant.filled,
                    ),
                    AppChip(
                      label: '${category.activeProductCount} active product${category.activeProductCount == 1 ? '' : 's'}',
                      color: Colors.blue.shade700,
                      variant: AppChipVariant.filled,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Details'),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (category.cityId != null)
                        _Row('City ID', category.cityId!),
                      if (category.createdAt != null)
                        _Row(
                          'Created On',
                          DateFormat('MMM d, yyyy, h:mm a').format(category.createdAt!.toLocal()),
                        ),
                      _Row('Sort Order', category.sortOrder.toString()),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                if (category.isActive) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.visibility_off, color: Colors.red),
                      label: const Text('Deactivate category', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: category.activeProductCount > 0
                          ? () {
                              AppToast.error(
                                context, 
                                'Cannot deactivate while ${category.activeProductCount} active product(s) use this category.',
                              );
                            }
                          : () => _deactivate(context, notifier, category),
                    ),
                  ),
                  if (category.activeProductCount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Reassign or deactivate all products in this category before deactivating it.',
                              style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      icon: const Icon(Icons.visibility),
                      label: 'Reactivate category',
                      onPressed: () => _reactivate(context, notifier),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivate(BuildContext context, CategoryDetailNotifier notifier, Category category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate category'),
        content: Text('Hide "${category.name}" from the catalog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await notifier.deactivate();
      if (context.mounted) {
        AppToast.success(context, 'Category deactivated successfully');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, friendlyError(e));
      }
    }
  }

  Future<void> _reactivate(BuildContext context, CategoryDetailNotifier notifier) async {
    try {
      await notifier.reactivate();
      if (context.mounted) {
        AppToast.success(context, 'Category reactivated successfully');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, friendlyError(e));
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

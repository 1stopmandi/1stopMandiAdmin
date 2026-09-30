import 'package:flutter/material.dart';
import '../../../../shared/widgets/skeleton_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../data/models/category.dart';
import '../../providers/categories_provider.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  final String? categoryId;

  const CategoryFormScreen({super.key, this.categoryId});

  bool get isEdit => categoryId != null;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _sortOrderCtrl = TextEditingController(text: '0');

  bool _slugManual = false;
  bool _loading = false;
  bool _loaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    if (!widget.isEdit && !_slugManual) {
      _slugCtrl.text = slugifyCategory(value);
    }
    setState(() {});
  }

  Future<void> _loadExisting() async {
    if (!widget.isEdit || _loaded) return;
    try {
      final c = await ref.read(categoriesRepositoryProvider).getCategory(widget.categoryId!);
      _nameCtrl.text = c.name;
      _slugCtrl.text = c.slug;
      _sortOrderCtrl.text = c.sortOrder.toString();
      _slugManual = true;
      _loaded = true;
    } catch (e) {
      if (mounted) {
        AppToast.error(context, friendlyError(e));
        context.pop();
      }
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(categoriesRepositoryProvider);
      final sortOrder = int.tryParse(_sortOrderCtrl.text.trim()) ?? 0;

      if (widget.isEdit) {
        await repo.updateCategory(widget.categoryId!, {
          'name': _nameCtrl.text.trim(),
          'sort_order': sortOrder,
        });
        ref.read(categoriesListProvider.notifier).refresh();
        if (mounted) {
          AppToast.success(context, 'Category updated successfully');
          context.pop(true);
        }
      } else {
        if (_nameCtrl.text.trim().isEmpty || _slugCtrl.text.trim().isEmpty) {
          throw const ApiException('Name and slug are required');
        }
        final category = await repo.createCategory(
          name: _nameCtrl.text.trim(),
          slug: _slugCtrl.text.trim(),
          sortOrder: sortOrder,
        );
        ref.read(categoriesListProvider.notifier).refresh();
        if (mounted) {
          AppToast.success(context, 'Category created successfully');
          context.pushReplacement('/categories/${category.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit && !_loaded) {
      _loadExisting().then((_) {
        if (mounted) setState(() {});
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Category' : 'Add Category'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: widget.isEdit && !_loaded
          ? const ContentSkeleton(type: ContentSkeletonType.form)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(title: 'Category Details'),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Category Name *',
                            hintText: 'e.g. Vegetables',
                          ),
                          onChanged: _onNameChanged,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _slugCtrl,
                          enabled: !widget.isEdit,
                          decoration: InputDecoration(
                            labelText: 'Slug *',
                            hintText: 'e.g. vegetables',
                            helperText: widget.isEdit
                                ? 'Slug cannot be changed after creation'
                                : 'Lowercase kebab-case used for URLs',
                            filled: true,
                            fillColor: widget.isEdit ? const Color(0xFFF9FAFB) : Colors.white,
                          ),
                          onChanged: (_) {
                            if (!widget.isEdit) _slugManual = true;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _sortOrderCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Sort Order',
                            hintText: 'e.g. 1',
                            helperText: 'Lower numbers appear first in the catalog',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  AppButton.primary(
                    onPressed: _submit,
                    isLoading: _loading,
                    label: widget.isEdit ? 'Save Changes' : 'Create Category',
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

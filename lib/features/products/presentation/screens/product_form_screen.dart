import 'package:flutter/material.dart';
import '../../../../shared/widgets/skeleton_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/product.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../categories/providers/categories_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;

  const ProductFormScreen({super.key, this.productId});

  bool get isEdit => productId != null;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'kg');
  final _brandCtrl = TextEditingController();
  final _moqCtrl = TextEditingController(text: '1');
  final _stockCtrl = TextEditingController(text: '0');
  final _basePriceCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  String? _categoryId;
  bool _isVeg = true;
  bool _slugManual = false;
  bool _loading = false;
  bool _loaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _unitCtrl.dispose();
    _brandCtrl.dispose();
    _moqCtrl.dispose();
    _stockCtrl.dispose();
    _basePriceCtrl.dispose();
    _descriptionCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    if (!widget.isEdit && !_slugManual) {
      _slugCtrl.text = slugify(value);
    }
    setState(() {});
  }

  Future<void> _loadExisting() async {
    if (!widget.isEdit || _loaded) return;
    try {
      final p = await ref.read(productsRepositoryProvider).getProduct(widget.productId!);
      _nameCtrl.text = p.name;
      _slugCtrl.text = p.slug;
      _unitCtrl.text = p.unit;
      _brandCtrl.text = p.brand ?? '';
      _moqCtrl.text = (p.moq ?? 1).toStringAsFixed((p.moq ?? 1) == (p.moq ?? 1).roundToDouble() ? 0 : 1);
      _stockCtrl.text = (p.stock ?? 0).toStringAsFixed(0);
      _basePriceCtrl.text = p.pricing?.basePrice != null
          ? p.pricing!.basePrice.toStringAsFixed(2)
          : (p.basePrice?.toStringAsFixed(2) ?? '');
      _descriptionCtrl.text = p.description ?? '';
      _imageUrlCtrl.text = p.imageUrl ?? '';
      _categoryId = p.categoryId;
      _isVeg = p.isVeg;
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
      final repo = ref.read(productsRepositoryProvider);
      final moq = double.tryParse(_moqCtrl.text.trim());
      final stock = double.tryParse(_stockCtrl.text.trim());
      final basePrice = double.tryParse(_basePriceCtrl.text.trim());

      if (widget.isEdit) {
        await repo.updateProduct(widget.productId!, {
          'name': _nameCtrl.text.trim(),
          'unit': _unitCtrl.text.trim(),
          if (_categoryId != null) 'category_id': _categoryId,
          if (_categoryId == null) 'category_id': null,
          if (moq != null) 'moq': moq,
          if (stock != null) 'stock': stock,
          'is_veg': _isVeg,
          if (_brandCtrl.text.trim().isNotEmpty) 'brand': _brandCtrl.text.trim(),
          if (_descriptionCtrl.text.trim().isNotEmpty) 'description': _descriptionCtrl.text.trim(),
          if (_imageUrlCtrl.text.trim().isNotEmpty) 'image_url': _imageUrlCtrl.text.trim(),
        });
        if (mounted) {
          AppToast.success(context, 'Product updated successfully');
          context.pop(true);
        }
      } else {
        if (_nameCtrl.text.trim().isEmpty || _slugCtrl.text.trim().isEmpty || _unitCtrl.text.trim().isEmpty) {
          throw const ApiException('Name, slug and unit are required');
        }
        final product = await repo.createProduct(
          name: _nameCtrl.text.trim(),
          slug: _slugCtrl.text.trim(),
          unit: _unitCtrl.text.trim(),
          categoryId: _categoryId,
          moq: moq,
          stock: stock,
          isVeg: _isVeg,
          brand: _brandCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          basePrice: basePrice,
        );
        if (mounted) {
          AppToast.success(context, 'Product created successfully');
          context.pushReplacement('/products/${product.id}');
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
    final categoriesAsync = ref.watch(sharedCategoriesProvider);

    if (widget.isEdit && !_loaded) {
      _loadExisting().then((_) {
        if (mounted) setState(() {});
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Product' : 'Add Product'),
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
                  const SectionHeader(title: 'Basic Info'),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Product Name *',
                            hintText: 'e.g. Red Onion',
                          ),
                          onChanged: _onNameChanged,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _slugCtrl,
                          enabled: !widget.isEdit,
                          decoration: InputDecoration(
                            labelText: 'Slug *',
                            hintText: 'e.g. red-onion',
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
                        categoriesAsync.when(
                          loading: () => const AppShimmer(
                            child: ShimmerBox(
                              width: double.infinity,
                              height: 56,
                              radius: 12,
                            ),
                          ),
                          error: (_, __) => const Text('Could not load categories'),
                          data: (categories) => DropdownButtonFormField<String?>(
                            value: _categoryId,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('No category'),
                              ),
                              ...categories.map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => _categoryId = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const SectionHeader(title: 'Product Details'),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _unitCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Unit *',
                            hintText: 'kg, piece, dozen…',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _brandCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Brand',
                            hintText: 'Optional brand name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _moqCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'MOQ',
                                  hintText: 'Minimum quantity',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _stockCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Stock',
                                  hintText: 'Current stock',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          title: const Text('Vegetarian product', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Shows the green veg icon if enabled', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          value: _isVeg,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _isVeg = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const SectionHeader(title: 'Pricing & Media'),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _basePriceCtrl,
                          enabled: !widget.isEdit,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Base price (₹)',
                            helperText: widget.isEdit
                                ? 'Use bulk pricing tools to change price later'
                                : 'Optional — sets initial pricing on create',
                            filled: true,
                            fillColor: widget.isEdit ? const Color(0xFFF9FAFB) : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _imageUrlCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                            hintText: 'https://example.com/image.jpg',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionCtrl,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Provide a short description of the product',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  AppButton.primary(
                    onPressed: _submit,
                    isLoading: _loading,
                    label: widget.isEdit ? 'Save Changes' : 'Create Product',
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

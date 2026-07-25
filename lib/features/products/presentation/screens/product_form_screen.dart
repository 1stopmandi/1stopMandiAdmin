import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/models/product.dart';
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
  String? _error;

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
      final p =
          await ref.read(productsRepositoryProvider).getProduct(widget.productId!);
      _nameCtrl.text = p.name;
      _slugCtrl.text = p.slug;
      _unitCtrl.text = p.unit;
      _brandCtrl.text = p.brand ?? '';
      _moqCtrl.text = (p.moq ?? 1).toStringAsFixed(
          (p.moq ?? 1) == (p.moq ?? 1).roundToDouble() ? 0 : 1);
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
      _error = friendlyError(e);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
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
          if (_descriptionCtrl.text.trim().isNotEmpty)
            'description': _descriptionCtrl.text.trim(),
          if (_imageUrlCtrl.text.trim().isNotEmpty)
            'image_url': _imageUrlCtrl.text.trim(),
        });
        if (mounted) context.pop(true);
      } else {
        if (_nameCtrl.text.trim().isEmpty ||
            _slugCtrl.text.trim().isEmpty ||
            _unitCtrl.text.trim().isEmpty) {
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
        if (mounted) context.go('/products/${product.id}');
      }
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(sharedCategoriesProvider);

    if (widget.isEdit && !_loaded && _error == null) {
      _loadExisting().then((_) {
        if (mounted) setState(() {});
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Product' : 'Add Product'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: widget.isEdit && !_loaded && _error == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Product name *',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _onNameChanged,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _slugCtrl,
                    enabled: !widget.isEdit,
                    decoration: InputDecoration(
                      labelText: 'Slug *',
                      border: const OutlineInputBorder(),
                      helperText: widget.isEdit
                          ? 'Slug cannot be changed after creation'
                          : 'Lowercase kebab-case, e.g. red-onion',
                    ),
                    onChanged: (_) {
                      if (!widget.isEdit) _slugManual = true;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _unitCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      hintText: 'kg, piece, dozen…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  categoriesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Could not load categories'),
                    data: (categories) => DropdownButtonFormField<String?>(
                      value: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: _brandCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Brand',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _moqCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'MOQ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _stockCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Stock',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!widget.isEdit)
                    TextField(
                      controller: _basePriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Base price (₹)',
                        border: OutlineInputBorder(),
                        helperText: 'Optional — sets initial pricing on create',
                      ),
                    )
                  else
                    TextField(
                      controller: _basePriceCtrl,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Base price (₹)',
                        border: OutlineInputBorder(),
                        helperText: 'Use bulk pricing tools to change price',
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _imageUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Image URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vegetarian product'),
                    value: _isVeg,
                    onChanged: (v) => setState(() => _isVeg = v),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.isEdit ? 'Save changes' : 'Create product'),
                  ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/providers/providers.dart';
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
  String? _error;

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
      final c = await ref
          .read(categoriesRepositoryProvider)
          .getCategory(widget.categoryId!);
      _nameCtrl.text = c.name;
      _slugCtrl.text = c.slug;
      _sortOrderCtrl.text = c.sortOrder.toString();
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
      final repo = ref.read(categoriesRepositoryProvider);
      final sortOrder = int.tryParse(_sortOrderCtrl.text.trim()) ?? 0;

      if (widget.isEdit) {
        await repo.updateCategory(widget.categoryId!, {
          'name': _nameCtrl.text.trim(),
          'sort_order': sortOrder,
        });
        ref.read(categoriesListProvider.notifier).refresh();
        if (mounted) context.pop(true);
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
        if (mounted) context.go('/categories/${category.id}');
      }
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit && !_loaded && _error == null) {
      _loadExisting().then((_) {
        if (mounted) setState(() {});
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Category' : 'Add Category'),
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
                      labelText: 'Category name *',
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
                          : 'Lowercase kebab-case, e.g. vegetables',
                    ),
                    onChanged: (_) {
                      if (!widget.isEdit) _slugManual = true;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sortOrderCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sort order',
                      border: OutlineInputBorder(),
                      helperText: 'Lower numbers appear first in the catalog',
                    ),
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
                        : Text(
                            widget.isEdit ? 'Save changes' : 'Create category',
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

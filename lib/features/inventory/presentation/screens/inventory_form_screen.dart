import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_provider.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/product.dart';
import '../../../auth/providers/auth_provider.dart';

/// Sentinel for "Me" (current admin) in Purchased By dropdown.
const _kPurchasedByMe = '__me__';

class InventoryFormScreen extends ConsumerStatefulWidget {
  final String? recordId;
  const InventoryFormScreen({super.key, this.recordId});

  @override
  ConsumerState<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends ConsumerState<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _purchasedById;
  List<_ItemRow> _items = [];
  bool _saving = false;
  bool _loading = true;
  List<ProductSummary> _products = [];
  List<ClientSummary> _clients = [];

  bool get isEdit => widget.recordId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prodResult = await ref.read(productsRepositoryProvider).listProducts(limit: 100, isActive: true);
      _products = prodResult.products;

      final clientsResult = await ref.read(clientsRepositoryProvider).listClients(
        accountStatus: 'active',
        limit: 100,
      );
      _clients = clientsResult.clients;

      final currentUserId = ref.read(authProvider).valueOrNull?.id;

      if (isEdit) {
        final record = await ref.read(inventoryRepositoryProvider).getById(widget.recordId!);
        _titleController.text = record.title;
        _notesController.text = record.notes ?? '';
        _selectedDate = DateTime.parse(record.recordDate);
        if (record.purchasedById != null &&
            currentUserId != null &&
            record.purchasedById == currentUserId) {
          _purchasedById = _kPurchasedByMe;
        } else if (record.purchasedByName == 'Me' &&
            (record.purchasedById == null || record.purchasedById == currentUserId)) {
          _purchasedById = _kPurchasedByMe;
        } else {
          _purchasedById = record.purchasedById;
          // Keep selection valid if client is outside the loaded page.
          if (_purchasedById != null &&
              !_clients.any((c) => c.id == _purchasedById)) {
            _clients = [
              ClientSummary(
                id: _purchasedById!,
                name: record.purchasedByName,
                businessName: record.purchasedByName,
                isSetupCompleted: true,
                setupApprovalStatus: 'approved',
                accountStatus: 'active',
                isBlocked: false,
                outstandingBalance: 0,
              ),
              ..._clients,
            ];
          }
        }
        _items = record.items.map((item) => _ItemRow(
          productId: item.productId,
          productName: item.productName ?? '',
          productUnit: item.productUnit ?? item.unit,
          purchasedController: TextEditingController(text: _fmtQty(item.purchasedQty)),
          goodStockController: TextEditingController(text: _fmtQty(item.goodStock)),
          recoverableController: TextEditingController(text: _fmtQty(item.recoverable)),
          wasteController: TextEditingController(text: _fmtQty(item.finalWaste)),
          // Existing rows already have a breakdown — never auto-overwrite on save.
          breakdownTouched: true,
        )).toList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _fmtQty(double v) => v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  bool get _allValid {
    if (_items.isEmpty) return false;
    return _items.every((item) => item.purchasedQty > 0);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // If user only filled Purchased, default Good Stock = Purchased before validate.
    for (final item in _items) {
      item.autofillGoodFromPurchased();
    }
    setState(() {});

    if (!_allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Each product must have a purchased quantity greater than 0',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      String? purchasedById = _purchasedById;
      if (purchasedById == _kPurchasedByMe) {
        purchasedById = ref.read(authProvider).valueOrNull?.id;
        if (purchasedById == null) {
          throw Exception('Not signed in');
        }
      }

      final data = {
        'title': _titleController.text.trim(),
        'record_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'purchased_by_id': purchasedById,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'items': _items.map((item) => {
          'product_id': item.productId,
          'purchased_qty': item.purchasedQty,
          'good_stock': item.goodStock,
          'recoverable': item.recoverable,
          'final_waste': item.waste,
          'unit': item.productUnit,
        }).toList(),
      };

      final repo = ref.read(inventoryRepositoryProvider);
      if (isEdit) {
        await repo.update(widget.recordId!, data);
        // Detail screen keeps a cached provider; refresh so pop-back shows new data.
        ref.invalidate(inventoryDetailProvider(widget.recordId!));
      } else {
        await repo.create(data);
      }

      ref.read(inventoryListProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Record updated' : 'Record created'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  void _addProduct() async {
    final existingIds = _items.map((i) => i.productId).toSet();
    final available = _products.where((p) => !existingIds.contains(p.id)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All products already added')),
      );
      return;
    }

    final selected = await showModalBottomSheet<List<ProductSummary>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProductSelector(available: available),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        for (final product in selected) {
          _items.add(_ItemRow(
            productId: product.id,
            productName: product.name,
            productUnit: product.unit,
            purchasedController: TextEditingController(),
            goodStockController: TextEditingController(),
            recoverableController: TextEditingController(),
            wasteController: TextEditingController(),
          ));
        }
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'Edit Record' : 'New Record'),
          backgroundColor: Colors.green[800],
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Record' : 'New Record'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeaderFields(),
            const SizedBox(height: 16),
            _buildProductsSection(),
            const SizedBox(height: 16),
            if (_items.isNotEmpty) _buildSummaryBar(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g. Morning Purchase',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Title required (min 2 chars)' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _purchasedById,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Purchased By',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      const DropdownMenuItem(
                        value: _kPurchasedByMe,
                        child: Text('Me'),
                      ),
                      ..._clients.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.displayName, overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (v) => setState(() {
                      _purchasedById = v;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Products (${_items.length})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            FilledButton.icon(
              onPressed: _addProduct,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Product'),
              style: FilledButton.styleFrom(backgroundColor: Colors.green[700]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_items.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No products added yet. Tap "Add Product" to start.')),
            ),
          )
        else
          ..._items.asMap().entries.map((entry) => _ProductRowCard(
            index: entry.key,
            item: entry.value,
            onRemove: () => _removeItem(entry.key),
            onChanged: () => setState(() {}),
          )),
      ],
    );
  }

  Widget _buildSummaryBar() {
    double totalPurchased = 0, totalGood = 0, totalRecover = 0, totalWaste = 0;
    for (final item in _items) {
      totalPurchased += item.purchasedQty;
      totalGood += item.goodStock;
      totalRecover += item.recoverable;
      totalWaste += item.waste;
    }
    final wastePct = totalPurchased > 0 ? (totalWaste / totalPurchased * 100) : 0.0;

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Summary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text('Purchased: ${totalPurchased.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 12)),
                Text('Good: ${totalGood.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 12, color: Colors.green)),
                Text('Recoverable: ${totalRecover.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                Text('Waste: ${totalWaste.toStringAsFixed(1)} kg (${wastePct.toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 12, color: Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }
}

// ─── Item row model ─────────────────────────────────────────────────────────

class _ItemRow {
  final String productId;
  final String productName;
  final String productUnit;
  final TextEditingController purchasedController;
  final TextEditingController goodStockController;
  final TextEditingController recoverableController;
  final TextEditingController wasteController;

  /// Once the user edits Good / Recoverable / Waste, stop auto-syncing Good from Purchased.
  bool breakdownTouched;

  _ItemRow({
    required this.productId,
    required this.productName,
    required this.productUnit,
    required this.purchasedController,
    required this.goodStockController,
    required this.recoverableController,
    required this.wasteController,
    this.breakdownTouched = false,
  });

  double get purchasedQty => double.tryParse(purchasedController.text) ?? 0;
  double get goodStock => double.tryParse(goodStockController.text) ?? 0;
  double get recoverable => double.tryParse(recoverableController.text) ?? 0;
  double get waste => double.tryParse(wasteController.text) ?? 0;

  double get sum => goodStock + recoverable + waste;
  double get difference => purchasedQty - sum;
  bool get isBalanced => purchasedQty > 0 && difference.abs() < 0.01;

  /// Copy Purchased → Good only until the user edits the breakdown fields.
  void autofillGoodFromPurchased() {
    if (purchasedQty <= 0 || breakdownTouched) return;

    final text = purchasedQty == purchasedQty.truncateToDouble()
        ? purchasedQty.toInt().toString()
        : purchasedQty.toStringAsFixed(2);
    if (goodStockController.text != text) {
      goodStockController.text = text;
      goodStockController.selection = TextSelection.collapsed(offset: text.length);
    }
  }

  void dispose() {
    purchasedController.dispose();
    goodStockController.dispose();
    recoverableController.dispose();
    wasteController.dispose();
  }
}

// ─── Product row card widget ────────────────────────────────────────────────

class _ProductRowCard extends StatelessWidget {
  final int index;
  final _ItemRow item;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ProductRowCard({
    required this.index,
    required this.item,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${index + 1}. ${item.productName} (${item.productUnit})',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _QtyField(
                  label: 'Purchased',
                  controller: item.purchasedController,
                  onChanged: () {
                    item.autofillGoodFromPurchased();
                    onChanged();
                  },
                ),
                const SizedBox(width: 8),
                _QtyField(
                  label: 'Good Stock',
                  controller: item.goodStockController,
                  onChanged: () {
                    item.breakdownTouched = true;
                    onChanged();
                  },
                ),
                const SizedBox(width: 8),
                _QtyField(
                  label: 'Recoverable',
                  controller: item.recoverableController,
                  onChanged: () {
                    item.breakdownTouched = true;
                    onChanged();
                  },
                ),
                const SizedBox(width: 8),
                _QtyField(
                  label: 'Waste',
                  controller: item.wasteController,
                  onChanged: () {
                    item.breakdownTouched = true;
                    onChanged();
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            _BalanceIndicator(item: item),
          ],
        ),
      ),
    );
  }
}

class _QtyField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _QtyField({required this.label, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
        style: const TextStyle(fontSize: 13),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

class _BalanceIndicator extends StatelessWidget {
  final _ItemRow item;
  const _BalanceIndicator({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.purchasedQty == 0 && item.sum == 0) {
      return const Text('Enter quantities', style: TextStyle(fontSize: 11, color: Colors.grey));
    }

    if (item.isBalanced) {
      return Row(
        children: [
          const Icon(Icons.check_circle, size: 14, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            '${item.goodStock.toStringAsFixed(1)} + ${item.recoverable.toStringAsFixed(1)} + ${item.waste.toStringAsFixed(1)} = ${item.sum.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 11, color: Colors.green),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.info_outline, size: 14, color: Colors.orange),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${item.sum.toStringAsFixed(1)} ≠ ${item.purchasedQty.toStringAsFixed(1)} (off by ${item.difference.abs().toStringAsFixed(1)})',
            style: const TextStyle(fontSize: 11, color: Colors.orange),
          ),
        ),
      ],
    );
  }
}

// ─── Product selector bottom sheet ──────────────────────────────────────────

class _ProductSelector extends StatefulWidget {
  final List<ProductSummary> available;
  const _ProductSelector({required this.available});

  @override
  State<_ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<_ProductSelector> {
  final _searchController = TextEditingController();
  final Set<String> _selected = {};
  String _filter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductSummary> get _filtered {
    if (_filter.isEmpty) return widget.available;
    return widget.available
        .where((p) => p.name.toLowerCase().contains(_filter.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Expanded(child: Text('Select Products', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                TextButton(
                  onPressed: _selected.isEmpty ? null : () {
                    final selectedProducts = widget.available.where((p) => _selected.contains(p.id)).toList();
                    Navigator.pop(context, selectedProducts);
                  },
                  child: Text('Add (${_selected.length})'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search product...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final product = _filtered[i];
                final isSelected = _selected.contains(product.id);
                return CheckboxListTile(
                  value: isSelected,
                  title: Text('${product.name} (${product.unit})', style: const TextStyle(fontSize: 14)),
                  dense: true,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selected.add(product.id);
                    } else {
                      _selected.remove(product.id);
                    }
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

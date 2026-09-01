import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/providers.dart';
import '../../../../data/models/product.dart';
import '../../providers/inventory_provider.dart';

class InventoryFormScreen extends ConsumerStatefulWidget {
  final String? recordId;

  const InventoryFormScreen({super.key, this.recordId});

  @override
  ConsumerState<InventoryFormScreen> createState() =>
      _InventoryFormScreenState();
}

class _InventoryFormScreenState extends ConsumerState<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<_PurchasingBatchRow> _batches = [];
  List<_DispatchRow> _dispatchItems = [];
  List<_DamageRow> _damageItems = [];
  List<ProductSummary> _products = [];
  bool _loading = true;
  bool _saving = false;
  bool _readOnly = false;

  bool get isEdit => widget.recordId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final result = await ref
          .read(productsRepositoryProvider)
          .listProducts(limit: 100, isActive: true);
      _products = result.products;

      if (isEdit) {
        final record = await ref
            .read(inventoryRepositoryProvider)
            .getById(widget.recordId!);
        _titleController.text = record.title;
        _notesController.text = record.notes ?? '';
        _selectedDate = DateTime.parse(record.recordDate);
        _readOnly = record.isFinalized;
        _batches = record.purchasingBatches
            .map(
              (batch) => _PurchasingBatchRow(
                id: batch.id,
                purchaseSource: batch.purchaseSource,
                transportation: _controller(batch.transportationCharge),
                otherCharges: _controller(batch.otherCharges),
                items: batch.items
                    .map(
                      (item) => _PurchasingRow(
                        id: item.id,
                        productId: item.productId,
                        productName: item.productName ?? '',
                        weight: _controller(item.weight),
                        rate: _controller(item.rate),
                        labour: _controller(item.labourCharge),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList();
        _dispatchItems = record.dispatchItems
            .map(
              (item) => _DispatchRow(
                id: item.id,
                productId: item.productId,
                productName: item.productName ?? '',
                dispatchTo: item.dispatchTo,
                pocket: _controller(item.pocket.toDouble()),
                weight: _controller(item.weight),
                rate: _controller(item.rate),
              ),
            )
            .toList();
        _damageItems = record.damageItems
            .map(
              (item) => _DamageRow(
                id: item.id,
                productId: item.productId,
                productName: item.productName ?? '',
                damageBy: item.damageBy,
                damage: _controller(item.damageQty),
                recover: _controller(item.recoverQty),
              ),
            )
            .toList();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  TextEditingController _controller(double value) => TextEditingController(
        text: value == value.truncateToDouble()
            ? value.toInt().toString()
            : value.toStringAsFixed(2),
      );

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    for (final batch in _batches) {
      batch.dispose();
    }
    for (final item in _dispatchItems) {
      item.dispose();
    }
    for (final item in _damageItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_readOnly || !_formKey.currentState!.validate()) return;
    final duplicateError = _duplicateError();
    if (duplicateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(duplicateError), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'title': _titleController.text.trim(),
        'record_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'notes': _nullable(_notesController.text),
        'purchasing_batches': _batches.map((batch) => batch.toJson()).toList(),
        'dispatch_items': _dispatchItems.map((item) => item.toJson()).toList(),
        'damage_items': _damageItems.map((item) => item.toJson()).toList(),
      };
      final repository = ref.read(inventoryRepositoryProvider);
      if (isEdit) {
        await repository.update(widget.recordId!, data);
        ref.invalidate(inventoryDetailProvider(widget.recordId!));
      } else {
        await repository.create(data);
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
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _duplicateError() {
    for (var index = 0; index < _batches.length; index++) {
      final ids = <String>{};
      for (final item in _batches[index].items) {
        if (!ids.add(item.productId)) {
          return 'Purchasing batch ${index + 1} has a duplicate product';
        }
      }
    }
    final dispatchKeys = <String>{};
    for (final item in _dispatchItems) {
      if (!dispatchKeys.add('${item.productId}:${item.dispatchTo}')) {
        return 'Dispatch product/destination combinations must be unique';
      }
    }
    final damageKeys = <String>{};
    for (final item in _damageItems) {
      if (!damageKeys.add('${item.productId}:${item.damageBy}')) {
        return 'Damage product/source combinations must be unique';
      }
    }
    return null;
  }

  Future<_ProductSelection?> _selectProducts(
    Set<String> excludedIds, {
    bool selectDispatchDestination = false,
    bool selectDamageSource = false,
  }) =>
      showModalBottomSheet<_ProductSelection>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _ProductSelector(
          available: _products
              .where((product) => !excludedIds.contains(product.id))
              .toList(),
          selectDispatchDestination: selectDispatchDestination,
          selectDamageSource: selectDamageSource,
        ),
      );

  Future<void> _addPurchasingItems(int batchIndex) async {
    final batch = _batches[batchIndex];
    final selected = await _selectProducts(
        batch.items.map((item) => item.productId).toSet());
    if (selected == null || selected.products.isEmpty || !mounted) return;
    setState(() {
      batch.items.addAll(
        selected.products.map(
          (product) => _PurchasingRow(
            productId: product.id,
            productName: product.name,
          ),
        ),
      );
    });
  }

  Future<void> _addDispatchItems() async {
    final selected = await _selectProducts({}, selectDispatchDestination: true);
    if (selected == null || selected.products.isEmpty || !mounted) return;
    setState(() {
      _dispatchItems.addAll(
        selected.products.map(
          (product) => _DispatchRow(
            productId: product.id,
            productName: product.name,
            dispatchTo: selected.dispatchTo!,
          ),
        ),
      );
    });
  }

  Future<void> _addDamageItems() async {
    final unavailable = <String>{};
    for (final product in _products) {
      final sources = _damageItems
          .where((item) => item.productId == product.id)
          .map((item) => item.damageBy)
          .toSet();
      if (sources.length == 2) unavailable.add(product.id);
    }
    final selected = await _selectProducts(
      unavailable,
      selectDamageSource: true,
    );
    if (selected == null || selected.products.isEmpty || !mounted) return;
    setState(() {
      _damageItems.addAll(
        selected.products.map(
          (product) => _DamageRow(
            productId: product.id,
            productName: product.name,
            damageBy: selected.damageBy!,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(isEdit ? 'Edit Record' : 'New Record')),
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
            onPressed: _saving || _readOnly ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: AbsorbPointer(
          absorbing: _readOnly,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_readOnly)
                const Card(
                  color: Color(0xfffff3e0),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'This record is finalized. Unfinalize it before editing.',
                    ),
                  ),
                ),
              _buildHeader(),
              const SizedBox(height: 12),
              _buildPurchasingSection(),
              const SizedBox(height: 12),
              _buildDispatchSection(),
              const SizedBox(height: 12),
              _buildDamageSection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildPurchasingSection() => _SectionCard(
        title: 'Purchasing',
        subtitle:
            '${_batches.length} batches • ₹${_purchasingGrandTotal.toStringAsFixed(2)}',
        initiallyExpanded: true,
        child: Column(
          children: [
            ..._batches.asMap().entries.map(
                  (entry) => _buildBatch(entry.key, entry.value),
                ),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => setState(
                  () => _batches.add(_PurchasingBatchRow()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Batch'),
              ),
            ),
          ],
        ),
      );

  Widget _buildBatch(int batchIndex, _PurchasingBatchRow batch) => Card(
        color: Colors.grey[50],
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Batch ${batchIndex + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() {
                      batch.dispose();
                      _batches.removeAt(batchIndex);
                    }),
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
                ],
              ),
              _SourceSelector(
                label: 'Purchase source',
                value: batch.purchaseSource,
                onChanged: (value) =>
                    setState(() => batch.purchaseSource = value),
              ),
              const SizedBox(height: 8),
              ...batch.items.asMap().entries.map(
                    (entry) => _PurchasingItemCard(
                      item: entry.value,
                      onChanged: () => setState(() {}),
                      onRemove: () => setState(() {
                        entry.value.dispose();
                        batch.items.removeAt(entry.key);
                      }),
                    ),
                  ),
              OutlinedButton.icon(
                onPressed: () => _addPurchasingItems(batchIndex),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _NumberField(
                      label: 'Transportation ₹',
                      controller: batch.transportation,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NumberField(
                      label: 'Other charges ₹',
                      controller: batch.otherCharges,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text('Items: ₹${batch.totalAmount.toStringAsFixed(2)}'),
                  Text('Labour: ₹${batch.totalLabour.toStringAsFixed(2)}'),
                  Text(
                    'Grand total: ₹${batch.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildDispatchSection() => _SectionCard(
        title: 'Dispatch',
        subtitle:
            '${_dispatchItems.length} rows • ₹${_dispatchTotal.toStringAsFixed(2)}',
        child: Column(
          children: [
            ..._dispatchItems.asMap().entries.map(
                  (entry) => _DispatchItemCard(
                    item: entry.value,
                    onChanged: () => setState(() {}),
                    onRemove: () => setState(() {
                      entry.value.dispose();
                      _dispatchItems.removeAt(entry.key);
                    }),
                  ),
                ),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _addDispatchItems,
                icon: const Icon(Icons.add),
                label: const Text('Add Dispatch'),
              ),
            ),
            if (_dispatchItems.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total: ₹${_dispatchTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      );

  Widget _buildDamageSection() => _SectionCard(
        title: 'Damage',
        subtitle:
            '${_damageItems.length} rows • ${_damageTotal.toStringAsFixed(2)} kg',
        child: Column(
          children: [
            ..._damageItems.asMap().entries.map(
                  (entry) => _DamageItemCard(
                    item: entry.value,
                    onChanged: () => setState(() {}),
                    onRemove: () => setState(() {
                      entry.value.dispose();
                      _damageItems.removeAt(entry.key);
                    }),
                  ),
                ),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _addDamageItems,
                icon: const Icon(Icons.add),
                label: const Text('Add Damage'),
              ),
            ),
            if (_damageItems.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Damage: ${_damageTotal.toStringAsFixed(2)} kg • '
                  'Recovered: ${_recoverTotal.toStringAsFixed(2)} kg • '
                  'Waste: ${_wasteTotal.toStringAsFixed(2)} kg',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      );

  double get _purchasingGrandTotal =>
      _batches.fold(0, (sum, batch) => sum + batch.grandTotal);
  double get _dispatchTotal =>
      _dispatchItems.fold(0, (sum, item) => sum + item.amount);
  double get _damageTotal =>
      _damageItems.fold(0, (sum, item) => sum + item.damageQty);
  double get _recoverTotal =>
      _damageItems.fold(0, (sum, item) => sum + item.recoverQty);
  double get _wasteTotal =>
      _damageItems.fold(0, (sum, item) => sum + item.wasteQty);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }
}

class _PurchasingBatchRow {
  final String? id;
  String purchaseSource;
  final TextEditingController transportation;
  final TextEditingController otherCharges;
  final List<_PurchasingRow> items;

  _PurchasingBatchRow({
    this.id,
    this.purchaseSource = 'om',
    TextEditingController? transportation,
    TextEditingController? otherCharges,
    List<_PurchasingRow>? items,
  })  : transportation = transportation ?? TextEditingController(text: '0'),
        otherCharges = otherCharges ?? TextEditingController(text: '0'),
        items = items ?? [];

  double get totalAmount => items.fold(0, (sum, item) => sum + item.amount);
  double get totalLabour =>
      items.fold(0, (sum, item) => sum + item.labourCharge);
  double get grandTotal =>
      totalAmount +
      totalLabour +
      _double(transportation.text) +
      _double(otherCharges.text);

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'purchase_source': purchaseSource,
        'transportation_charge': _double(transportation.text),
        'other_charges': _double(otherCharges.text),
        'items': items.map((item) => item.toJson()).toList(),
      };

  void dispose() {
    transportation.dispose();
    otherCharges.dispose();
    for (final item in items) {
      item.dispose();
    }
  }
}

class _PurchasingRow {
  final String? id;
  final String productId;
  final String productName;
  final TextEditingController weight;
  final TextEditingController rate;
  final TextEditingController labour;

  _PurchasingRow({
    this.id,
    required this.productId,
    required this.productName,
    TextEditingController? weight,
    TextEditingController? rate,
    TextEditingController? labour,
  })  : weight = weight ?? TextEditingController(),
        rate = rate ?? TextEditingController(text: '0'),
        labour = labour ?? TextEditingController(text: '0');

  double get amount => _double(weight.text) * _double(rate.text);
  double get labourCharge => _double(labour.text);

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'product_id': productId,
        'weight': _double(weight.text),
        'rate': _double(rate.text),
        'labour_charge': labourCharge,
      };

  void dispose() {
    weight.dispose();
    rate.dispose();
    labour.dispose();
  }
}

class _DispatchRow {
  final String? id;
  final String productId;
  final String productName;
  final String dispatchTo;
  final TextEditingController pocket;
  final TextEditingController weight;
  final TextEditingController rate;

  _DispatchRow({
    this.id,
    required this.productId,
    required this.productName,
    required this.dispatchTo,
    TextEditingController? pocket,
    TextEditingController? weight,
    TextEditingController? rate,
  })  : pocket = pocket ?? TextEditingController(text: '0'),
        weight = weight ?? TextEditingController(),
        rate = rate ?? TextEditingController(text: '0');

  double get amount => _double(weight.text) * _double(rate.text);

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'product_id': productId,
        'dispatch_to': dispatchTo,
        'pocket': int.tryParse(pocket.text) ?? 0,
        'weight': _double(weight.text),
        'rate': _double(rate.text),
      };

  void dispose() {
    pocket.dispose();
    weight.dispose();
    rate.dispose();
  }
}

class _DamageRow {
  final String? id;
  final String productId;
  final String productName;
  String damageBy;
  final TextEditingController damage;
  final TextEditingController recover;

  _DamageRow({
    this.id,
    required this.productId,
    required this.productName,
    this.damageBy = 'om',
    TextEditingController? damage,
    TextEditingController? recover,
  })  : damage = damage ?? TextEditingController(),
        recover = recover ?? TextEditingController(text: '0');

  double get damageQty => _double(damage.text);
  double get recoverQty => _double(recover.text);
  double get wasteQty => damageQty - recoverQty;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'product_id': productId,
        'damage_by': damageBy,
        'damage_qty': damageQty,
        'recover_qty': recoverQty,
      };

  void dispose() {
    damage.dispose();
    recover.dispose();
  }
}

class _PurchasingItemCard extends StatelessWidget {
  final _PurchasingRow item;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _PurchasingItemCard({
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => _RowCard(
        title: item.productName,
        onRemove: onRemove,
        children: [
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  label: 'Weight kg *',
                  controller: item.weight,
                  positive: true,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(
                  label: 'Rate ₹/kg',
                  controller: item.rate,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(
                  label: 'Labour ₹',
                  controller: item.labour,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Amount: ₹${item.amount.toStringAsFixed(2)}'),
        ],
      );
}

class _DispatchItemCard extends StatelessWidget {
  final _DispatchRow item;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _DispatchItemCard({
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => _RowCard(
        title: '${item.productName} • ${_dispatchLabel(item.dispatchTo)}',
        onRemove: onRemove,
        children: [
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  label: 'Pocket',
                  controller: item.pocket,
                  integer: true,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(
                  label: 'Weight kg *',
                  controller: item.weight,
                  positive: true,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(
                  label: 'Rate ₹/kg',
                  controller: item.rate,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Amount: ₹${item.amount.toStringAsFixed(2)}'),
        ],
      );
}

class _DamageItemCard extends StatelessWidget {
  final _DamageRow item;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _DamageItemCard({
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => _RowCard(
        title: item.productName,
        onRemove: onRemove,
        children: [
          _SourceSelector(
            label: 'Damage by',
            value: item.damageBy,
            onChanged: (value) {
              item.damageBy = value;
              onChanged();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  label: 'Damage kg *',
                  controller: item.damage,
                  positive: true,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: item.recover,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Recover kg',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (value) {
                    final recover = _double(value ?? '');
                    if (recover < 0) return 'Must be ≥ 0';
                    if (recover > item.damageQty) return 'Exceeds damage';
                    return null;
                  },
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Waste kg',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Text(item.wasteQty.toStringAsFixed(2)),
                ),
              ),
            ],
          ),
        ],
      );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool initiallyExpanded;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [child],
        ),
      );
}

class _RowCard extends StatelessWidget {
  final String title;
  final VoidCallback onRemove;
  final List<Widget> children;

  const _RowCard({
    required this.title,
    required this.onRemove,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close, color: Colors.red),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              ...children,
            ],
          ),
        ),
      );
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool positive;
  final bool integer;
  final VoidCallback onChanged;

  const _NumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.positive = false,
    this.integer = false,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: !integer),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: (value) {
          final number = integer
              ? int.tryParse(value ?? '')
              : double.tryParse(value ?? '');
          if (number == null) return 'Required';
          if (positive && number <= 0) return 'Must be > 0';
          if (!positive && number < 0) return 'Must be ≥ 0';
          return null;
        },
        onChanged: (_) => onChanged(),
      );
}

class _SourceSelector extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _SourceSelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text('$label: '),
          const SizedBox(width: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'om', label: Text('Om')),
              ButtonSegment(value: 'quicklo', label: Text('Quicklo')),
            ],
            selected: {value},
            showSelectedIcon: false,
            onSelectionChanged: (values) => onChanged(values.first),
          ),
        ],
      );
}

class _ProductSelection {
  final List<ProductSummary> products;
  final String? dispatchTo;
  final String? damageBy;

  const _ProductSelection(
    this.products, {
    this.dispatchTo,
    this.damageBy,
  });
}

class _ProductSelector extends StatefulWidget {
  final List<ProductSummary> available;
  final bool selectDispatchDestination;
  final bool selectDamageSource;

  const _ProductSelector({
    required this.available,
    this.selectDispatchDestination = false,
    this.selectDamageSource = false,
  });

  @override
  State<_ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<_ProductSelector> {
  final _searchController = TextEditingController();
  final _dispatchToController = TextEditingController();
  final Set<String> _selected = {};
  String _filter = '';
  String _damageBy = 'om';

  @override
  void dispose() {
    _searchController.dispose();
    _dispatchToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.available
        .where(
          (product) =>
              product.name.toLowerCase().contains(_filter.toLowerCase()),
        )
        .toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Products',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _selected.isEmpty ||
                          (widget.selectDispatchDestination &&
                              _dispatchToController.text.trim().isEmpty)
                      ? null
                      : () => Navigator.pop(
                            context,
                            _ProductSelection(
                              widget.available
                                  .where(
                                    (product) => _selected.contains(product.id),
                                  )
                                  .toList(),
                              dispatchTo: widget.selectDispatchDestination
                                  ? _dispatchToController.text.trim()
                                  : null,
                              damageBy:
                                  widget.selectDamageSource ? _damageBy : null,
                            ),
                          ),
                  child: Text('Add (${_selected.length})'),
                ),
              ],
            ),
          ),
          if (widget.selectDispatchDestination)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _dispatchToController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Dispatch to',
                  hintText: 'Enter destination',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          if (widget.selectDamageSource)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Damage by',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final value in const ['om', 'quicklo'])
                        ChoiceChip(
                          label: Text(value == 'om' ? 'Om' : 'Quicklo'),
                          selected: _damageBy == value,
                          onSelected: (_) => setState(() => _damageBy = value),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search product',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _filter = value),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text('No products available'))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return CheckboxListTile(
                        value: _selected.contains(product.id),
                        title: Text('${product.name} (${product.unit})'),
                        onChanged: (selected) => setState(() {
                          if (selected == true) {
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

double _double(String value) => double.tryParse(value.trim()) ?? 0;

String _dispatchLabel(String value) => switch (value) {
      'quicklo_part_2' => 'Quicklo Part 2',
      'quicklo_part_3' => 'Quicklo Part 3',
      'quicklo_part_1' => 'Quicklo Part 1',
      _ => value,
    };

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

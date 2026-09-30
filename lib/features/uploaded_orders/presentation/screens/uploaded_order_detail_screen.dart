import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/skeleton_card.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../data/models/product.dart';
import '../../providers/uploaded_orders_provider.dart';

class UploadedOrderDetailScreen extends ConsumerStatefulWidget {
  final String uploadId;

  const UploadedOrderDetailScreen({super.key, required this.uploadId});

  @override
  ConsumerState<UploadedOrderDetailScreen> createState() =>
      _UploadedOrderDetailScreenState();
}

class _LineItem {
  String? productId;
  String productName = '';
  String unit = '';
  final qtyCtrl = TextEditingController(text: '1');
}

class _UploadedOrderDetailScreenState
    extends ConsumerState<UploadedOrderDetailScreen> {
  final _notesCtrl = TextEditingController();
  final _lines = <_LineItem>[];
  bool _loading = false;
  bool _linesInitialized = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final l in _lines) {
      l.qtyCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _pickProduct(_LineItem line) async {
    final product = await showDialog<ProductSummary>(
      context: context,
      builder: (_) => const _ProductPickerDialog(),
    );
    if (product == null) return;
    setState(() {
      line.productId = product.id;
      line.productName = product.name;
      line.unit = product.unit;
    });
  }

  Future<void> _markReady() async {
    final items = _lines
        .where((l) => l.productId != null)
        .map((l) => {
              'product_id': l.productId,
              'quantity': double.tryParse(l.qtyCtrl.text.trim()) ?? 1,
            })
        .toList();
    if (items.isEmpty) {
      AppToast.warning(context, 'Add at least one product line');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(uploadedOrderDetailProvider(widget.uploadId).notifier).markReady(
            items,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );
      if (mounted) {
        AppToast.success(context, 'Marked ready — buyer can add to cart');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject upload'),
        content: TextField(
          controller: _notesCtrl,
          decoration: const InputDecoration(
            hintText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
          minLines: 2,
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(uploadedOrderDetailProvider(widget.uploadId).notifier)
          .markRejected(notes: _notesCtrl.text.trim());
      if (mounted) Navigator.pop(context);
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
    final detailAsync = ref.watch(uploadedOrderDetailProvider(widget.uploadId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Detail'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: detailAsync.when(
        loading: () => const ContentSkeleton(type: ContentSkeletonType.detail),
        error: (e, _) => ErrorView(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(
            uploadedOrderDetailProvider(widget.uploadId),
          ),
        ),
        data: (upload) {
          if (!_linesInitialized && upload.status == 'processing') {
            _linesInitialized = true;
            _lines.add(_LineItem());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  resolveMediaUrl(upload.imageUrl),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.broken_image, size: 48)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Status: ${upload.status}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (upload.notes != null && upload.notes!.isNotEmpty)
                Text('Notes: ${upload.notes}'),
              if (upload.items.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                ...upload.items.map((it) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(it.productName),
                      subtitle: Text(
                          '${it.quantity} ${it.unit}${it.pricePerUnit != null ? ' @ ₹${it.pricePerUnit}' : ''}'),
                    )),
              ],
              if (upload.status == 'processing') ...[
                const SizedBox(height: 16),
                const Text('Build cart items',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._lines.asMap().entries.map((e) {
                  final line = e.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(line.productName.isEmpty
                                ? 'Tap to select product'
                                : line.productName),
                            subtitle: line.unit.isNotEmpty ? Text(line.unit) : null,
                            trailing: const Icon(Icons.search),
                            onTap: () => _pickProduct(line),
                          ),
                          TextField(
                            controller: line.qtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => setState(() => _lines.add(_LineItem())),
                  icon: const Icon(Icons.add),
                  label: const Text('Add line'),
                ),
                TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Admin notes',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _markReady,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Mark ready'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _reject,
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Reject',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProductPickerDialog extends ConsumerStatefulWidget {
  const _ProductPickerDialog();

  @override
  ConsumerState<_ProductPickerDialog> createState() =>
      _ProductPickerDialogState();
}

class _ProductPickerDialogState extends ConsumerState<_ProductPickerDialog> {
  final _searchCtrl = TextEditingController();
  List<ProductSummary> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(String q) async {
    setState(() => _loading = true);
    try {
      final r = await ref.read(productsRepositoryProvider).listProducts(
            search: q.isEmpty ? null : q,
            isActive: true,
            limit: 30,
          );
      setState(() => _products = r.products);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select product'),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: _load,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const ContentSkeleton(type: ContentSkeletonType.list, itemCount: 3)
                  : ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (_, i) {
                        final p = _products[i];
                        return ListTile(
                          title: Text(p.name),
                          subtitle: Text('${p.slug} · ${p.unit}'),
                          onTap: () => Navigator.pop(context, p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

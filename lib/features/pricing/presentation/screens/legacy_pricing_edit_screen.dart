import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/skeleton_card.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../data/models/pricing.dart';
import '../../providers/pricing_provider.dart';

class LegacyPricingEditScreen extends ConsumerStatefulWidget {
  final String productId;

  const LegacyPricingEditScreen({super.key, required this.productId});

  @override
  ConsumerState<LegacyPricingEditScreen> createState() =>
      _LegacyPricingEditScreenState();
}

class _LegacyPricingEditScreenState extends ConsumerState<LegacyPricingEditScreen> {
  final _basePriceCtrl = TextEditingController();
  final _slabMinCtrls = <TextEditingController>[];
  final _slabMaxCtrls = <TextEditingController>[];
  final _slabPriceCtrls = <TextEditingController>[];
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _basePriceCtrl.dispose();
    for (final c in [..._slabMinCtrls, ..._slabMaxCtrls, ..._slabPriceCtrls]) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFromPricing(ProductPricingDetail pricing) {
    if (_initialized) return;
    _basePriceCtrl.text = pricing.basePrice?.toStringAsFixed(2) ?? '';
    for (final s in pricing.slabs) {
      _addSlab(s);
    }
    if (pricing.slabs.isEmpty) _addSlab(null);
    _initialized = true;
  }

  void _addSlab(PricingSlabInput? s) {
    _slabMinCtrls.add(TextEditingController(
        text: s?.minQty.toString() ?? ''));
    _slabMaxCtrls.add(TextEditingController(
        text: s?.maxQty?.toString() ?? ''));
    _slabPriceCtrls.add(TextEditingController(
        text: s?.pricePerUnit.toString() ?? ''));
  }

  List<PricingSlabInput> _readSlabs() {
    final slabs = <PricingSlabInput>[];
    for (var i = 0; i < _slabMinCtrls.length; i++) {
      final min = double.tryParse(_slabMinCtrls[i].text.trim());
      final price = double.tryParse(_slabPriceCtrls[i].text.trim());
      if (min == null || price == null) continue;
      final maxStr = _slabMaxCtrls[i].text.trim();
      slabs.add(PricingSlabInput(
        minQty: min,
        maxQty: maxStr.isEmpty ? null : double.tryParse(maxStr),
        pricePerUnit: price,
      ));
    }
    return slabs;
  }

  Future<void> _save() async {
    final base = double.tryParse(_basePriceCtrl.text.trim());
    if (base == null || base <= 0) {
      AppToast.warning(context, 'Enter a valid base price');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(legacyPricingEditProvider(widget.productId).notifier).save(
            base,
            _readSlabs(),
          );
      if (mounted) {
        AppToast.success(context, 'Pricing saved');
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
    final stateAsync = ref.watch(legacyPricingEditProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Pricing'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: stateAsync.when(
        loading: () => const ContentSkeleton(type: ContentSkeletonType.form),
        error: (e, _) => ErrorView(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(
            legacyPricingEditProvider(widget.productId),
          ),
        ),
        data: (state) {
          _initFromPricing(state.pricing);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _basePriceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Base price (₹) *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Slabs',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _slabMinCtrls.length >= 3
                        ? null
                        : () => setState(() => _addSlab(null)),
                    icon: const Icon(Icons.add),
                    label: const Text('Add slab'),
                  ),
                ],
              ),
              ...List.generate(_slabMinCtrls.length, (i) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _slabMinCtrls[i],
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Min qty',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _slabMaxCtrls[i],
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Max qty',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _slabPriceCtrls[i],
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save pricing'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  try {
                    await ref
                        .read(legacyPricingEditProvider(widget.productId).notifier)
                        .revert();
                    if (context.mounted) {
                      AppToast.success(context, 'Reverted to previous price');
                      setState(() => _initialized = false);
                      ref.invalidate(legacyPricingEditProvider(widget.productId));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppToast.error(context, friendlyError(e));
                    }
                  }
                },
                child: const Text('Revert to previous version'),
              ),
              if (state.audit.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Audit log',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...state.audit.take(10).map((a) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(a.changedByName ?? a.changedByPhone ?? 'System'),
                      subtitle: Text(a.changedAt?.toLocal().toString() ?? ''),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

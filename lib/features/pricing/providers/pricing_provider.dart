import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/pricing.dart';

final legacyPricingListProvider =
    AsyncNotifierProvider<LegacyPricingListNotifier, List<ProductPricingRow>>(
        LegacyPricingListNotifier.new);

class LegacyPricingListNotifier extends AsyncNotifier<List<ProductPricingRow>> {
  bool _unpricedOnly = false;

  bool get unpricedOnly => _unpricedOnly;

  @override
  Future<List<ProductPricingRow>> build() async => _fetch();

  Future<List<ProductPricingRow>> _fetch() async {
    return ref.read(pricingRepositoryProvider).listPricingProducts(
          unpricedOnly: _unpricedOnly,
        );
  }

  Future<void> setUnpricedOnly(bool value) async {
    _unpricedOnly = value;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _fetch());
  }
}

class LegacyPricingEditState {
  final ProductPricingDetail pricing;
  final List<PricingAuditEntry> audit;

  const LegacyPricingEditState({required this.pricing, this.audit = const []});
}

final legacyPricingEditProvider = AsyncNotifierProviderFamily<
    LegacyPricingEditNotifier, LegacyPricingEditState, String>(
  LegacyPricingEditNotifier.new,
);

class LegacyPricingEditNotifier
    extends FamilyAsyncNotifier<LegacyPricingEditState, String> {
  @override
  Future<LegacyPricingEditState> build(String productId) async => _load(productId);

  Future<LegacyPricingEditState> _load(String productId) async {
    final repo = ref.read(pricingRepositoryProvider);
    final pricing = await repo.getProductPricing(productId);
    List<PricingAuditEntry> audit = [];
    try {
      audit = await repo.getAuditLog(productId);
    } catch (_) {}
    return LegacyPricingEditState(pricing: pricing, audit: audit);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(arg));
    ref.read(legacyPricingListProvider.notifier).refresh();
  }

  Future<void> save(double basePrice, List<PricingSlabInput> slabs) async {
    await ref.read(pricingRepositoryProvider).updatePricing(
          productId: arg,
          basePrice: basePrice,
          slabs: slabs,
        );
    await refresh();
  }

  Future<void> deactivate() async {
    await ref.read(pricingRepositoryProvider).deactivatePricing(arg);
    await refresh();
  }

  Future<void> revert() async {
    await ref.read(pricingRepositoryProvider).revertPricing(arg);
    await refresh();
  }
}

final bulkImportPreviewProvider = StateProvider<BulkImportPreview?>((ref) => null);

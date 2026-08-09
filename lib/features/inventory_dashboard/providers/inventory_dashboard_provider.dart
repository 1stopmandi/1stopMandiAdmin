import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/inventory_dashboard_repository.dart';

final inventoryDashboardRepositoryProvider =
    Provider<InventoryDashboardRepository>((ref) => InventoryDashboardRepository());

final inventoryDashboardPeriodProvider = StateProvider<String>((ref) => 'this_month');

final inventoryDashboardProvider =
    AsyncNotifierProvider<InventoryDashboardNotifier, InventoryDashboardData>(
        InventoryDashboardNotifier.new);

class InventoryDashboardNotifier extends AsyncNotifier<InventoryDashboardData> {
  @override
  Future<InventoryDashboardData> build() async {
    final period = ref.watch(inventoryDashboardPeriodProvider);
    return ref.read(inventoryDashboardRepositoryProvider).getDashboard(period: period);
  }

  Future<void> refresh() async {
    final period = ref.read(inventoryDashboardPeriodProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(inventoryDashboardRepositoryProvider).getDashboard(period: period),
    );
  }
}

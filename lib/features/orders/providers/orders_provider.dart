import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/order.dart';

// ─── Orders list ─────────────────────────────────────────────────────────────

class OrdersListState {
  final List<Order> orders;
  final int total;
  final int totalPages;
  final int currentPage;
  final String? statusFilter;
  final bool loading;
  final String? error;

  const OrdersListState({
    this.orders = const [],
    this.total = 0,
    this.totalPages = 1,
    this.currentPage = 1,
    this.statusFilter,
    this.loading = false,
    this.error,
  });

  OrdersListState copyWith({
    List<Order>? orders,
    int? total,
    int? totalPages,
    int? currentPage,
    String? statusFilter,
    bool clearStatusFilter = false,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      OrdersListState(
        orders: orders ?? this.orders,
        total: total ?? this.total,
        totalPages: totalPages ?? this.totalPages,
        currentPage: currentPage ?? this.currentPage,
        statusFilter:
            clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

final ordersListProvider =
    AsyncNotifierProvider<OrdersListNotifier, OrdersListState>(
        OrdersListNotifier.new);

class OrdersListNotifier extends AsyncNotifier<OrdersListState> {
  @override
  Future<OrdersListState> build() async {
    return _fetch(page: 1, status: null);
  }

  Future<OrdersListState> _fetch({int page = 1, String? status}) async {
    final repo = ref.read(ordersRepositoryProvider);
    final result = await repo.listOrders(status: status, page: page);
    return OrdersListState(
      orders: result.orders,
      total: result.total,
      totalPages: result.totalPages,
      currentPage: page,
      statusFilter: status,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = await AsyncValue.guard(
      () => _fetch(page: 1, status: current?.statusFilter),
    );
  }

  Future<void> setFilter(String? status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, status: status));
  }

  Future<void> nextPage() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.currentPage >= current.totalPages) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetch(
          page: current.currentPage + 1, status: current.statusFilter),
    );
  }
}

// ─── Single order detail ─────────────────────────────────────────────────────

final orderDetailProvider =
    AsyncNotifierProviderFamily<OrderDetailNotifier, Order, String>(
        OrderDetailNotifier.new);

class OrderDetailNotifier extends FamilyAsyncNotifier<Order, String> {
  @override
  Future<Order> build(String id) async {
    return ref.read(ordersRepositoryProvider).getOrder(id);
  }

  Future<void> accept() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ordersRepositoryProvider).acceptOrder(arg),
    );
    ref.read(ordersListProvider.notifier).refresh();
  }

  Future<void> reject(String reason) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ordersRepositoryProvider).rejectOrder(arg, reason),
    );
    ref.read(ordersListProvider.notifier).refresh();
  }

  Future<void> requestExtension(DateTime proposed, String? note) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(ordersRepositoryProvider)
          .requestExtension(arg, proposed, note),
    );
    ref.read(ordersListProvider.notifier).refresh();
  }
}

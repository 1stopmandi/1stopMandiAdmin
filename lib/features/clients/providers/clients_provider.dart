import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/client.dart';
import '../../../data/models/client_billing.dart';

// ─── Clients list ────────────────────────────────────────────────────────────

class ClientsListState {
  final List<ClientSummary> clients;
  final int total;
  final int totalPages;
  final int currentPage;
  final String? search;
  final String? approvalFilter;
  final bool outstandingOnly;
  final bool loading;
  final String? error;

  const ClientsListState({
    this.clients = const [],
    this.total = 0,
    this.totalPages = 1,
    this.currentPage = 1,
    this.search,
    this.approvalFilter,
    this.outstandingOnly = false,
    this.loading = false,
    this.error,
  });

  ClientsListState copyWith({
    List<ClientSummary>? clients,
    int? total,
    int? totalPages,
    int? currentPage,
    String? search,
    bool clearSearch = false,
    String? approvalFilter,
    bool clearApprovalFilter = false,
    bool? outstandingOnly,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      ClientsListState(
        clients: clients ?? this.clients,
        total: total ?? this.total,
        totalPages: totalPages ?? this.totalPages,
        currentPage: currentPage ?? this.currentPage,
        search: clearSearch ? null : (search ?? this.search),
        approvalFilter:
            clearApprovalFilter ? null : (approvalFilter ?? this.approvalFilter),
        outstandingOnly: outstandingOnly ?? this.outstandingOnly,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

final clientsListProvider =
    AsyncNotifierProvider<ClientsListNotifier, ClientsListState>(
        ClientsListNotifier.new);

class ClientsListNotifier extends AsyncNotifier<ClientsListState> {
  @override
  Future<ClientsListState> build() async => _fetch(page: 1);

  Future<ClientsListState> _fetch({int page = 1, ClientsListState? prev}) async {
    final repo = ref.read(clientsRepositoryProvider);
    final result = await repo.listClients(
      search: prev?.search,
      setupApprovalStatus: prev?.approvalFilter,
      hasOutstanding: prev?.outstandingOnly == true ? true : null,
      page: page,
    );
    return ClientsListState(
      clients: result.clients,
      total: result.total,
      totalPages: result.totalPages,
      currentPage: page,
      search: prev?.search,
      approvalFilter: prev?.approvalFilter,
      outstandingOnly: prev?.outstandingOnly ?? false,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: current));
  }

  Future<void> search(String query) async {
    final current = state.valueOrNull;
    final next = (current ?? const ClientsListState()).copyWith(
      search: query.trim().isEmpty ? null : query.trim(),
      clearSearch: query.trim().isEmpty,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: next));
  }

  Future<void> setApprovalFilter(String? status) async {
    final current = state.valueOrNull;
    final next = (current ?? const ClientsListState()).copyWith(
      approvalFilter: status,
      clearApprovalFilter: status == null,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: next));
  }

  Future<void> toggleOutstandingOnly(bool value) async {
    final current = state.valueOrNull;
    final next = (current ?? const ClientsListState()).copyWith(
      outstandingOnly: value,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: next));
  }

  Future<void> nextPage() async {
    final current = state.valueOrNull;
    if (current == null || current.currentPage >= current.totalPages) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(clientsRepositoryProvider);
      final result = await repo.listClients(
        search: current.search,
        setupApprovalStatus: current.approvalFilter,
        hasOutstanding: current.outstandingOnly ? true : null,
        page: current.currentPage + 1,
      );
      return ClientsListState(
        clients: [...current.clients, ...result.clients],
        total: result.total,
        totalPages: result.totalPages,
        currentPage: current.currentPage + 1,
        search: current.search,
        approvalFilter: current.approvalFilter,
        outstandingOnly: current.outstandingOnly,
      );
    });
  }
}

// ─── Client detail ───────────────────────────────────────────────────────────

class ClientDetailState {
  final ClientDetail client;
  final ClientBillingSummary? billing;
  final List<ClientBillingOrder> billingOrders;

  const ClientDetailState({
    required this.client,
    this.billing,
    this.billingOrders = const [],
  });

  ClientDetailState copyWith({
    ClientDetail? client,
    ClientBillingSummary? billing,
    List<ClientBillingOrder>? billingOrders,
  }) =>
      ClientDetailState(
        client: client ?? this.client,
        billing: billing ?? this.billing,
        billingOrders: billingOrders ?? this.billingOrders,
      );
}

final clientDetailProvider =
    AsyncNotifierProviderFamily<ClientDetailNotifier, ClientDetailState, String>(
        ClientDetailNotifier.new);

class ClientDetailNotifier extends FamilyAsyncNotifier<ClientDetailState, String> {
  @override
  Future<ClientDetailState> build(String id) async => _load(id);

  Future<ClientDetailState> _load(String id) async {
    final repo = ref.read(clientsRepositoryProvider);
    final client = await repo.getClient(id);
    ClientBillingSummary? billing;
    List<ClientBillingOrder> orders = [];
    try {
      billing = await repo.getBillingSummary(id);
      orders = await repo.listBillingOrders(id, status: 'all');
    } catch (_) {
      // billing is optional on detail
    }
    return ClientDetailState(
      client: client,
      billing: billing,
      billingOrders: orders,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(arg));
    ref.read(clientsListProvider.notifier).refresh();
  }

  Future<void> setSetupApproval(String status, {String? note}) async {
    await ref.read(clientsRepositoryProvider).setSetupApproval(
          arg,
          status: status,
          note: note,
        );
    await refresh();
  }

  Future<void> setBlocked(bool blocked, {String? reason}) async {
    await ref.read(clientsRepositoryProvider).setBlocked(
          arg,
          blocked: blocked,
          reason: reason,
        );
    await refresh();
  }

  Future<void> markOrderPaid(String orderId, {String? reference}) async {
    await ref.read(clientsRepositoryProvider).markOrderPaid(
          arg,
          orderId,
          reference: reference,
        );
    await refresh();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/inventory_record.dart';
import '../data/repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) => InventoryRepository());

// ─── List state ───────────────────────────────────────────────────────────────

class InventoryListState {
  final List<InventoryRecord> records;
  final int total;
  final int totalPages;
  final int currentPage;
  final String? search;
  final String? statusFilter;
  final String? dateFilter;

  const InventoryListState({
    this.records = const [],
    this.total = 0,
    this.totalPages = 1,
    this.currentPage = 1,
    this.search,
    this.statusFilter,
    this.dateFilter,
  });

  InventoryListState copyWith({
    List<InventoryRecord>? records,
    int? total,
    int? totalPages,
    int? currentPage,
    String? search,
    bool clearSearch = false,
    String? statusFilter,
    bool clearStatus = false,
    String? dateFilter,
    bool clearDate = false,
  }) =>
      InventoryListState(
        records: records ?? this.records,
        total: total ?? this.total,
        totalPages: totalPages ?? this.totalPages,
        currentPage: currentPage ?? this.currentPage,
        search: clearSearch ? null : (search ?? this.search),
        statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
        dateFilter: clearDate ? null : (dateFilter ?? this.dateFilter),
      );
}

final inventoryListProvider =
    AsyncNotifierProvider<InventoryListNotifier, InventoryListState>(
        InventoryListNotifier.new);

class InventoryListNotifier extends AsyncNotifier<InventoryListState> {
  @override
  Future<InventoryListState> build() async => _fetch(page: 1);

  Future<InventoryListState> _fetch({int page = 1, InventoryListState? prev}) async {
    final repo = ref.read(inventoryRepositoryProvider);
    final result = await repo.list(
      search: prev?.search,
      status: prev?.statusFilter,
      date: prev?.dateFilter,
      page: page,
    );
    return InventoryListState(
      records: result.records,
      total: result.total,
      totalPages: result.totalPages,
      currentPage: page,
      search: prev?.search,
      statusFilter: prev?.statusFilter,
      dateFilter: prev?.dateFilter,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: current));
  }

  Future<void> search(String query) async {
    final current = state.valueOrNull;
    final next = (current ?? const InventoryListState()).copyWith(
      search: query.trim().isEmpty ? null : query.trim(),
      clearSearch: query.trim().isEmpty,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: next));
  }

  Future<void> setStatusFilter(String? status) async {
    final current = state.valueOrNull;
    final next = (current ?? const InventoryListState()).copyWith(
      statusFilter: status,
      clearStatus: status == null,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: next));
  }

  Future<void> setDateFilter(String? date) async {
    final current = state.valueOrNull;
    final next = (current ?? const InventoryListState()).copyWith(
      dateFilter: date,
      clearDate: date == null,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: next));
  }

  Future<void> nextPage() async {
    final current = state.valueOrNull;
    if (current == null || current.currentPage >= current.totalPages) return;
    state = await AsyncValue.guard(() async {
      final repo = ref.read(inventoryRepositoryProvider);
      final result = await repo.list(
        search: current.search,
        status: current.statusFilter,
        date: current.dateFilter,
        page: current.currentPage + 1,
      );
      return current.copyWith(
        records: [...current.records, ...result.records],
        total: result.total,
        totalPages: result.totalPages,
        currentPage: current.currentPage + 1,
      );
    });
  }
}

// ─── Detail provider ──────────────────────────────────────────────────────────

final inventoryDetailProvider =
    AsyncNotifierProviderFamily<InventoryDetailNotifier, InventoryRecord, String>(
        InventoryDetailNotifier.new);

class InventoryDetailNotifier extends FamilyAsyncNotifier<InventoryRecord, String> {
  @override
  Future<InventoryRecord> build(String id) async {
    return ref.read(inventoryRepositoryProvider).getById(id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(inventoryRepositoryProvider).getById(arg));
  }

  Future<void> finalizeRecord() async {
    await ref.read(inventoryRepositoryProvider).finalize(arg);
    await refresh();
    ref.read(inventoryListProvider.notifier).refresh();
  }

  Future<void> unfinalizeRecord() async {
    await ref.read(inventoryRepositoryProvider).unfinalize(arg);
    await refresh();
    ref.read(inventoryListProvider.notifier).refresh();
  }

  Future<void> deleteRecord() async {
    await ref.read(inventoryRepositoryProvider).delete(arg);
    ref.read(inventoryListProvider.notifier).refresh();
  }
}

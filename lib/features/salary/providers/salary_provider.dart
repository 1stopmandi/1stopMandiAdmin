import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/salary.dart';
import '../data/repositories/salary_repository.dart';

final salaryRepositoryProvider = Provider<SalaryRepository>((ref) => SalaryRepository());

// ─── Salary periods list ────────────────────────────────────────────────────

class SalaryPeriodsListState {
  final List<SalaryPeriod> periods;
  final int total;
  final int totalPages;
  final int currentPage;
  final String? statusFilter;

  const SalaryPeriodsListState({
    this.periods = const [],
    this.total = 0,
    this.totalPages = 1,
    this.currentPage = 1,
    this.statusFilter,
  });

  SalaryPeriodsListState copyWith({
    List<SalaryPeriod>? periods,
    int? total,
    int? totalPages,
    int? currentPage,
    String? statusFilter,
    bool clearStatusFilter = false,
  }) =>
      SalaryPeriodsListState(
        periods: periods ?? this.periods,
        total: total ?? this.total,
        totalPages: totalPages ?? this.totalPages,
        currentPage: currentPage ?? this.currentPage,
        statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      );
}

final salaryPeriodsListProvider =
    AsyncNotifierProvider<SalaryPeriodsListNotifier, SalaryPeriodsListState>(
        SalaryPeriodsListNotifier.new);

class SalaryPeriodsListNotifier extends AsyncNotifier<SalaryPeriodsListState> {
  @override
  Future<SalaryPeriodsListState> build() async => _fetch(page: 1);

  Future<SalaryPeriodsListState> _fetch({int page = 1, String? statusFilter}) async {
    final repo = ref.read(salaryRepositoryProvider);
    final result = await repo.listPeriods(status: statusFilter, page: page);
    return SalaryPeriodsListState(
      periods: result.periods,
      total: result.total,
      totalPages: result.totalPages,
      currentPage: page,
      statusFilter: statusFilter,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, statusFilter: current?.statusFilter));
  }

  Future<void> setStatusFilter(String? status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, statusFilter: status));
  }

  Future<void> nextPage() async {
    final current = state.valueOrNull;
    if (current == null || current.currentPage >= current.totalPages) return;
    state = await AsyncValue.guard(() async {
      final repo = ref.read(salaryRepositoryProvider);
      final result = await repo.listPeriods(
        status: current.statusFilter,
        page: current.currentPage + 1,
      );
      return current.copyWith(
        periods: [...current.periods, ...result.periods],
        total: result.total,
        totalPages: result.totalPages,
        currentPage: current.currentPage + 1,
      );
    });
  }
}

// ─── Salary period detail ───────────────────────────────────────────────────

final salaryPeriodDetailProvider =
    AsyncNotifierProviderFamily<SalaryPeriodDetailNotifier, SalaryPeriod, String>(
        SalaryPeriodDetailNotifier.new);

class SalaryPeriodDetailNotifier extends FamilyAsyncNotifier<SalaryPeriod, String> {
  @override
  Future<SalaryPeriod> build(String id) async {
    return ref.read(salaryRepositoryProvider).getById(id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(salaryRepositoryProvider).getById(arg));
  }

  Future<void> recalculate() async {
    await ref.read(salaryRepositoryProvider).recalculate(arg);
    await refresh();
  }

  Future<void> recordPayment({
    required double amount,
    required String method,
    required String date,
    String? reference,
    String? notes,
  }) async {
    await ref.read(salaryRepositoryProvider).recordPayment(
      salaryPeriodId: arg,
      amountPaid: amount,
      paymentMethod: method,
      paymentDate: date,
      transactionReference: reference,
      notes: notes,
    );
    await refresh();
    ref.read(salaryPeriodsListProvider.notifier).refresh();
  }
}

// ─── Salary generation (preview) ────────────────────────────────────────────

final salaryGenerateProvider =
    AsyncNotifierProvider<SalaryGenerateNotifier, List<SalaryBreakdown>?>(
        SalaryGenerateNotifier.new);

class SalaryGenerateNotifier extends AsyncNotifier<List<SalaryBreakdown>?> {
  @override
  Future<List<SalaryBreakdown>?> build() async => null;

  Future<void> generate(String periodStart, String periodEnd) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(salaryRepositoryProvider);
      return repo.generate(periodStart: periodStart, periodEnd: periodEnd);
    });
  }

  Future<void> confirm(String periodStart, String periodEnd) async {
    final repo = ref.read(salaryRepositoryProvider);
    await repo.confirm(periodStart: periodStart, periodEnd: periodEnd);
    state = const AsyncData(null);
    ref.read(salaryPeriodsListProvider.notifier).refresh();
  }

  void reset() {
    state = const AsyncData(null);
  }
}

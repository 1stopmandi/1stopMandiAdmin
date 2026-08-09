import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/employee.dart';
import '../data/repositories/employee_repository.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) => EmployeeRepository());

// ─── Employees list ─────────────────────────────────────────────────────────

class EmployeesListState {
  final List<Employee> employees;
  final int total;
  final int totalPages;
  final int currentPage;
  final String? search;
  final String statusFilter;
  final String designationFilter;

  const EmployeesListState({
    this.employees = const [],
    this.total = 0,
    this.totalPages = 1,
    this.currentPage = 1,
    this.search,
    this.statusFilter = 'all',
    this.designationFilter = 'all',
  });

  EmployeesListState copyWith({
    List<Employee>? employees,
    int? total,
    int? totalPages,
    int? currentPage,
    String? search,
    bool clearSearch = false,
    String? statusFilter,
    String? designationFilter,
  }) =>
      EmployeesListState(
        employees: employees ?? this.employees,
        total: total ?? this.total,
        totalPages: totalPages ?? this.totalPages,
        currentPage: currentPage ?? this.currentPage,
        search: clearSearch ? null : (search ?? this.search),
        statusFilter: statusFilter ?? this.statusFilter,
        designationFilter: designationFilter ?? this.designationFilter,
      );
}

final employeesListProvider =
    AsyncNotifierProvider<EmployeesListNotifier, EmployeesListState>(
        EmployeesListNotifier.new);

class EmployeesListNotifier extends AsyncNotifier<EmployeesListState> {
  @override
  Future<EmployeesListState> build() async => _fetch(page: 1);

  Future<EmployeesListState> _fetch({int page = 1, EmployeesListState? prev}) async {
    final repo = ref.read(employeeRepositoryProvider);
    final result = await repo.list(
      search: prev?.search,
      status: prev?.statusFilter ?? 'all',
      designation: prev?.designationFilter ?? 'all',
      page: page,
    );
    return EmployeesListState(
      employees: result.employees,
      total: result.total,
      totalPages: result.totalPages,
      currentPage: page,
      search: prev?.search,
      statusFilter: prev?.statusFilter ?? 'all',
      designationFilter: prev?.designationFilter ?? 'all',
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: current));
  }

  Future<void> search(String query) async {
    final current = state.valueOrNull;
    final next = (current ?? const EmployeesListState()).copyWith(
      search: query.trim().isEmpty ? null : query.trim(),
      clearSearch: query.trim().isEmpty,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: next));
  }

  Future<void> setStatusFilter(String status) async {
    final current = state.valueOrNull;
    final next = (current ?? const EmployeesListState()).copyWith(statusFilter: status);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: next));
  }

  Future<void> setDesignationFilter(String designation) async {
    final current = state.valueOrNull;
    final next = (current ?? const EmployeesListState()).copyWith(designationFilter: designation);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: next));
  }

  Future<void> nextPage() async {
    final current = state.valueOrNull;
    if (current == null || current.currentPage >= current.totalPages) return;
    state = await AsyncValue.guard(() async {
      final repo = ref.read(employeeRepositoryProvider);
      final result = await repo.list(
        search: current.search,
        status: current.statusFilter,
        designation: current.designationFilter,
        page: current.currentPage + 1,
      );
      return current.copyWith(
        employees: [...current.employees, ...result.employees],
        total: result.total,
        totalPages: result.totalPages,
        currentPage: current.currentPage + 1,
      );
    });
  }
}

// ─── Employee detail ────────────────────────────────────────────────────────

final employeeDetailProvider =
    AsyncNotifierProviderFamily<EmployeeDetailNotifier, Employee, String>(
        EmployeeDetailNotifier.new);

class EmployeeDetailNotifier extends FamilyAsyncNotifier<Employee, String> {
  @override
  Future<Employee> build(String id) async {
    return ref.read(employeeRepositoryProvider).getById(id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(employeeRepositoryProvider).getById(arg));
  }

  Future<void> updateStatus(String status, {String? notes}) async {
    await ref.read(employeeRepositoryProvider).updateStatus(arg, status, notes: notes);
    await refresh();
    ref.read(employeesListProvider.notifier).refresh();
  }

  Future<void> deleteEmployee() async {
    await ref.read(employeeRepositoryProvider).delete(arg);
    ref.read(employeesListProvider.notifier).refresh();
  }
}

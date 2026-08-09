import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/dashboard_repository.dart';

final employeeDashboardRepositoryProvider =
    Provider<EmployeeDashboardRepository>((ref) => EmployeeDashboardRepository());

final employeeDashboardProvider =
    AsyncNotifierProvider<EmployeeDashboardNotifier, EmployeeDashboardMetrics>(
        EmployeeDashboardNotifier.new);

class EmployeeDashboardNotifier extends AsyncNotifier<EmployeeDashboardMetrics> {
  @override
  Future<EmployeeDashboardMetrics> build() async {
    return ref.read(employeeDashboardRepositoryProvider).getMetrics();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(employeeDashboardRepositoryProvider).getMetrics());
  }
}

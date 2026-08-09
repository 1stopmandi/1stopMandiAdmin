import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/repositories/inventory_reports_repository.dart';

final inventoryReportsRepositoryProvider =
    Provider<InventoryReportsRepository>((ref) => InventoryReportsRepository());

final reportsDateRangeProvider = StateProvider<({String start, String end})>((ref) {
  final now = DateTime.now();
  final firstOfMonth = DateTime(now.year, now.month, 1);
  return (
    start: DateFormat('yyyy-MM-dd').format(firstOfMonth),
    end: DateFormat('yyyy-MM-dd').format(now),
  );
});

final inventorySummaryReportProvider = FutureProvider<InventoryReportSummary>((ref) {
  final range = ref.watch(reportsDateRangeProvider);
  return ref.read(inventoryReportsRepositoryProvider).getSummary(range.start, range.end);
});

final productReportProvider = FutureProvider<List<ProductReportRow>>((ref) {
  final range = ref.watch(reportsDateRangeProvider);
  return ref.read(inventoryReportsRepositoryProvider).getProductSummary(range.start, range.end);
});

final wasteReportProvider = FutureProvider<List<WasteReportRow>>((ref) {
  final range = ref.watch(reportsDateRangeProvider);
  return ref.read(inventoryReportsRepositoryProvider).getWasteSummary(range.start, range.end);
});

final recoverableReportProvider = FutureProvider<List<RecoverableReportRow>>((ref) {
  final range = ref.watch(reportsDateRangeProvider);
  return ref.read(inventoryReportsRepositoryProvider).getRecoverableSummary(range.start, range.end);
});

final employeeReportProvider = FutureProvider<List<EmployeeReportRow>>((ref) {
  final range = ref.watch(reportsDateRangeProvider);
  return ref.read(inventoryReportsRepositoryProvider).getEmployeeSummary(range.start, range.end);
});

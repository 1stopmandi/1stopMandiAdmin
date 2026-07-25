import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/uploaded_order.dart';

final uploadedOrdersListProvider =
    AsyncNotifierProvider<UploadedOrdersListNotifier, List<UploadedOrderSummary>>(
        UploadedOrdersListNotifier.new);

class UploadedOrdersListNotifier extends AsyncNotifier<List<UploadedOrderSummary>> {
  String _status = 'processing';

  String get statusFilter => _status;

  @override
  Future<List<UploadedOrderSummary>> build() async {
    return ref.read(uploadedOrdersRepositoryProvider).list(status: _status);
  }

  Future<void> setStatus(String status) async {
    _status = status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(uploadedOrdersRepositoryProvider).list(status: status),
    );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(uploadedOrdersRepositoryProvider).list(status: _status),
    );
  }
}

final uploadedOrderDetailProvider =
    AsyncNotifierProviderFamily<UploadedOrderDetailNotifier, UploadedOrderDetail, String>(
        UploadedOrderDetailNotifier.new);

class UploadedOrderDetailNotifier extends FamilyAsyncNotifier<UploadedOrderDetail, String> {
  @override
  Future<UploadedOrderDetail> build(String id) async {
    return ref.read(uploadedOrdersRepositoryProvider).getById(id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(uploadedOrdersRepositoryProvider).getById(arg),
    );
    ref.read(uploadedOrdersListProvider.notifier).refresh();
  }

  Future<void> markReady(List<Map<String, dynamic>> items, {String? notes}) async {
    await ref.read(uploadedOrdersRepositoryProvider).markReady(
          arg,
          items: items,
          notes: notes,
        );
    await refresh();
  }

  Future<void> markRejected({String? notes}) async {
    await ref.read(uploadedOrdersRepositoryProvider).markRejected(arg, notes: notes);
    await refresh();
  }
}

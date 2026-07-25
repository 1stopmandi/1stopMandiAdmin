import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/platform_user.dart';

class UsersListState {
  final List<PlatformUserSummary> users;
  final int total;
  final int totalPages;
  final int currentPage;
  final String? search;

  const UsersListState({
    this.users = const [],
    this.total = 0,
    this.totalPages = 1,
    this.currentPage = 1,
    this.search,
  });
}

final usersListProvider =
    AsyncNotifierProvider<UsersListNotifier, UsersListState>(UsersListNotifier.new);

class UsersListNotifier extends AsyncNotifier<UsersListState> {
  @override
  Future<UsersListState> build() async => _fetch(page: 1);

  Future<UsersListState> _fetch({int page = 1, UsersListState? prev}) async {
    final result = await ref.read(adminUsersRepositoryProvider).listUsers(
          search: prev?.search,
          page: page,
        );
    return UsersListState(
      users: result.users,
      total: result.total,
      totalPages: result.totalPages,
      currentPage: page,
      search: prev?.search,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: current));
    ref.invalidate(usersStatsProvider);
  }

  Future<void> search(String query) async {
    final next = UsersListState(
      search: query.trim().isEmpty ? null : query.trim(),
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: next));
  }

  Future<void> nextPage() async {
    final current = state.valueOrNull;
    if (current == null || current.currentPage >= current.totalPages) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(adminUsersRepositoryProvider).listUsers(
            search: current.search,
            page: current.currentPage + 1,
          );
      return UsersListState(
        users: [...current.users, ...result.users],
        total: result.total,
        totalPages: result.totalPages,
        currentPage: current.currentPage + 1,
        search: current.search,
      );
    });
  }
}

final usersStatsProvider = FutureProvider<UsersStats>((ref) async {
  return ref.read(adminUsersRepositoryProvider).getStats();
});

final userDetailProvider =
    AsyncNotifierProviderFamily<UserDetailNotifier, UserDetailState, String>(
        UserDetailNotifier.new);

class UserDetailState {
  final PlatformUserDetail user;
  final List<PlatformUserOrder> orders;

  const UserDetailState({required this.user, this.orders = const []});
}

class UserDetailNotifier extends FamilyAsyncNotifier<UserDetailState, String> {
  @override
  Future<UserDetailState> build(String id) async => _load(id);

  Future<UserDetailState> _load(String id) async {
    final repo = ref.read(adminUsersRepositoryProvider);
    final user = await repo.getUser(id);
    List<PlatformUserOrder> orders = [];
    try {
      orders = await repo.getUserOrders(id);
    } catch (_) {}
    return UserDetailState(user: user, orders: orders);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(arg));
    ref.read(usersListProvider.notifier).refresh();
  }

  Future<void> setRole(String role) async {
    await ref.read(adminUsersRepositoryProvider).setRole(arg, role);
    await refresh();
  }

  Future<void> setBlocked(bool blocked, {String? reason}) async {
    await ref.read(adminUsersRepositoryProvider).setBlocked(
          arg,
          blocked: blocked,
          reason: reason,
        );
    await refresh();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/category.dart';

class CategoriesListState {
  final List<Category> categories;
  final bool showInactive;

  const CategoriesListState({
    this.categories = const [],
    this.showInactive = true,
  });

  CategoriesListState copyWith({
    List<Category>? categories,
    bool? showInactive,
  }) =>
      CategoriesListState(
        categories: categories ?? this.categories,
        showInactive: showInactive ?? this.showInactive,
      );

  List<Category> get visible => showInactive
      ? categories
      : categories.where((c) => c.isActive).toList();
}

final categoriesListProvider =
    AsyncNotifierProvider<CategoriesListNotifier, CategoriesListState>(
        CategoriesListNotifier.new);

class CategoriesListNotifier extends AsyncNotifier<CategoriesListState> {
  @override
  Future<CategoriesListState> build() async => _fetch(showInactive: true);

  Future<CategoriesListState> _fetch({required bool showInactive}) async {
    final list = await ref
        .read(categoriesRepositoryProvider)
        .listCategories(includeInactive: showInactive);
    return CategoriesListState(categories: list, showInactive: showInactive);
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = await AsyncValue.guard(
      () => _fetch(showInactive: current?.showInactive ?? true),
    );
    ref.invalidate(sharedCategoriesProvider);
  }

  Future<void> setShowInactive(bool value) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(showInactive: value));
  }
}

final categoryDetailProvider =
    AsyncNotifierProviderFamily<CategoryDetailNotifier, Category, String>(
        CategoryDetailNotifier.new);

class CategoryDetailNotifier extends FamilyAsyncNotifier<Category, String> {
  @override
  Future<Category> build(String id) async {
    return ref.read(categoriesRepositoryProvider).getCategory(id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(categoriesRepositoryProvider).getCategory(arg),
    );
    ref.read(categoriesListProvider.notifier).refresh();
  }

  Future<void> deactivate() async {
    await ref.read(categoriesRepositoryProvider).deactivateCategory(arg);
    await refresh();
  }

  Future<void> reactivate() async {
    await ref.read(categoriesRepositoryProvider).updateCategory(arg, {
      'is_active': true,
    });
    await refresh();
  }
}

/// Shared category list for product forms and filters.
final sharedCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(categoriesRepositoryProvider).listCategories(includeInactive: true);
});

final categoryNameMapProvider = Provider<Map<String, String>>((ref) {
  final categories = ref.watch(sharedCategoriesProvider).valueOrNull ?? [];
  return {for (final c in categories) c.id: c.name};
});

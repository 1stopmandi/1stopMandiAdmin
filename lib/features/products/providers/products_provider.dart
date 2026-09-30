import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/product.dart';

class ProductsListState {
  final List<ProductSummary> products;
  final int total;
  final int totalPages;
  final int currentPage;
  final String? search;
  final String? categoryFilter;
  final bool? activeFilter;
  final bool loading;
  final String? error;

  const ProductsListState({
    this.products = const [],
    this.total = 0,
    this.totalPages = 1,
    this.currentPage = 1,
    this.search,
    this.categoryFilter,
    this.activeFilter,
    this.loading = false,
    this.error,
  });

  ProductsListState copyWith({
    List<ProductSummary>? products,
    int? total,
    int? totalPages,
    int? currentPage,
    String? search,
    bool clearSearch = false,
    String? categoryFilter,
    bool clearCategoryFilter = false,
    bool? activeFilter,
    bool clearActiveFilter = false,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      ProductsListState(
        products: products ?? this.products,
        total: total ?? this.total,
        totalPages: totalPages ?? this.totalPages,
        currentPage: currentPage ?? this.currentPage,
        search: clearSearch ? null : (search ?? this.search),
        categoryFilter:
            clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
        activeFilter:
            clearActiveFilter ? null : (activeFilter ?? this.activeFilter),
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

final productsListProvider =
    AsyncNotifierProvider<ProductsListNotifier, ProductsListState>(
        ProductsListNotifier.new);

class ProductsListNotifier extends AsyncNotifier<ProductsListState> {
  @override
  Future<ProductsListState> build() async => _fetch(page: 1);

  Future<ProductsListState> _fetch({int page = 1, ProductsListState? prev}) async {
    final repo = ref.read(productsRepositoryProvider);
    final result = await repo.listProducts(
      search: prev?.search,
      categoryId: prev?.categoryFilter,
      isActive: prev?.activeFilter,
      page: page,
    );
    return ProductsListState(
      products: result.products,
      total: result.total,
      totalPages: result.totalPages,
      currentPage: page,
      search: prev?.search,
      categoryFilter: prev?.categoryFilter,
      activeFilter: prev?.activeFilter,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: current));
  }

  Future<void> search(String query) async {
    final current = state.valueOrNull;
    final next = (current ?? const ProductsListState()).copyWith(
      search: query.trim().isEmpty ? null : query.trim(),
      clearSearch: query.trim().isEmpty,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: next));
  }

  Future<void> setCategoryFilter(String? categoryId) async {
    final current = state.valueOrNull;
    final next = (current ?? const ProductsListState()).copyWith(
      categoryFilter: categoryId,
      clearCategoryFilter: categoryId == null,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: next));
  }

  Future<void> setActiveFilter(bool? active) async {
    final current = state.valueOrNull;
    final next = (current ?? const ProductsListState()).copyWith(
      activeFilter: active,
      clearActiveFilter: active == null,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, prev: next));
  }

  Future<void> nextPage() async {
    final current = state.valueOrNull;
    if (current == null || current.currentPage >= current.totalPages || current.loading) return;
    
    state = AsyncData(current.copyWith(loading: true));
    try {
      final repo = ref.read(productsRepositoryProvider);
      final result = await repo.listProducts(
        search: current.search,
        categoryId: current.categoryFilter,
        isActive: current.activeFilter,
        page: current.currentPage + 1,
      );
      state = AsyncData(current.copyWith(
        products: [...current.products, ...result.products],
        total: result.total,
        totalPages: result.totalPages,
        currentPage: current.currentPage + 1,
        loading: false,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(loading: false, error: e.toString()));
    }
  }
}

final productDetailProvider =
    AsyncNotifierProviderFamily<ProductDetailNotifier, ProductDetail, String>(
        ProductDetailNotifier.new);

class ProductDetailNotifier extends FamilyAsyncNotifier<ProductDetail, String> {
  @override
  Future<ProductDetail> build(String id) async {
    return ref.read(productsRepositoryProvider).getProduct(id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(productsRepositoryProvider).getProduct(arg),
    );
    ref.read(productsListProvider.notifier).refresh();
  }

  Future<void> deactivate() async {
    await ref.read(productsRepositoryProvider).deactivateProduct(arg);
    await refresh();
  }

  Future<void> reactivate() async {
    await ref.read(productsRepositoryProvider).updateProduct(arg, {
      'is_active': true,
    });
    await refresh();
  }
}

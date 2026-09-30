import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/product.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/skeleton_card.dart';
import '../../../categories/providers/categories_provider.dart';
import '../../providers/products_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late final ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrolled = _scrollController.hasClients && _scrollController.offset > 40;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return productAsync.when(
      data: (product) {
        return AppPageScaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'Product Details',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: Colors.black87,
              onPressed: () => Navigator.of(context).pop(),
            ),
            elevation: _isScrolled ? 0.5 : 0,
            scrolledUnderElevation: 0,
            backgroundColor: _isScrolled
                ? Colors.white.withValues(alpha: 0.96)
                : Colors.transparent,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                onPressed: () async {
                  final updated = await context.push<bool>('/products/${widget.productId}/edit');
                  if (updated == true) {
                    ref.read(productDetailProvider(widget.productId).notifier).refresh();
                  }
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
            onRefresh: () async {
              ref.invalidate(productDetailProvider(widget.productId));
              await ref.read(productDetailProvider(widget.productId).future);
            },
            child: _ProductDetailBody(
              product: product,
              productId: widget.productId,
              scrollController: _scrollController,
            ),
          ),
        );
      },
      loading: () => AppPageScaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Product Details',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: Colors.black87,
            onPressed: () => Navigator.of(context).pop(),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: const AdminProductDetailSkeleton(),
      ),
      error: (e, st) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppToast.error(context, friendlyError(e));
        });
        return AppPageScaffold(
          title: 'Product Details',
          body: ErrorView(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
          ),
        );
      },
    );
  }
}

class _ProductDetailBody extends ConsumerWidget {
  final ProductDetail product;
  final String productId;
  final ScrollController scrollController;

  const _ProductDetailBody({
    required this.product,
    required this.productId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryNames = ref.watch(categoryNameMapProvider);
    final categoryName = product.categoryId != null ? categoryNames[product.categoryId] : null;
    final notifier = ref.read(productDetailProvider(productId).notifier);

    return SingleChildScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero Banner ─────────────────────────────────────
          _HeaderBanner(product: product, categoryName: categoryName),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Details'),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _Row('Unit', product.unit),
                      _Row('Brand', product.brand),
                      _Row('MOQ', product.moq?.toString()),
                      _Row('Stock', product.stock?.toString()),
                      if (product.description != null && product.description!.isNotEmpty)
                        _Row('Description', product.description),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (product.pricing != null) ...[
                  const SectionHeader(title: 'Pricing'),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Row(
                          'Base price',
                          '₹${product.pricing!.basePrice.toStringAsFixed(2)}',
                          bold: true,
                        ),
                        if (product.pricing!.slabs.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          const Text(
                            'Quantity Slabs',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          ...product.pricing!.slabs.map((s) {
                            final max = s.maxQty == null ? '+' : '–${s.maxQty!.toStringAsFixed(0)}';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      '${s.minQty.toStringAsFixed(0)}$max ${product.unit}',
                                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Text(
                                    '₹${s.pricePerUnit.toStringAsFixed(2)}/${product.unit}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),
                if (product.isActive)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.visibility_off, color: Colors.red),
                      label: const Text('Deactivate product', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => _deactivate(context, notifier),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      icon: const Icon(Icons.visibility),
                      label: 'Reactivate product',
                      onPressed: () => _reactivate(context, notifier),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivate(BuildContext context, ProductDetailNotifier notifier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate product'),
        content: const Text(
          'This hides the product from the catalog but preserves order history. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await notifier.deactivate();
      if (context.mounted) {
        AppToast.success(context, 'Product deactivated successfully');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, friendlyError(e));
      }
    }
  }

  Future<void> _reactivate(BuildContext context, ProductDetailNotifier notifier) async {
    try {
      await notifier.reactivate();
      if (context.mounted) {
        AppToast.success(context, 'Product reactivated successfully');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, friendlyError(e));
      }
    }
  }
}

class _HeaderBanner extends StatelessWidget {
  final ProductDetail product;
  final String? categoryName;

  const _HeaderBanner({required this.product, this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
      ),
      child: Stack(
        children: [
          if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                product.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 40,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _VegBadge(isVeg: product.isVeg),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  product.slug,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppChip(
                      label: product.isActive ? 'Active' : 'Inactive',
                      color: product.isActive ? Colors.green : Colors.grey,
                      variant: AppChipVariant.filled,
                    ),
                    if (categoryName != null)
                      AppChip(label: categoryName!, color: Colors.blue, variant: AppChipVariant.filled),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String? value;
  final bool bold;

  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value!,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _VegBadge extends StatelessWidget {
  final bool isVeg;

  const _VegBadge({required this.isVeg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isVeg ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isVeg ? 'VEG' : 'NON-VEG',
            style: TextStyle(
              color: isVeg ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

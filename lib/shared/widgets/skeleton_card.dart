import 'package:flutter/material.dart';
import 'app_shimmer.dart';

enum ContentSkeletonType { list, detail, form, dashboard }

class ContentSkeleton extends StatelessWidget {
  const ContentSkeleton({
    super.key,
    this.type = ContentSkeletonType.detail,
    this.itemCount = 5,
    this.padding = const EdgeInsets.all(16),
  });

  final ContentSkeletonType type;
  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: switch (type) {
            ContentSkeletonType.list => [
                const ShimmerBox(width: double.infinity, height: 46, radius: 12),
                const SizedBox(height: 14),
                for (var i = 0; i < itemCount; i++) ...[
                  const _SkeletonSurface(
                    child: Row(
                      children: [
                        ShimmerBox(width: 52, height: 52, radius: 12),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBox(width: 150, height: 15, radius: 5),
                              SizedBox(height: 8),
                              ShimmerBox(width: 210, height: 12, radius: 5),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        ShimmerBox(width: 24, height: 24, radius: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ContentSkeletonType.detail => [
                const ShimmerBox(width: double.infinity, height: 116, radius: 16),
                const SizedBox(height: 16),
                for (var section = 0; section < 3; section++) ...[
                  const _SkeletonSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 120, height: 16, radius: 5),
                        SizedBox(height: 16),
                        ShimmerBox(width: double.infinity, height: 13, radius: 5),
                        SizedBox(height: 10),
                        ShimmerBox(width: 220, height: 13, radius: 5),
                        SizedBox(height: 10),
                        ShimmerBox(width: 170, height: 13, radius: 5),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ContentSkeletonType.form => [
                for (var i = 0; i < itemCount; i++) ...[
                  const ShimmerBox(width: 110, height: 13, radius: 5),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: double.infinity, height: 54, radius: 12),
                  const SizedBox(height: 18),
                ],
                const ShimmerBox(width: double.infinity, height: 50, radius: 12),
              ],
            ContentSkeletonType.dashboard => [
                Row(
                  children: List.generate(
                    2,
                    (_) => const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: ShimmerBox(width: double.infinity, height: 104, radius: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const ShimmerBox(width: double.infinity, height: 210, radius: 16),
                const SizedBox(height: 16),
                const ShimmerBox(width: double.infinity, height: 170, radius: 16),
              ],
          },
        ),
      ),
    );
  }
}

class _SkeletonSurface extends StatelessWidget {
  const _SkeletonSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

/// Skeleton for an order list card — matching the exact layout of the admin order card
class AdminOrderCardSkeleton extends StatelessWidget {
  const AdminOrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent strip (5px wide shimmering strip)
            const AppShimmer(
              child: ShimmerBox(
                width: 5,
                height: double.infinity,
                radius: 0,
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: AppShimmer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: order number + status chip pill
                      Row(
                        children: [
                          const ShimmerBox(width: 125, height: 16, radius: 4),
                          const Spacer(),
                          // OrderStatusChip pill replica
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8ECF0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShimmerBox(width: 10, height: 10, radius: 5),
                                SizedBox(width: 5),
                                ShimmerBox(width: 52, height: 11, radius: 3),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      // Buyer name line
                      const ShimmerBox(width: 100, height: 14, radius: 4),

                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: const Color(0xFFF1F4F8),
                      ),
                      const SizedBox(height: 12),

                      // Bottom row: amount + deliver by
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ShimmerBox(width: 50, height: 16, radius: 4),
                          Spacer(),
                          ShimmerBox(width: 13, height: 13, radius: 3),
                          SizedBox(width: 4),
                          ShimmerBox(width: 110, height: 13, radius: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-page skeleton list for the admin app.
class AdminSkeletonListView extends StatelessWidget {
  const AdminSkeletonListView.orders({super.key})
      : _count = 5,
        _padding = const EdgeInsets.fromLTRB(16, 16, 16, 120),
        _type = _SkeletonType.order;

  const AdminSkeletonListView.clients({super.key})
      : _count = 6,
        _padding = const EdgeInsets.fromLTRB(12, 12, 12, 120),
        _type = _SkeletonType.client;

  const AdminSkeletonListView.products({super.key})
      : _count = 6,
        _padding = const EdgeInsets.fromLTRB(12, 12, 12, 120),
        _type = _SkeletonType.product;

  const AdminSkeletonListView.categories({super.key})
      : _count = 6,
        _padding = const EdgeInsets.fromLTRB(12, 12, 12, 120),
        _type = _SkeletonType.category;

  final int _count;
  final EdgeInsetsGeometry _padding;
  final _SkeletonType _type;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: _padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _count,
      itemBuilder: (_, i) => switch (_type) {
        _SkeletonType.order => const AdminOrderCardSkeleton(),
        _SkeletonType.client => const AdminClientCardSkeleton(),
        _SkeletonType.product => const AdminProductCardSkeleton(),
        _SkeletonType.category => const AdminCategoryCardSkeleton(),
      },
    );
  }
}

enum _SkeletonType { order, client, product, category }

class AdminCategoryCardSkeleton extends StatelessWidget {
  const AdminCategoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(14),
      child: AppShimmer(
        child: Row(
          children: [
            const ShimmerBox(width: 48, height: 48, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      ShimmerBox(width: 120, height: 16, radius: 4),
                      Spacer(),
                      ShimmerBox(width: 50, height: 22, radius: 12),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const ShimmerBox(width: 80, height: 12, radius: 4),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 100, height: 22, radius: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminCategoryDetailSkeleton extends StatelessWidget {
  const AdminCategoryDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner
          const AppShimmer(
            child: ShimmerBox(width: double.infinity, height: 120, radius: 12),
          ),
          const SizedBox(height: 16),
          // Sections Skeleton
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            child: AppShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: 90, height: 16, radius: 4),
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F4F8)),
                  const SizedBox(height: 12),
                  for (int i = 0; i < 2; i++) ...[
                    const Row(
                      children: [
                        ShimmerBox(width: 100, height: 14, radius: 4),
                        SizedBox(width: 20),
                        Expanded(child: ShimmerBox(width: double.infinity, height: 14, radius: 4)),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminProductCardSkeleton extends StatelessWidget {
  const AdminProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(14),
      child: AppShimmer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: 56, height: 56, radius: 8),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      ShimmerBox(width: 140, height: 16, radius: 4),
                      Spacer(),
                      ShimmerBox(width: 50, height: 16, radius: 8),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const ShimmerBox(width: 80, height: 12, radius: 4),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const ShimmerBox(width: 70, height: 22, radius: 12),
                      const SizedBox(width: 6),
                      const ShimmerBox(width: 60, height: 22, radius: 12),
                      const SizedBox(width: 6),
                      const ShimmerBox(width: 50, height: 22, radius: 12),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminProductDetailSkeleton extends StatelessWidget {
  const AdminProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner
          const AppShimmer(
            child: ShimmerBox(width: double.infinity, height: 220, radius: 12),
          ),
          const SizedBox(height: 16),
          // Sections Skeleton
          for (int s = 0; s < 3; s++) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              child: AppShimmer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerBox(width: 90, height: 16, radius: 4),
                    const SizedBox(height: 12),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F4F8)),
                    const SizedBox(height: 12),
                    for (int i = 0; i < 3; i++) ...[
                      const Row(
                        children: [
                          ShimmerBox(width: 100, height: 14, radius: 4),
                          SizedBox(width: 20),
                          Expanded(child: ShimmerBox(width: double.infinity, height: 14, radius: 4)),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AdminClientCardSkeleton extends StatelessWidget {
  const AdminClientCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(14),
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                ShimmerBox(width: 140, height: 16, radius: 4),
                Spacer(),
                ShimmerBox(width: 60, height: 22, radius: 12),
              ],
            ),
            const SizedBox(height: 8),
            const ShimmerBox(width: 100, height: 14, radius: 4),
            const SizedBox(height: 12),
            Row(
              children: [
                const ShimmerBox(width: 80, height: 22, radius: 12),
                const SizedBox(width: 8),
                const ShimmerBox(width: 60, height: 22, radius: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton matching the exact layout of Admin's ClientDetailScreen
class AdminClientDetailSkeleton extends StatelessWidget {
  const AdminClientDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner
          const AppShimmer(
            child: ShimmerBox(width: double.infinity, height: 70, radius: 12),
          ),
          const SizedBox(height: 16),
          // Sections Skeleton
          for (int s = 0; s < 3; s++) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              child: AppShimmer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerBox(width: 90, height: 16, radius: 4),
                    const SizedBox(height: 12),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F4F8)),
                    const SizedBox(height: 12),
                    for (int i = 0; i < 4; i++) ...[
                      const Row(
                        children: [
                          ShimmerBox(width: 100, height: 14, radius: 4),
                          SizedBox(width: 20),
                          Expanded(child: ShimmerBox(width: double.infinity, height: 14, radius: 4)),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer skeleton matching the exact layout of Admin's OrderDetailScreen
class AdminOrderDetailSkeleton extends StatelessWidget {
  const AdminOrderDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Status Banner Skeleton ────────────────────────────────────
          const AppShimmer(
            child: ShimmerBox(width: double.infinity, height: 50, radius: 12),
          ),
          const SizedBox(height: 16),

          // ── Sections Skeleton ──────────────────────────────────────────
          for (int s = 0; s < 3; s++) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              child: AppShimmer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerBox(width: 90, height: 16, radius: 4),
                    const SizedBox(height: 12),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F4F8)),
                    const SizedBox(height: 12),
                    for (int i = 0; i < (s == 2 ? 3 : 4); i++) ...[
                      const Row(
                        children: [
                          ShimmerBox(width: 100, height: 14, radius: 4),
                          SizedBox(width: 20),
                          Expanded(child: ShimmerBox(width: double.infinity, height: 14, radius: 4)),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          // Actions skeleton
          const AppShimmer(
            child: Column(
              children: [
                ShimmerBox(width: double.infinity, height: 44, radius: 8),
                SizedBox(height: 10),
                ShimmerBox(width: double.infinity, height: 44, radius: 8),
              ],
            ),
          )
        ],
      ),
    );
  }
}

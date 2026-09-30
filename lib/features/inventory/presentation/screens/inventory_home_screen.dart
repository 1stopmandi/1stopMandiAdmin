import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_provider.dart';
import '../../data/models/inventory_record.dart';
import '../../../../core/widgets/admin_menu_button.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_card.dart';

class InventoryHomeScreen extends ConsumerStatefulWidget {
  const InventoryHomeScreen({super.key});

  @override
  ConsumerState<InventoryHomeScreen> createState() =>
      _InventoryHomeScreenState();
}

class _InventoryHomeScreenState extends ConsumerState<InventoryHomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(inventoryListProvider.notifier).nextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(inventoryListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Inventory Records'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(inventoryListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/inventory-mgmt/create'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _SearchBar(controller: _searchController),
          _FilterChips(),
          Expanded(
            child: listAsync.when(
              loading: () => const ContentSkeleton(type: ContentSkeletonType.list),
              error: (e, _) => ErrorView(
                message: friendlyError(e),
                onRetry: () => ref.read(inventoryListProvider.notifier).refresh(),
              ),
              data: (state) => state.records.isEmpty
                  ? EmptyStateView(
                      icon: Icons.inventory_2_outlined,
                      title: 'No inventory records found',
                      subtitle: 'Create the first purchasing and stock record.',
                      actionLabel: 'Create record',
                      onAction: () => context.push('/inventory-mgmt/create'),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(inventoryListProvider.notifier).refresh(),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: state.records.length,
                        itemBuilder: (ctx, i) =>
                            _RecordCard(record: state.records[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search by title...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    ref.read(inventoryListProvider.notifier).search('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        onSubmitted: (v) => ref.read(inventoryListProvider.notifier).search(v),
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryListProvider).valueOrNull;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Draft'),
            selected: state?.statusFilter == 'draft',
            onSelected: (v) => ref
                .read(inventoryListProvider.notifier)
                .setStatusFilter(v ? 'draft' : null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Finalized'),
            selected: state?.statusFilter == 'finalized',
            onSelected: (v) => ref
                .read(inventoryListProvider.notifier)
                .setStatusFilter(v ? 'finalized' : null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Today'),
            selected: state?.dateFilter != null,
            onSelected: (v) {
              if (v) {
                final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                ref.read(inventoryListProvider.notifier).setDateFilter(today);
              } else {
                ref.read(inventoryListProvider.notifier).setDateFilter(null);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final InventoryRecord record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(record.recordDate);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => context.push('/inventory-mgmt/${record.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(record.displayTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  Text(dateStr,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Stat('Purchase batches', '${record.purchasingBatchCount}'),
                  _Stat('Rows', '${record.totalRowCount}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _Stat(
                    'Purchase',
                    '${record.totalPurchasedWeight.toStringAsFixed(1)} kg • '
                        '₹${record.purchasingGrandTotal.toStringAsFixed(0)}',
                    color: Colors.green,
                  ),
                  _Stat(
                    'Dispatch',
                    '${record.totalDispatchWeight.toStringAsFixed(1)} kg • '
                        '₹${record.totalDispatchAmount.toStringAsFixed(0)}',
                    color: Colors.blue,
                  ),
                  _Stat(
                    'Waste',
                    '${record.totalWasteQty.toStringAsFixed(1)} kg',
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: record.isDraft
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      record.isDraft ? 'Draft' : 'Finalized',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: record.isDraft
                            ? Colors.orange[800]
                            : Colors.green[800],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (record.isDraft)
                    TextButton(
                      onPressed: () =>
                          context.push('/inventory-mgmt/${record.id}/edit'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Edit'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/uploaded_orders_provider.dart';
import '../../../../core/widgets/admin_menu_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../data/models/uploaded_order.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_card.dart';

class UploadedOrdersListScreen extends ConsumerWidget {
  const UploadedOrdersListScreen({super.key});

  static const _filters = [
    ('processing', 'Processing'),
    ('ready', 'Ready'),
    ('rejected', 'Rejected'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(uploadedOrdersListProvider);
    final status = ref.read(uploadedOrdersListProvider.notifier).statusFilter;

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Uploaded Orders'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(uploadedOrdersListProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: _filters.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.$2),
                    selected: status == f.$1,
                    onSelected: (_) => ref
                        .read(uploadedOrdersListProvider.notifier)
                        .setStatus(f.$1),
                    selectedColor: Colors.green[200],
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const ContentSkeleton(type: ContentSkeletonType.list),
              error: (e, _) => ErrorView(
                message: friendlyError(e),
                onRetry: () => ref.read(uploadedOrdersListProvider.notifier).refresh(),
              ),
              data: (items) => items.isEmpty
                  ? EmptyStateView(
                      icon: Icons.upload_file_outlined,
                      title: 'No uploads in this status',
                      subtitle: 'New buyer uploads will appear here.',
                      actionLabel: 'Refresh',
                      onAction: () => ref.read(uploadedOrdersListProvider.notifier).refresh(),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(uploadedOrdersListProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _UploadCard(upload: items[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  final UploadedOrderSummary upload;
  static final _fmt = DateFormat('dd MMM, hh:mm a');

  const _UploadCard({required this.upload});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.push('/uploaded-orders/${upload.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  resolveMediaUrl(upload.imageUrl),
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(upload.buyerLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (upload.userPhone != null)
                      Text(upload.userPhone!,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (upload.createdAt != null)
                      Text(_fmt.format(upload.createdAt!.toLocal()),
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

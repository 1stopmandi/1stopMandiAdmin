import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/clients_provider.dart';
import '../../../../core/widgets/admin_menu_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../data/models/client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_async_view.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/skeleton_card.dart';

class ClientsListScreen extends ConsumerStatefulWidget {
  const ClientsListScreen({super.key});

  @override
  ConsumerState<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends ConsumerState<ClientsListScreen> {
  final _searchCtrl = TextEditingController();

  static const _approvalFilters = [
    (null, 'All'),
    ('pending', 'Pending'),
    ('approved', 'Approved'),
    ('rejected', 'Rejected'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsListProvider);
    final currentState = clientsAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Clients'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(clientsListProvider.notifier).refresh(),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/clients/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Client'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search phone, name, business…',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref.read(clientsListProvider.notifier).search('');
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (v) =>
                        ref.read(clientsListProvider.notifier).search(v),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: () =>
                      ref.read(clientsListProvider.notifier).search(_searchCtrl.text),
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          _FilterBar(
            approvalFilter: currentState?.approvalFilter,
            outstandingOnly: currentState?.outstandingOnly ?? false,
            onApprovalChanged: (v) =>
                ref.read(clientsListProvider.notifier).setApprovalFilter(v),
            onOutstandingChanged: (v) =>
                ref.read(clientsListProvider.notifier).toggleOutstandingOnly(v),
          ),
          Expanded(
            child: AppAsyncView<ClientsListState>(
              asyncValue: clientsAsync,
              skeleton: const AdminSkeletonListView.clients(),
              onRefresh: () => ref.read(clientsListProvider.notifier).refresh(),
              onRetry: () => ref.read(clientsListProvider.notifier).refresh(),
              isEmpty: (state) => state.clients.isEmpty,
              emptyState: const EmptyStateView(
                icon: Icons.people_outline,
                title: 'No clients found',
                subtitle: 'Try adjusting your filters or search query.',
              ),
              builder: (context, state) {
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  itemCount: state.clients.length +
                      (state.currentPage < state.totalPages ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == state.clients.length) {
                      if (!state.loading) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref.read(clientsListProvider.notifier).nextPage();
                        });
                      }
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: AdminClientCardSkeleton(),
                        ),
                      );
                    }
                    return _ClientCard(client: state.clients[i]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? approvalFilter;
  final bool outstandingOnly;
  final ValueChanged<String?> onApprovalChanged;
  final ValueChanged<bool> onOutstandingChanged;

  const _FilterBar({
    required this.approvalFilter,
    required this.outstandingOnly,
    required this.onApprovalChanged,
    required this.onOutstandingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          ..._ClientsListScreenState._approvalFilters.map((f) {
            final selected = approvalFilter == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f.$2),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) => onApprovalChanged(f.$1),
                selectedColor: AppColors.primary.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : Colors.black87,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: selected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
              ),
            );
          }),
          FilterChip(
            label: const Text('Outstanding'),
            selected: outstandingOnly,
            showCheckmark: false,
            onSelected: onOutstandingChanged,
            selectedColor: Colors.orange.shade100,
            labelStyle: TextStyle(
              color: outstandingOnly ? Colors.orange.shade800 : Colors.black87,
              fontWeight: outstandingOnly ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: outstandingOnly ? Colors.orange.shade800 : Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final ClientSummary client;
  static final _dateFmt = DateFormat('dd MMM yyyy');

  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.push('/clients/${client.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  client.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (client.isBlocked)
                const AppChip(label: 'Blocked', color: Colors.red)
              else if (client.accountStatus == 'provisional')
                const AppChip(label: 'Provisional', color: Colors.blue),
            ],
          ),
          if (client.phone != null) ...[
            const SizedBox(height: 4),
            Text(client.phone!, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppChip(
                label: _label(client.setupApprovalStatus),
                color: _approvalColor(client.setupApprovalStatus),
              ),
              if (client.outstandingBalance > 0)
                AppChip(
                  label: '₹${client.outstandingBalance.toStringAsFixed(0)} due',
                  color: Colors.orange.shade800,
                ),
              if (client.isSetupCompleted)
                const AppChip(label: 'Setup done', color: AppColors.primary),
            ],
          ),
          if (client.createdAt != null) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Joined ${_dateFmt.format(client.createdAt!.toLocal())}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _label(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  static Color _approvalColor(String status) => switch (status) {
        'approved' => AppColors.primary,
        'rejected' => Colors.red,
        _ => Colors.orange,
      };
}

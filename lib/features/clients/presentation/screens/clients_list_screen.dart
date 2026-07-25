import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/clients_provider.dart';
import '../../../../core/widgets/admin_menu_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../data/models/client.dart';

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

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Clients'),
        backgroundColor: Colors.green[800],
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
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Client'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search phone, name, business…',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
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
                  onPressed: () =>
                      ref.read(clientsListProvider.notifier).search(_searchCtrl.text),
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          _FilterBar(
            approvalFilter: clientsAsync.valueOrNull?.approvalFilter,
            outstandingOnly: clientsAsync.valueOrNull?.outstandingOnly ?? false,
            onApprovalChanged: (v) =>
                ref.read(clientsListProvider.notifier).setApprovalFilter(v),
            onOutstandingChanged: (v) =>
                ref.read(clientsListProvider.notifier).toggleOutstandingOnly(v),
          ),
          Expanded(
            child: clientsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(e.toString()),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(clientsListProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (state) => state.clients.isEmpty
                  ? const Center(child: Text('No clients found'))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(clientsListProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.clients.length +
                            (state.currentPage < state.totalPages ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == state.clients.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: ElevatedButton(
                                  onPressed: () => ref
                                      .read(clientsListProvider.notifier)
                                      .nextPage(),
                                  child: const Text('Load more'),
                                ),
                              ),
                            );
                          }
                          return _ClientCard(client: state.clients[i]);
                        },
                      ),
                    ),
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
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          ..._ClientsListScreenState._approvalFilters.map((f) {
            final selected = approvalFilter == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f.$2),
                selected: selected,
                onSelected: (_) => onApprovalChanged(f.$1),
                selectedColor: Colors.green[200],
              ),
            );
          }),
          FilterChip(
            label: const Text('Outstanding'),
            selected: outstandingOnly,
            onSelected: onOutstandingChanged,
            selectedColor: Colors.orange[200],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/clients/${client.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (client.isBlocked)
                    _Badge('Blocked', Colors.red)
                  else if (client.accountStatus == 'provisional')
                    _Badge('Provisional', Colors.blue),
                ],
              ),
              if (client.phone != null) ...[
                const SizedBox(height: 4),
                Text(client.phone!, style: const TextStyle(color: Colors.black87)),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _Badge(
                    _label(client.setupApprovalStatus),
                    _approvalColor(client.setupApprovalStatus),
                  ),
                  if (client.outstandingBalance > 0)
                    _Badge(
                      '₹${client.outstandingBalance.toStringAsFixed(0)} due',
                      Colors.orange,
                    ),
                  if (client.isSetupCompleted)
                    const _Badge('Setup done', Colors.green),
                ],
              ),
              if (client.createdAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Joined ${_dateFmt.format(client.createdAt!.toLocal())}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _label(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  static Color _approvalColor(String status) => switch (status) {
        'approved' => Colors.green,
        'rejected' => Colors.red,
        _ => Colors.orange,
      };
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/users_provider.dart';
import '../../../../core/widgets/admin_menu_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../data/models/platform_user.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersListProvider);
    final statsAsync = ref.watch(usersStatsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AdminMenuButton(),
        title: const Text('Users'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(usersListProvider.notifier).refresh(),
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
          statsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (s) => Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip('${s.totalUsers} users', Colors.blue),
                  _StatChip('${s.totalAdmins} admins', Colors.purple),
                  _StatChip('${s.blockedUsers} blocked', Colors.red),
                  _StatChip('${s.pendingOrders} pending orders', Colors.orange),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search phone or name…',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () =>
                      ref.read(usersListProvider.notifier).search(_searchCtrl.text),
                ),
              ),
              onSubmitted: (v) => ref.read(usersListProvider.notifier).search(v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (state) => state.users.isEmpty
                  ? const Center(child: Text('No users found'))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(usersListProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.users.length +
                            (state.currentPage < state.totalPages ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == state.users.length) {
                            return Center(
                              child: TextButton(
                                onPressed: () =>
                                    ref.read(usersListProvider.notifier).nextPage(),
                                child: const Text('Load more'),
                              ),
                            );
                          }
                          return _UserCard(user: state.users[i]);
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

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}

class _UserCard extends StatelessWidget {
  final PlatformUserSummary user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/users/${user.id}'),
        title: Text(user.displayName),
        subtitle: Text('${user.phone ?? '—'} · ${user.role}'),
        trailing: user.role == 'admin'
            ? const Icon(Icons.admin_panel_settings, color: Colors.purple)
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

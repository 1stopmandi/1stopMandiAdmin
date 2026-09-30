import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/skeleton_card.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../providers/users_provider.dart';

class UserDetailScreen extends ConsumerWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(userDetailProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Detail'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(userDetailProvider(userId).notifier).refresh(),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const ContentSkeleton(type: ContentSkeletonType.detail),
        error: (e, _) => ErrorView(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(userDetailProvider(userId)),
        ),
        data: (state) => _Body(state: state, userId: userId),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final UserDetailState state;
  final String userId;

  const _Body({required this.state, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = state.user;
    final notifier = ref.read(userDetailProvider(userId).notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(user.name ?? user.phone ?? user.id,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (user.businessName != null) Text(user.businessName!),
        const SizedBox(height: 12),
        _Row('Phone', user.phone),
        _Row('Email', user.email),
        _Row('Role', user.role),
        _Row('Setup', user.isSetupCompleted ? 'Complete' : 'Incomplete'),
        if (user.isBlocked)
          Text('Blocked: ${user.blockedReason ?? '—'}',
              style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            if (user.role != 'admin')
              ActionChip(
                label: const Text('Make admin'),
                onPressed: () => _setRole(context, notifier, 'admin'),
              ),
            if (user.role != 'buyer')
              ActionChip(
                label: const Text('Make buyer'),
                onPressed: () => _setRole(context, notifier, 'buyer'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (user.isBlocked)
          OutlinedButton(
            onPressed: () => notifier.setBlocked(false),
            child: const Text('Unblock user'),
          )
        else
          OutlinedButton(
            onPressed: () => _block(context, notifier),
            child: const Text('Block user', style: TextStyle(color: Colors.red)),
          ),
        if (state.orders.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Recent orders',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...state.orders.map((o) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('#${o.orderNumber}'),
                subtitle: Text('${o.status} · ₹${o.totalAmount.toStringAsFixed(2)}'),
              )),
        ],
      ],
    );
  }

  Future<void> _setRole(
    BuildContext context,
    dynamic notifier,
    String role,
  ) async {
    try {
      await notifier.setRole(role);
      if (context.mounted) {
        AppToast.success(context, 'Role set to $role');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, friendlyError(e));
      }
    }
  }

  Future<void> _block(BuildContext context, dynamic notifier) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block user'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            hintText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await notifier.setBlocked(true, reason: reasonCtrl.text.trim());
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, friendlyError(e));
      }
    }
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String? value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value!)),
        ],
      ),
    );
  }
}

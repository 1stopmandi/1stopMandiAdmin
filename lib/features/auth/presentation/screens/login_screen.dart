import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/app_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).sendEmailOtp(_emailCtrl.text.trim());
      setState(() { _otpSent = true; });
      if (mounted) AppToast.success(context, 'OTP sent to your email');
    } catch (e) {
      if (mounted) {
        setState(() { _error = friendlyError(e); });
        AppToast.error(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _verify() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).verifyEmailOtp(
        _emailCtrl.text.trim(),
        _otpCtrl.text.trim(),
      );
      if (mounted) context.go('/orders');
    } catch (e) {
      setState(() {
        _error = friendlyError(e).contains('admin')
            ? friendlyError(e)
            : 'Login failed. Make sure your account has admin role.';
      });
      if (mounted) AppToast.error(context, _error!);
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE5F7EA), AppColors.background, Color(0xFFEAF0FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 26, offset: const Offset(0, 10))],
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 24),
                    Text('Operations, in one place.', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                    const SizedBox(height: 8),
                    Text('Sign in to manage orders, clients, inventory and your team.', style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.45)),
                    const SizedBox(height: 28),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(_otpSent ? 'Verify your email' : 'Admin sign in', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 20),
                          TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: _otpSent ? TextInputAction.next : TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Work email',
                  hintText: 'admin@1stopmandi.com',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                enabled: !_otpSent,
              ),
              if (_otpSent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '6-digit OTP',
                    hintText: '• • • • • •',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  onSubmitted: (_) => _verify(),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
                          FilledButton.icon(
                onPressed: _loading
                    ? null
                    : (_otpSent ? _verify : _sendOtp),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                icon: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,
                        ),
                      )
                    : Icon(_otpSent ? Icons.verified_user_rounded : Icons.arrow_forward_rounded),
                label: Text(_loading ? 'Please wait…' : (_otpSent ? 'Verify & continue' : 'Send secure OTP')),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 12),
                            TextButton.icon(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _otpSent = false;
                            _otpCtrl.clear();
                          }),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Change email'),
                ),
              ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Access is restricted to approved administrators.', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

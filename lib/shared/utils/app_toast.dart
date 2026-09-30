import 'dart:async';

import 'package:flutter/material.dart';

/// Toast notification types.
enum ToastType { success, warning, error, info }

/// App-wide toast utility.
/// Shows a premium floating toast at the bottom of the screen.
///
/// Usage:
/// ```dart
/// AppToast.success(context, 'Item added to cart!');
/// AppToast.error(context, 'Something went wrong. Please try again.');
/// AppToast.warning(context, 'Prices have changed. Please review.');
/// ```
abstract class AppToast {
  /// Notifies listeners whenever a floating toast is currently visible on screen.
  static final ValueNotifier<bool> isVisible = ValueNotifier<bool>(false);

  static int _token = 0;
  static Timer? _fallbackTimer;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final currentToken = ++_token;
    isVisible.value = true;
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(duration + const Duration(milliseconds: 600), () {
      if (_token == currentToken && isVisible.value) {
        isVisible.value = false;
      }
    });

    final (icon, bg, fg) = switch (type) {
      ToastType.success => (
          Icons.check_circle_rounded,
          const Color(0xFF16A34A),
          Colors.white,
        ),
      ToastType.warning => (
          Icons.warning_amber_rounded,
          const Color(0xFFF59E0B),
          Colors.white,
        ),
      ToastType.error => (
          Icons.cancel_rounded,
          const Color(0xFFDC2626),
          Colors.white,
        ),
      ToastType.info => (
          Icons.info_rounded,
          const Color(0xFF2563EB),
          Colors.white,
        ),
    };

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: bg.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    controller.closed.then((_) {
      if (_token == currentToken) {
        _fallbackTimer?.cancel();
        isVisible.value = false;
      }
    });
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: ToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: ToastType.error);

  static void warning(BuildContext context, String message) =>
      show(context, message, type: ToastType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message, type: ToastType.info);
}

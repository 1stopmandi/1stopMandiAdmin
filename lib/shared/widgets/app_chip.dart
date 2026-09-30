import 'package:flutter/material.dart';

/// A consistent, reusable chip/badge widget used throughout the app.
///
/// Usage examples:
/// ```dart
/// // Simple label chip
/// AppChip(label: 'Pending', color: Colors.orange)
///
/// // With icon
/// AppChip(label: 'Delivered', color: Colors.green, icon: Icons.check_circle_rounded)
///
/// // Outlined variant
/// AppChip(label: 'Unpaid', color: Colors.red, variant: AppChipVariant.outlined)
/// ```
enum AppChipVariant {
  /// Soft tinted background with colored text (default)
  soft,

  /// Transparent background with a colored border and text
  outlined,

  /// Fully filled background with white text
  filled,
}

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.variant = AppChipVariant.soft,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final AppChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final Color textColor = switch (variant) {
      AppChipVariant.filled => Colors.white,
      _ => color,
    };

    final Color bgColor = switch (variant) {
      AppChipVariant.soft => color.withValues(alpha: 0.12),
      AppChipVariant.outlined => Colors.transparent,
      AppChipVariant.filled => color,
    };

    final Border? border = switch (variant) {
      AppChipVariant.outlined =>
        Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
      _ => null,
    };

    return Container(
      height: 28,
      padding: EdgeInsets.symmetric(
        horizontal: icon != null ? 8 : 10,
        vertical: 0,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pre-built order status chip — picks color, icon, and label automatically.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final String status;

  static Color colorForStatus(String s) => switch (s) {
        'pending' => Colors.orange,
        'extension_requested' => Colors.purple,
        'confirmed' => Colors.blue.shade700,
        'out_for_delivery' => Colors.indigo,
        'delivered' => Colors.green.shade600,
        'rejected' => Colors.red.shade600,
        'cancelled' => Colors.grey.shade600,
        _ => Colors.grey.shade600,
      };

  static IconData iconForStatus(String s) => switch (s) {
        'pending' => Icons.schedule_rounded,
        'extension_requested' => Icons.edit_calendar_rounded,
        'confirmed' => Icons.thumb_up_rounded,
        'out_for_delivery' => Icons.local_shipping_rounded,
        'delivered' => Icons.check_circle_rounded,
        'rejected' => Icons.cancel_rounded,
        'cancelled' => Icons.cancel_rounded,
        _ => Icons.receipt_long_rounded,
      };

  static String labelForStatus(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: labelForStatus(status),
      color: colorForStatus(status),
      icon: iconForStatus(status),
    );
  }
}

/// Pre-built payment status chip.
class PaymentChip extends StatelessWidget {
  const PaymentChip({super.key, required this.paymentStatus, this.paymentProvider});

  final String paymentStatus;
  final String? paymentProvider;

  @override
  Widget build(BuildContext context) {
    final bool isManual = paymentStatus == 'manual_settlement' ||
        paymentProvider == 'manual';
    final bool isPaid = paymentStatus == 'paid';

    if (isPaid && paymentProvider == 'cashfree') {
      return const AppChip(
        label: 'Paid via Cashfree',
        color: Colors.green,
        icon: Icons.verified_rounded,
      );
    } else if (isManual) {
      return const AppChip(
        label: 'Manual settlement',
        color: Colors.teal,
        icon: Icons.handshake_rounded,
      );
    } else if (isPaid) {
      return const AppChip(
        label: 'Paid',
        color: Colors.green,
        icon: Icons.check_circle_rounded,
      );
    } else {
      return const AppChip(
        label: 'Pay on delivery',
        color: Colors.orange,
        icon: Icons.payments_rounded,
      );
    }
  }
}

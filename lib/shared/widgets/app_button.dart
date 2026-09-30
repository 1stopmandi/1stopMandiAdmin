import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum _ButtonVariant { primary, secondary, outlined, text }

/// A unified button component matching the design standards of 1StopMandi.
class AppButton extends StatelessWidget {
  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 48,
    this.borderRadius = 10,
    this.fullWidth = true,
  }) : _variant = _ButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 48,
    this.borderRadius = 10,
    this.fullWidth = true,
  }) : _variant = _ButtonVariant.secondary;

  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 48,
    this.borderRadius = 10,
    this.fullWidth = true,
  }) : _variant = _ButtonVariant.outlined;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 48,
    this.borderRadius = 10,
    this.fullWidth = false,
  }) : _variant = _ButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final bool fullWidth;
  final _ButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    final size = fullWidth ? Size.fromHeight(height) : Size(0, height);

    if (isLoading) {
      return SizedBox(
        height: height,
        width: fullWidth ? double.infinity : null,
        child: FilledButton(
          onPressed: null,
          style: FilledButton.styleFrom(
            shape: shape,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          ),
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    Widget button;

    switch (_variant) {
      case _ButtonVariant.primary:
        if (icon != null) {
          button = FilledButton.icon(
            onPressed: onPressed,
            icon: icon!,
            label: Text(label),
            style: FilledButton.styleFrom(
              minimumSize: size,
              shape: shape,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          );
        } else {
          button = FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              minimumSize: size,
              shape: shape,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            child: Text(label),
          );
        }
        break;

      case _ButtonVariant.secondary:
        if (icon != null) {
          button = FilledButton.tonalIcon(
            onPressed: onPressed,
            icon: icon!,
            label: Text(label),
            style: FilledButton.styleFrom(
              minimumSize: size,
              shape: shape,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          );
        } else {
          button = FilledButton.tonal(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              minimumSize: size,
              shape: shape,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            child: Text(label),
          );
        }
        break;

      case _ButtonVariant.outlined:
        if (icon != null) {
          button = OutlinedButton.icon(
            onPressed: onPressed,
            icon: icon!,
            label: Text(label),
            style: OutlinedButton.styleFrom(
              minimumSize: size,
              shape: shape,
              side: BorderSide(color: Colors.grey.shade300),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          );
        } else {
          button = OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: size,
              shape: shape,
              side: BorderSide(color: Colors.grey.shade300),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            child: Text(label),
          );
        }
        break;

      case _ButtonVariant.text:
        if (icon != null) {
          button = TextButton.icon(
            onPressed: onPressed,
            icon: icon!,
            label: Text(label),
            style: TextButton.styleFrom(
              minimumSize: size,
              shape: shape,
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          );
        } else {
          button = TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              minimumSize: size,
              shape: shape,
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            child: Text(label),
          );
        }
        break;
    }

    return button;
  }
}

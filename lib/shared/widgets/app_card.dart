import 'package:flutter/material.dart';

/// A standard card widget used throughout the app.
///
/// Features:
/// - Clean white surface by default with subtle border and elevation
/// - Built-in ink splash ripple when [onTap] is provided (with a guaranteed
///   [Material] ancestor)
/// - Configurable padding, margin, border, and border radius
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.onTap,
    this.borderRadius = 16,
    this.backgroundColor = Colors.white,
    this.borderColor,
    this.border,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color backgroundColor;
  final Color? borderColor;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = border ??
        Border.all(
          color: borderColor ?? Colors.grey.shade200,
          width: 1,
        );

    final effectiveShadow = boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ];

    final cardRadius = BorderRadius.circular(borderRadius);

    Widget content = Padding(
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: cardRadius,
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: cardRadius,
        border: effectiveBorder,
        boxShadow: effectiveShadow,
      ),
      child: ClipRRect(
        borderRadius: cardRadius,
        child: content,
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// A consistent section header used throughout the app.
/// Shows a colored left-accent dot, a bold label, and an optional trailing widget.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.color,
    this.bottomPadding = 10,
  });

  final String title;
  final Widget? trailing;
  final Color? color;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Carte de surface KANU (fond légèrement plus clair + bordure fine).
class KanuCard extends StatelessWidget {
  const KanuCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.borderColor,
    this.highlight = false,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final bool highlight;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color border = borderColor ?? scheme.outlineVariant;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? scheme.primary.withValues(alpha: 0.45)
              : border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

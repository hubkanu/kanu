import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum KanuButtonVariant { primary, silver, outline, danger, ghost }

/// Bouton KANU unifié, avec état de chargement intégré.
class KanuButton extends StatelessWidget {
  const KanuButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = KanuButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final KanuButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || loading;

    final Widget child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 18),
        if (loading || icon != null) const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final ButtonStyle base = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, height)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24),
      ),
    );

    switch (variant) {
      case KanuButtonVariant.primary:
        return SizedBox(
          width: expand ? double.infinity : null,
          child: FilledButton(
            style: base,
            onPressed: disabled ? null : onPressed,
            child: child,
          ),
        );
      case KanuButtonVariant.danger:
        return SizedBox(
          width: expand ? double.infinity : null,
          child: FilledButton(
            style: base.copyWith(
              backgroundColor: const WidgetStatePropertyAll(AppColors.danger),
              foregroundColor: const WidgetStatePropertyAll(Colors.white),
            ),
            onPressed: disabled ? null : onPressed,
            child: child,
          ),
        );
      case KanuButtonVariant.outline:
        return SizedBox(
          width: expand ? double.infinity : null,
          child: OutlinedButton(
            style: base,
            onPressed: disabled ? null : onPressed,
            child: child,
          ),
        );
      case KanuButtonVariant.silver:
        return SizedBox(
          width: expand ? double.infinity : null,
          child: OutlinedButton(
            style: base.copyWith(
              foregroundColor:
                  const WidgetStatePropertyAll(AppColors.chrome),
              side: WidgetStatePropertyAll(
                BorderSide(color: AppColors.chrome.withValues(alpha: 0.5)),
              ),
            ),
            onPressed: disabled ? null : onPressed,
            child: child,
          ),
        );
      case KanuButtonVariant.ghost:
        return SizedBox(
          width: expand ? double.infinity : null,
          child: TextButton(
            style: base,
            onPressed: disabled ? null : onPressed,
            child: child,
          ),
        );
    }
  }
}

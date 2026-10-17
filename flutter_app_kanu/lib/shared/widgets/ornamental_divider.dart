import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Séparateur ornemental avec un libellé central (utilisé au-dessus des titres).
class OrnamentalDivider extends StatelessWidget {
  const OrnamentalDivider({super.key, this.label, this.width = 220});

  final String? label;
  final double width;

  @override
  Widget build(BuildContext context) {
    final Color line = AppColors.muted.withValues(alpha: 0.35);
    return Column(
      children: [
        if (label != null)
          Text(
            label!.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.red,
                ),
          ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: width * 0.32,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, line],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.diamond_outlined,
                  size: 12, color: AppColors.red),
            ),
            Container(
              width: width * 0.32,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [line, Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

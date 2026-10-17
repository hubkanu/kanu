import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// En-tête de section : surtitre + titre serif + action éventuelle.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.overline,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 12),
  });

  final String title;
  final String? overline;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null) ...[
                  Text(
                    overline!.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.red,
                        ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

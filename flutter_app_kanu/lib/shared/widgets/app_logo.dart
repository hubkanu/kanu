import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Logo KANU : monogramme « K » dans un médaillon cerclé de rouge/or.
class KanuMonogram extends StatelessWidget {
  const KanuMonogram({super.key, this.size = 64, this.glow = false});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.charcoal, AppColors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.red.withValues(alpha: 0.75),
          width: size * 0.02,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.red.withValues(alpha: 0.35),
                  blurRadius: size * 0.5,
                  spreadRadius: size * 0.05,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: ShaderMask(
        shaderCallback: (Rect bounds) =>
            AppColors.silverGradient.createShader(bounds),
        child: Text(
          'K',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: size * 0.52,
            fontWeight: FontWeight.w300,
            height: 1,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Logo complet : médaillon + mot « KANU » avec baseline optionnelle.
class KanuLogo extends StatelessWidget {
  const KanuLogo({
    super.key,
    this.size = 56,
    this.showWordmark = true,
    this.showTagline = false,
    this.glow = false,
    this.axis = Axis.horizontal,
  });

  final double size;
  final bool showWordmark;
  final bool showTagline;
  final bool glow;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final Widget monogram = KanuMonogram(size: size, glow: glow);
    if (!showWordmark) return monogram;

    final List<Widget> column = [
      Text(
        'KANU',
        style: TextStyle(
          fontFamily: 'serif',
          fontSize: size * 0.42,
          letterSpacing: size * 0.09,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      if (showTagline)
        Padding(
          padding: EdgeInsets.only(top: size * 0.08),
          child: Text(
            'Rencontrer moins. Rencontrer mieux.',
            style: TextStyle(
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
              fontSize: size * 0.17,
              color: AppColors.muted,
            ),
          ),
        ),
    ];

    return Flex(
      direction: axis,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        monogram,
        SizedBox(
          width: axis == Axis.horizontal ? size * 0.3 : 0,
          height: axis == Axis.vertical ? size * 0.2 : 0,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: column,
        ),
      ],
    );
  }
}

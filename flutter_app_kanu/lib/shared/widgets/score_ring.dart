import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Anneau de score de compatibilité.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.size = 56,
    this.stroke = 5,
    this.showLabel = true,
  });

  final int score;
  final double size;
  final double stroke;
  final bool showLabel;

  Color get _color {
    if (score >= 90) return AppColors.gold;
    if (score >= 85) return AppColors.red;
    if (score >= 70) return AppColors.rose;
    return AppColors.muted;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: (score.clamp(0, 100)) / 100,
              color: _color,
              track: AppColors.border,
              stroke: stroke,
            ),
          ),
          if (showLabel)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: size * 0.30,
                    fontWeight: FontWeight.w700,
                    color: _color,
                    height: 1,
                  ),
                ),
                Text(
                  '%',
                  style: TextStyle(
                    fontSize: size * 0.16,
                    color: AppColors.muted,
                    height: 1,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - stroke) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

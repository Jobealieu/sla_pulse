import 'dart:math';

import 'package:flutter/material.dart';

import '../../logic/sla.dart';
import '../../theme.dart';

/// Our own chart: a ring split by SLA status with the health score
/// in the middle. Drawn with CustomPainter, so no chart package needed.
class HealthRing extends StatelessWidget {
  const HealthRing({super.key, required this.score, required this.counts, this.size = 132});

  final int score;
  final Map<SlaStatus, int> counts;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Project health $score out of 100, ${healthLabel(score)}',
      excludeSemantics: true,
      // Animates the ring from empty to full whenever it first appears.
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) => SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _RingPainter(
              counts: counts,
              progress: progress,
              track: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(score * progress).round()}',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text('health', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.counts, required this.progress, required this.track});

  final Map<SlaStatus, int> counts;
  final double progress;
  final Color track;

  static const _stroke = 14.0;
  static const _gap = 0.05; // radians between segments

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, 0, 2 * pi, false, paint..color = track);

    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;

    // Start at 12 o'clock and draw one arc per status, sized by its share.
    var start = -pi / 2;
    for (final status in SlaStatus.values) {
      final n = counts[status] ?? 0;
      if (n == 0) continue;
      final sweep = 2 * pi * n / total * progress;
      canvas.drawArc(rect, start + _gap / 2, max(sweep - _gap, 0.001), false, paint..color = slaColor(status));
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || SlaStatus.values.any((s) => old.counts[s] != counts[s]);
}

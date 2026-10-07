import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class HistoryChart extends StatelessWidget {
  const HistoryChart({
    super.key,
    required this.values,
    required this.minY,
    required this.maxY,
    required this.bandLow,
    required this.bandHigh,
    required this.bandLabel,
    required this.xLabels,
    this.color = AppColors.primary,
    this.spikeIndex,
    this.spikeLabel,
  });

  final List<double> values;
  final double minY;
  final double maxY;
  final double bandLow;
  final double bandHigh;
  final String bandLabel;
  final List<String> xLabels;
  final Color color;
  final int? spikeIndex;
  final String? spikeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 96,
            width: double.infinity,
            child: CustomPaint(
              painter: _HistoryPainter(
                values: values,
                minY: minY,
                maxY: maxY,
                bandLow: bandLow,
                bandHigh: bandHigh,
                bandLabel: bandLabel,
                color: color,
                spikeIndex: spikeIndex,
                spikeLabel: spikeLabel,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final l in xLabels)
                Text(
                  l,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter({
    required this.values,
    required this.minY,
    required this.maxY,
    required this.bandLow,
    required this.bandHigh,
    required this.bandLabel,
    required this.color,
    required this.spikeIndex,
    required this.spikeLabel,
  });

  final List<double> values;
  final double minY;
  final double maxY;
  final double bandLow;
  final double bandHigh;
  final String bandLabel;
  final Color color;
  final int? spikeIndex;
  final String? spikeLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    double yOf(double v) {
      final t = ((v - minY) / (maxY - minY)).clamp(0.0, 1.0).toDouble();
      return h - t * h;
    }

    // Safe / comfort band
    final bandTop = yOf(bandHigh);
    final bandBottom = yOf(bandLow);
    canvas.drawRect(
      Rect.fromLTRB(0, bandTop, w, bandBottom),
      Paint()..color = AppColors.border.withValues(alpha: 0.55),
    );
    final dash = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (double x = 0; x < w; x += 6) {
      canvas.drawLine(
        Offset(x, bandTop),
        Offset(math.min(x + 3, w), bandTop),
        dash,
      );
    }

    final label = TextPainter(
      text: TextSpan(
        text: bandLabel,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final ly = (bandTop - label.height - 3).clamp(0.0, h).toDouble();
    label.paint(canvas, Offset(4, ly));

    // Line
    final n = values.length;
    final pts = <Offset>[
      for (var i = 0; i < n; i++) Offset(i / (n - 1) * w, yOf(values[i])),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < n; i++) {
      final prev = pts[i - 1];
      final cur = pts[i];
      final mid = Offset((prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Spike marker + tooltip
    final si = spikeIndex;
    if (si != null && si >= 0 && si < n) {
      final p = pts[si];
      canvas.drawCircle(p, 4, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      final text = spikeLabel;
      if (text != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final pw = tp.width + 12;
        final ph = tp.height + 6;
        final left = (p.dx - pw / 2)
            .clamp(0.0, math.max(0.0, w - pw))
            .toDouble();
        final top = math.max(0.0, p.dy - ph - 8);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, pw, ph),
            const Radius.circular(6),
          ),
          Paint()..color = AppColors.textPrimary,
        );
        tp.paint(canvas, Offset(left + 6, top + 3));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryPainter old) => true;
}

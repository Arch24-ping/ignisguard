import 'package:flutter/material.dart';

import '../data/sensor_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../data/sensor_link.dart';

class TrendCard extends StatefulWidget {
  const TrendCard({super.key, required this.onHistory});
  final VoidCallback onHistory;

  @override
  State<TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<TrendCard> {
  int _selected = 3; // Thursday, as in the design

  @override
  Widget build(BuildContext context) {
    final week = SensorLink.instance.week;
    if (week.isEmpty) return const SizedBox.shrink();
    final day = week[_selected];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '7-Day Environmental Trend',
                        style: AppTheme.heading(size: 20),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Thermal & aerosol stability matrix',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: widget.onHistory,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('History', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) {
                    final step =
                        (w - TrendChartPainter.padX * 2) / (week.length - 1);
                    final i =
                        ((d.localPosition.dx - TrendChartPainter.padX) / step)
                            .round()
                            .clamp(0, week.length - 1)
                            .toInt();
                    setState(() => _selected = i);
                  },
                  child: SizedBox(
                    width: w,
                    height: 180,
                    child: CustomPaint(
                      painter: TrendChartPainter(
                        week: week,
                        selected: _selected,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.day} • ${day.tempF.toStringAsFixed(0)}°F • '
                    '${day.smokePpm.toStringAsFixed(2)} ppm',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      _legend(
                        AppColors.primary,
                        'Ambient Temp (avg '
                        '${SensorLink.instance.avgTemp.toStringAsFixed(1)}°)',
                        dashed: false,
                      ),
                      _legend(
                        AppColors.textSecondary,
                        'Aerosols (avg '
                        '${SensorLink.instance.avgSmoke.toStringAsFixed(2)})',
                        dashed: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label, {required bool dashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: dashed ? 0 : 3,
          decoration: BoxDecoration(
            color: dashed ? null : color,
            border: dashed
                ? Border(top: BorderSide(color: color, width: 1.5))
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class TrendChartPainter extends CustomPainter {
  TrendChartPainter({required this.week, required this.selected});

  final List<DailyReading> week;
  final int selected;

  static const double padX = 14;
  static const double labelH = 24;

  // Temperature scale 45–80 °F, smoke scale 0–0.3 ppm (each fills the height).
  double _yTemp(double v, double h) => h * (0.10 + 0.70 * (1 - (v - 45) / 35));
  double _ySmoke(double v, double h) => h * (0.10 + 0.80 * (1 - v / 0.3));

  Path _smooth(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      final midX = (a.dx + b.dx) / 2;
      p.cubicTo(midX, a.dy, midX, b.dy, b.dx, b.dy);
    }
    return p;
  }

  void _text(
    Canvas canvas,
    String text,
    Offset anchor,
    double size,
    Color color, {
    bool bold = false,
    double factor = 0.5,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(anchor.dx - tp.width * factor, anchor.dy));
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;
    var x = a.dx;
    while (x < b.dx) {
      final end = (x + dash) < b.dx ? x + dash : b.dx;
      canvas.drawLine(Offset(x, a.dy), Offset(end, a.dy), paint);
      x += dash + gap;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height - labelH;
    final step = (size.width - padX * 2) / (week.length - 1);

    final tempPts = [
      for (var i = 0; i < week.length; i++)
        Offset(padX + step * i, _yTemp(week[i].tempF, h)),
    ];
    final smokePts = [
      for (var i = 0; i < week.length; i++)
        Offset(padX + step * i, _ySmoke(week[i].smokePpm, h)),
    ];

    // Panel background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, h),
        const Radius.circular(12),
      ),
      Paint()..color = AppColors.surfaceMuted.withValues(alpha: 0.6),
    );

    // Safe threshold (smoke limit 0.15 ppm)
    final ty = _ySmoke(0.15, h);
    _dashedLine(
      canvas,
      Offset(0, ty),
      Offset(size.width, ty),
      Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );
    _text(
      canvas,
      'SAFE THRESHOLD',
      Offset(size.width - 8, ty - 13),
      8,
      AppColors.textSecondary,
      factor: 1,
    );

    // Temperature area + line
    final linePath = _smooth(tempPts);
    final fill = Path.from(linePath)
      ..lineTo(tempPts.last.dx, h)
      ..lineTo(tempPts.first.dx, h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.28),
            AppColors.primary.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, h)),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Aerosol dashed line
    final smokePaint = Paint()
      ..color = AppColors.textSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final m in _smooth(smokePts).computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), smokePaint);
        d += 9;
      }
    }

    // Selected day marker
    final sp = tempPts[selected];
    canvas.drawLine(
      Offset(sp.dx, 0),
      Offset(sp.dx, h),
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.25)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(sp, 6, Paint()..color = Colors.white);
    canvas.drawCircle(
      sp,
      6,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Day labels
    for (var i = 0; i < week.length; i++) {
      final isSel = i == selected;
      _text(
        canvas,
        week[i].day,
        Offset(tempPts[i].dx, h + 6),
        10,
        isSel ? AppColors.primary : AppColors.textSecondary,
        bold: isSel,
      );
    }
  }

  @override
  bool shouldRepaint(TrendChartPainter old) => old.selected != selected;
}

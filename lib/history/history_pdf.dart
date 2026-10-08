import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/history_data.dart';

final _orange = PdfColor.fromInt(0xFFC8602B);
final _text = PdfColor.fromInt(0xFF2B211B);
final _grey = PdfColor.fromInt(0xFF7A6D63);
final _muted = PdfColor.fromInt(0xFFF3EBE1);
final _band = PdfColor.fromInt(0xFFEADFD2);

String _two(int n) => n.toString().padLeft(2, '0');

pw.TextStyle _style(
  double size, {
  bool bold = false,
  PdfColor? color,
  double? spacing,
}) {
  return pw.TextStyle(
    fontSize: size,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    color: color ?? _text,
    letterSpacing: spacing,
  );
}

pw.Widget _chart(
  List<double> v,
  double minY,
  double maxY,
  double bandLow,
  double bandHigh,
  PdfColor color,
) {
  return pw.CustomPaint(
    size: const PdfPoint(520, 80),
    painter: (PdfGraphics canvas, PdfPoint size) {
      final w = size.x;
      final h = size.y;
      double yOf(double val) =>
          ((val - minY) / (maxY - minY)).clamp(0.0, 1.0).toDouble() * h;

      canvas
        ..setFillColor(_muted)
        ..drawRect(0, 0, w, h)
        ..fillPath()
        ..setFillColor(_band)
        ..drawRect(0, yOf(bandLow), w, yOf(bandHigh) - yOf(bandLow))
        ..fillPath()
        ..setStrokeColor(color)
        ..setLineWidth(1.4)
        ..moveTo(0, yOf(v.first));
      for (var i = 1; i < v.length; i++) {
        canvas.lineTo(i / (v.length - 1) * w, yOf(v[i]));
      }
      canvas.strokePath();
    },
  );
}

pw.Widget _metric({
  required String title,
  required String badge,
  required String big,
  required String sub,
  required pw.Widget chart,
  required List<String> labels,
  required String note,
}) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 16),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(title, style: _style(14, bold: true)),
            pw.Text(badge, style: _style(9, color: _grey)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(big, style: _style(22, bold: true, color: _orange)),
            pw.SizedBox(width: 8),
            pw.Text(sub, style: _style(9, color: _grey)),
          ],
        ),
        pw.SizedBox(height: 6),
        chart,
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: labels
              .map((l) => pw.Text(l, style: _style(8, color: _grey)))
              .toList(),
        ),
        pw.SizedBox(height: 4),
        pw.Text(note, style: _style(9)),
      ],
    ),
  );
}

Future<Uint8List> buildHistoryPdf(HistoryData d) async {
  final doc = pw.Document();
  final now = DateTime.now();
  final stamp =
      '${now.year}-${_two(now.month)}-${_two(now.day)} '
      '${_two(now.hour)}:${_two(now.minute)}';
  final safe = d.safePercent;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => [
        pw.Text(
          'IGNISGUARD',
          style: _style(10, bold: true, color: _orange, spacing: 1.5),
        ),
        pw.SizedBox(height: 4),
        pw.Text('Sensor History & Trends', style: _style(24, bold: true)),
        pw.SizedBox(height: 4),
        pw.Text(
          'Kitchen Detector - Zone 1   |   ${d.pastLabel}   |   '
          'Generated $stamp',
          style: _style(9, color: _grey),
        ),
        pw.SizedBox(height: 14),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _muted,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                safe >= 95 ? 'Everything is Safe' : 'Minor Activity Detected',
                style: _style(13, bold: true),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'All sensors were within normal levels $safe% of the past '
                '${d.periodWord}.',
                style: _style(10, color: _grey),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 18),
        _metric(
          title: 'Smoke & Air Quality',
          badge: 'Safe & Clear',
          big: '${d.smoke.avg.toStringAsFixed(2)} ppm',
          sub: 'average. Normal is under 0.15 ppm',
          chart: _chart(d.smoke.values, 0, 0.45, 0, 0.15, _orange),
          labels: d.xLabels,
          note: d.hasEvent
              ? 'No hazardous fire smoke detected. Only 1 brief cooking '
                    'spike was recorded and cleared safely.'
              : 'No smoke detected. Air quality stayed clear the whole '
                    'period.',
        ),
        _metric(
          title: 'Room Temperature',
          badge: 'Comfortable',
          big: '${d.temp.avg.round()} F',
          sub:
              'average. Ranged between ${d.temp.min.round()} F and '
              '${d.temp.max.round()} F',
          chart: _chart(
            d.temp.values,
            60,
            85,
            68,
            78,
            PdfColor.fromInt(0xFFE0894F),
          ),
          labels: d.xLabels,
          note: 'Stable indoor climate. No sudden dangerous heat spikes.',
        ),
        _metric(
          title: 'Humidity Levels',
          badge: 'Optimal',
          big: '${d.humidity.avg.round()}%',
          sub: 'average. Ideal range is 30% - 50%',
          chart: _chart(d.humidity.values, 20, 70, 30, 50, _grey),
          labels: d.xLabels,
          note: 'Healthy moisture balance helps prevent false alarms.',
        ),
        pw.Text(
          '${d.eventsTitle} (${d.hasEvent ? 1 : 0})',
          style: _style(14, bold: true),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          d.hasEvent
              ? 'Cooking Steam / Searing - Thu Oct 24, 10:24 AM, Kitchen - '
                    'Harmless. Cleared automatically after 6 minutes.'
              : 'No events recorded in this period.',
          style: _style(10),
        ),
        pw.SizedBox(height: 18),
        pw.Text(
          'Kitchen Sensor is working perfectly. Battery 94%, signal strong '
          '(Wi-Fi).',
          style: _style(10, bold: true),
        ),
        pw.SizedBox(height: 18),
        pw.Text(
          'Prototype report. Values are simulated sample data, not live '
          'sensor readings.',
          style: _style(8, color: _grey),
        ),
      ],
    ),
  );

  return doc.save();
}

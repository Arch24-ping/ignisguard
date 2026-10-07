import 'dart:math' as math;

import 'package:flutter/material.dart';

enum HistoryPeriod { day, week, month, custom }

class HistorySeries {
  const HistorySeries(this.values);
  final List<double> values;

  double get avg => values.reduce((a, b) => a + b) / values.length;
  double get min => values.reduce(math.min);
  double get max => values.reduce(math.max);
}

class HistoryData {
  const HistoryData({
    required this.period,
    required this.pastLabel,
    required this.periodWord,
    required this.eventsTitle,
    required this.xLabels,
    required this.smoke,
    required this.temp,
    required this.humidity,
    required this.spikeIndex,
  });

  final HistoryPeriod period;
  final String pastLabel; // "Past 30 Days"
  final String periodWord; // "month"
  final String eventsTitle; // "Events this Month"
  final List<String> xLabels;
  final HistorySeries smoke;
  final HistorySeries temp;
  final HistorySeries humidity;
  final int? spikeIndex;

  bool get hasEvent => spikeIndex != null;

  /// Share of readings with smoke under the 0.15 ppm safe limit.
  int get safePercent {
    final safe = smoke.values.where((v) => v < 0.15).length;
    return (safe / smoke.values.length * 100).round();
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _fmt(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  static HistoryData build(HistoryPeriod period, {DateTimeRange? range}) {
    int days;
    int perDay;
    String past;
    String word;
    String eventsTitle;
    List<String> labels;

    if (period == HistoryPeriod.day) {
      days = 1;
      perDay = 48;
      past = 'Past 24 Hours';
      word = '24 hours';
      eventsTitle = 'Events Today';
      labels = const ['12 AM', '6 AM', '12 PM', '6 PM', 'Now'];
    } else if (period == HistoryPeriod.week) {
      days = 7;
      perDay = 12;
      past = 'Past 7 Days';
      word = 'week';
      eventsTitle = 'Events this Week';
      labels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    } else if (period == HistoryPeriod.month) {
      days = 30;
      perDay = 4;
      past = 'Past 30 Days';
      word = 'month';
      eventsTitle = 'Events this Month';
      labels = const ['Oct 1', 'Week 1', 'Week 2', 'Week 3', 'Oct 30'];
    } else {
      final now = DateTime.now();
      final r =
          range ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 13)),
            end: now,
          );
      days = (r.end.difference(r.start).inDays + 1).clamp(1, 90).toInt();
      perDay = days <= 2 ? 24 : (days <= 14 ? 8 : 4);
      past = '${_fmt(r.start)} – ${_fmt(r.end)}';
      word = 'selected period';
      eventsTitle = 'Events in this Period';
      final mid = r.start.add(Duration(days: days ~/ 2));
      labels = [_fmt(r.start), _fmt(mid), _fmt(r.end)];
    }

    final n = math.max(24, days * perDay);

    int? spike;
    if (period == HistoryPeriod.month ||
        (period == HistoryPeriod.custom && days >= 14)) {
      spike = (n * 0.8).round();
    } else if (period == HistoryPeriod.week) {
      spike = ((n - 1) * 0.5).round();
    }

    final rng = math.Random(days * 31 + period.index);

    final smoke = List<double>.generate(n, (i) {
      var v =
          0.02 + 0.005 * math.sin(i * 0.7) + (rng.nextDouble() - 0.5) * 0.006;
      if (spike != null) {
        final d = (i - spike).toDouble();
        v += 0.30 * math.exp(-(d * d) / (2 * 0.6 * 0.6));
      }
      return v < 0.004 ? 0.004 : v;
    });

    final temp = List<double>.generate(n, (i) {
      return 72 +
          3.2 * math.sin(2 * math.pi * i / perDay) +
          (rng.nextDouble() - 0.5) * 1.2;
    });

    final humidity = List<double>.generate(n, (i) {
      return 44 +
          1.0 * math.sin(2 * math.pi * i / perDay + 1) +
          (rng.nextDouble() - 0.5) * 0.8;
    });

    return HistoryData(
      period: period,
      pastLabel: past,
      periodWord: word,
      eventsTitle: eventsTitle,
      xLabels: labels,
      smoke: HistorySeries(smoke),
      temp: HistorySeries(temp),
      humidity: HistorySeries(humidity),
      spikeIndex: spike,
    );
  }
}

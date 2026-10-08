import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'history_pdf.dart';
import '../data/history_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_header.dart';
import 'history_chart.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryPeriod _period = HistoryPeriod.month;
  DateTimeRange? _range;
  HistoryData _data = HistoryData.build(HistoryPeriod.month);
  String get _viewLabel => switch (_period) {
    HistoryPeriod.day => '24-hour',
    HistoryPeriod.week => '7-day',
    HistoryPeriod.month => '30-day',
    HistoryPeriod.custom => 'custom-range',
  };
  Future<void> _select(HistoryPeriod p) async {
    if (p == HistoryPeriod.custom) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 1),
        lastDate: now,
        initialDateRange: _range,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _range = picked;
        _period = p;
        _data = HistoryData.build(p, range: picked);
      });
      return;
    }
    setState(() {
      _period = p;
      _data = HistoryData.build(p);
    });
  }

  bool _saving = false;
  Future<void> _savePdf() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final bytes = await buildHistoryPdf(_data);
      await Printing.sharePdf(bytes: bytes, filename: 'ignisguard-summary.pdf');
    } catch (e, st) {
      debugPrint('PDF export failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create the PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final safe = d.safePercent;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(title: 'Home'),
              const SizedBox(height: 12),
              _topBar(),
              const SizedBox(height: 16),
              Text(
                'Sensor History & Trends',
                style: AppTheme.heading(size: 28),
              ),
              const SizedBox(height: 6),
              Text(
                'Clear $_viewLabel view of your home\'s air and safety '
                'conditions.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _safeBanner(safe),
              const SizedBox(height: 16),
              _tabs(),
              const SizedBox(height: 16),
              _metricCard(
                icon: Icons.cloud_outlined,
                title: 'Smoke & Air Quality',
                badge: d.smoke.max >= 0.15 ? 'Spike recorded' : 'Safe & Clear',
                big: d.smoke.avg.toStringAsFixed(2),
                unit: 'ppm avg',
                detail: '• Normal is under 0.15 ppm',
                chart: HistoryChart(
                  values: d.smoke.values,
                  minY: 0,
                  maxY: 0.45,
                  bandLow: 0,
                  bandHigh: 0.15,
                  bandLabel: 'Normal safe range (under 0.15)',
                  xLabels: d.xLabels,
                  spikeIndex: d.spikeIndex,
                  spikeLabel: d.hasEvent
                      ? 'Simulated spike (${d.eventDay})'
                      : null,
                ),
                note: d.hasEvent
                    ? 'One simulated smoke spike is shown to demonstrate how '
                          'events appear.'
                    : 'No smoke detected in this period.',
              ),
              const SizedBox(height: 14),
              _metricCard(
                icon: Icons.thermostat,
                title: 'Room Temperature',
                badge: (d.temp.min >= 68 && d.temp.max <= 78)
                    ? 'Comfortable'
                    : 'Outside comfort zone',
                big: '${d.temp.avg.round()}°F',
                unit: 'average',
                detail:
                    '• Ranged between ${d.temp.min.round()}°F and ${d.temp.max.round()}°F',
                chart: HistoryChart(
                  values: d.temp.values,
                  minY: 60,
                  maxY: 85,
                  bandLow: 68,
                  bandHigh: 78,
                  bandLabel: 'Comfort zone (68°F – 78°F)',
                  xLabels: d.xLabels,
                  color: const Color(0xFFE0894F),
                ),
                note: d.temp.max < 120
                    ? 'Temperature stayed well below the 120°F alert level.'
                    : 'Temperature reached the alert level.',
              ),
              const SizedBox(height: 14),
              _metricCard(
                icon: Icons.water_drop_outlined,
                title: 'Humidity Levels',
                badge: (d.humidity.avg >= 30 && d.humidity.avg <= 50)
                    ? 'Optimal'
                    : 'Outside range',
                big: '${d.humidity.avg.round()}%',
                unit: 'average',
                detail: '• Ideal range is 30% - 50%',
                chart: HistoryChart(
                  values: d.humidity.values,
                  minY: 20,
                  maxY: 70,
                  bandLow: 30,
                  bandHigh: 50,
                  bandLabel: 'Ideal range (30% – 50%)',
                  xLabels: d.xLabels,
                  color: AppColors.textSecondary,
                ),
                note: 'Healthy moisture balance helps prevent false alarms.',
              ),
              const SizedBox(height: 22),
              _eventsSection(),
              const SizedBox(height: 14),
              _sensorHealthCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.of(context).pop(),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 16, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Demo sensor  •  simulated data',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: _savePdf,
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_outlined, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _safeBanner(int safe) {
    final ok = safe >= 95;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ok ? Icons.verified_user_outlined : Icons.info_outline,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok ? 'Everything is Safe' : 'Minor Activity Detected',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All sensors were within normal levels $safe% of the past '
                  '${_data.periodWord}.',
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    const items = [
      (HistoryPeriod.day, '24 Hours'),
      (HistoryPeriod.week, '7 Days'),
      (HistoryPeriod.month, '30 Days'),
      (HistoryPeriod.custom, 'Custom'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (final (p, label) in items)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _select(p),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _period == p
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _period == p
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String badge,
    required String big,
    required String unit,
    required String detail,
    required Widget chart,
    required String note,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: AppTheme.heading(size: 20))),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _data.pastLabel,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            children: [
              Text(big, style: AppTheme.heading(size: 30)),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '$unit  $detail',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          chart,
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note,
                    style: const TextStyle(fontSize: 11, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventsSection() {
    final d = _data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${d.eventsTitle} (${d.hasEvent ? 1 : 0})',
              style: AppTheme.heading(size: 20),
            ),
            const Text(
              'All Resolved',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (!d.hasEvent)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'No events recorded in this period.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.soup_kitchen_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Simulated smoke spike',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'd.eventWhen ??',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Demo',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Example event for demonstration. Real events appear here'
                    'once a sensor reports them.',
                    style: TextStyle(fontSize: 11, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _sensorHealthCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demo mode: no sensor connected',
                  style: AppTheme.heading(size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Battery and Signal: not reported (no sensor connected)',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          const Text(
            'Readings on this screen are simulated for demonstration. Real'
            'diagnostics appear here once a sensor is pair',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _saving ? null : _savePdf,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Save Summary (PDF)'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../data/profile_store.dart';
import '../data/sensor_data.dart';
import '../data/sensor_link.dart';
import '../history/history_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'sprinkler_card.dart';
import 'trend_card.dart';
import '../data/temp_format.dart';
import 'sprinkler_control.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenEducation});
  final VoidCallback onOpenEducation;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _sensor = SensorData.sensors.first;

  Widget _liveDevice(SensorLink link) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              link.deviceZone.isEmpty
                  ? link.deviceName
                  : '${link.deviceName} • ${link.deviceZone}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smokeCard(SensorReading r) {
    final level = r.smokeLevel;
    if (level != null) {
      final high = level == 'High';
      final elevated = level == 'Elevated';
      return _MetricCard(
        label: 'Smoke',
        icon: Icons.cloud_outlined,
        value: level,
        unit: '',
        valueSize: 18,
        accent: high
            ? AppColors.critical
            : (elevated ? AppColors.primary : null),
        caption: high
            ? 'Smoke detected'
            : (elevated ? 'Elevated' : 'Level reported by sensor'),
      );
    }
    final ppm = r.smokePpm ?? 0;
    final over = ppm >= SensorLink.smokeLimit;
    return _MetricCard(
      label: 'Smoke',
      icon: Icons.cloud_outlined,
      value: ppm.toStringAsFixed(2),
      unit: 'ppm',
      accent: over ? AppColors.critical : null,
      caption: over ? 'Elevated (≥ 0.15)' : 'Normal (< 0.15)',
    );
  }

  Widget _historyPending() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Trends and history build up as your sensor keeps reporting. '
        'Charts arrive in a later update.',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }

  void _comingLater(String what) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(what)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: SensorLink.instance,
        builder: (context, _) {
          final link = SensorLink.instance;
          final r = link.reading;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 16),
                if (r == null)
                  _noSensorCard(link)
                else ...[
                  _sourceBanner(link),
                  const SizedBox(height: 12),
                  link.isDemo ? _sensorSelector() : _liveDevice(link),
                  const SizedBox(height: 14),
                  _statusBanner(link, r),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Temp',
                          icon: Icons.thermostat,
                          value: toC(r.tempF).toStringAsFixed(0),
                          accent: r.tempF >= SensorLink.tempLimitF
                              ? AppColors.critical
                              : null,
                          unit: '°C',
                          caption: link.isDemo
                              ? '${r.tempF >= SensorLink.tempLimitF ? 'High' : 'Normal'}'
                                    ' • Avg ${toC(link.avgTemp).toStringAsFixed(0)}°C'
                              : (r.tempF >= SensorLink.tempLimitF
                                    ? 'High'
                                    : 'Normal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _smokeCard(r)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          label: 'Humidity',
                          icon: Icons.water_drop_outlined,
                          value: r.humidity.toStringAsFixed(0),
                          unit: '%',
                          caption: (r.humidity >= 40 && r.humidity <= 50)
                              ? 'Optimal 40–50%'
                              : 'Outside 40–50%',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (link.isDemo) ...[
                    TrendCard(
                      onHistory: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HistoryScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const SprinklerCard(),
                  ] else ...[
                     SprinklerControl(),
                    const SizedBox(height: 14),
                    _historyPending(),
                  ],
                  const SizedBox(height: 14),
                  _spatialView(link),
                ],
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: widget.onOpenEducation,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Read in Education Hub',
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 1.4),
          ),
          child: const Icon(
            Icons.local_fire_department_outlined,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'IGNISGUARD',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.primary,
              ),
            ),
            Text('Home', style: AppTheme.heading(size: 22)),
          ],
        ),
      ],
    );
  }

  Widget _noSensorCard(SensorLink link) {
    if (link.isPaired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${link.deviceName} is paired. Waiting for its first reading.',
          style: const TextStyle(fontSize: 13),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.sensors_off_outlined,
            size: 34,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text('No sensor connected', style: AppTheme.heading(size: 22)),
          const SizedBox(height: 6),
          const Text(
            'Live temperature, smoke and humidity readings appear here once '
            'an IgnisGuard sensor is paired. Until then you can explore the '
            'app with simulated data.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: link.startDemo,
              child: const Text('Try demo mode'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceBanner(SensorLink link) {
    final live = link.isLive;
    final text = live
        ? (link.isOnline
              ? 'LIVE • Updated ${_ago(link.lastSeen)}'
              : 'OFFLINE • Last seen ${_ago(link.lastSeen)}')
        : 'DEMO DATA • Simulated readings, no sensor connected';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            live
                ? (link.isOnline ? Icons.sensors : Icons.sensors_off)
                : Icons.science_outlined,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          if (!live)
            TextButton(
              onPressed: link.stopDemo,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('Exit', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _sensorSelector() {
    return Row(
      children: [
        Expanded(
          child: PopupMenuButton<String>(
            onSelected: (v) => setState(() => _sensor = v),
            itemBuilder: (_) => [
              for (final s in SensorData.sensors)
                PopupMenuItem(value: s, child: Text(s)),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sensors_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _sensor,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _comingLater('Sensor filters arrive with live data'),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.tune, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBanner(SensorLink link, SensorReading r) {
    final health = r.health;
    final alarm = link.isAlarm;
    final warn = link.isWarning;
    final offline = link.isLive && !link.isOnline;

    final bg = alarm
        ? AppColors.criticalSoft
        : warn
        ? AppColors.primary.withValues(alpha: 0.12)
        : AppColors.surfaceMuted;
    final titleColor = alarm
        ? AppColors.critical
        : (offline ? AppColors.textSecondary : AppColors.textPrimary);
    final iconColor = alarm
        ? AppColors.critical
        : (offline ? AppColors.textSecondary : AppColors.primary);
    final icon = alarm
        ? Icons.local_fire_department
        : warn
        ? Icons.warning_amber_rounded
        : offline
        ? Icons.sensors_off
        : Icons.check_circle_outline;

    final subtitle = link.isDemo
        ? 'Based on simulated demo readings.'
        : offline
        ? 'Last report ${_ago(link.lastSeen)}. The readings below may be out of date.'
        : 'From your sensor, updated ${_ago(link.lastSeen)}.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: alarm
            ? Border.all(color: AppColors.critical, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.statusTitle,
                  style: AppTheme.heading(size: 20, color: titleColor),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (health != null) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: health / 100,
                      strokeWidth: 5,
                      color: AppColors.primary,
                      backgroundColor: AppColors.border,
                    ),
                  ),
                  Text(
                    '$health%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _spatialView(SensorLink link) {
    final location = ProfileStore.instance.location;
    return Container(
      height: 130,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEBD9C4), Color(0xFFB98B66)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SPATIAL VIEW',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            link.isLive ? link.deviceName : _sensor,
            style: AppTheme.heading(size: 20, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            link.isLive
                ? (link.deviceZone.isEmpty ? location : link.deviceZone)
                : (location.isEmpty ? 'Demo sensor' : location),
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.unit,
    required this.caption,
    this.valueSize = 28,
    this.accent,
  });

  final String label;
  final IconData icon;
  final String value;
  final String unit;
  final String caption;
  final double valueSize;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Icon(icon, size: 16, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: accent == null
                      ? AppTheme.heading(size: valueSize)
                      : AppTheme.heading(size: valueSize, color: accent!),
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              style: TextStyle(
                fontSize: 9,
                color: accent ?? AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _ago(DateTime? t) {
  if (t == null) return 'unknown';
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 90) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

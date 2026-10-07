import 'package:flutter/material.dart';

import '../history/history_screen.dart';
import '../data/sensor_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'sprinkler_card.dart';
import 'trend_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenEducation});
  final VoidCallback onOpenEducation;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _sensor = SensorData.sensors.first;

  void _comingLater(String what) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(what)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 16),
            _sensorSelector(),
            const SizedBox(height: 14),
            _statusBanner(),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Temp',
                    icon: Icons.thermostat,
                    value: SensorData.tempF.toStringAsFixed(0),
                    unit: '°F',
                    caption:
                        'Normal • Avg '
                        '${SensorData.avgTemp.toStringAsFixed(0)}°',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'Smoke',
                    icon: Icons.cloud_outlined,
                    value: SensorData.smokePpm.toStringAsFixed(2),
                    unit: 'ppm',
                    caption: 'Normal (< 0.15)',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'Humidity',
                    icon: Icons.water_drop_outlined,
                    value: '${SensorData.humidity}',
                    unit: '%',
                    caption: 'Optimal 40–50%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            
            TrendCard(
              onHistory: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
            ),
            const SizedBox(height: 14),
            const SprinklerCard(),
            const SizedBox(height: 14),
            _spatialView(),
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

  Widget _statusBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No thermal anomalies detected',
                  style: AppTheme.heading(size: 20),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Dual-optic optical sensor running at optimum calibration.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: SensorData.health / 100,
                    strokeWidth: 5,
                    color: AppColors.primary,
                    backgroundColor: AppColors.border,
                  ),
                ),
                Text(
                  '${SensorData.health}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _spatialView() {
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
            'Kitchen Area • West Loft',
            style: AppTheme.heading(size: 20, color: Colors.white),
          ),
          const SizedBox(height: 2),
          const Text(
            'Connected to Zone A Main Supply',
            style: TextStyle(fontSize: 11, color: Colors.white),
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
  });

  final String label;
  final IconData icon;
  final String value;
  final String unit;
  final String caption;

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
                Text(value, style: AppTheme.heading(size: 28)),
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
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

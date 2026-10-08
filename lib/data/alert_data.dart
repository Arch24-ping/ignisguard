import 'package:flutter/material.dart';

enum AlertSeverity { critical, warning, system }

class AlertItem {
  AlertItem({
    required this.severity,
    required this.title,
    required this.message,
    required this.time,
    required this.tag,
    required this.trailing,
    required this.icon,
    this.actionRequired = false,
  });

  final AlertSeverity severity;
  final String title;
  final String message;
  final String time;
  final String tag;
  final String trailing;
  final IconData icon;
  bool actionRequired;
}

class AlertData {
  AlertData._();

  static String _clock(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  /// Demo alerts only. The screen shows these only while demo mode is on.
  /// Returns a fresh list each time so the screen can change it.
  static List<AlertItem> initial() {
    final now = DateTime.now();
    String ago(int minutes) =>
        _clock(now.subtract(Duration(minutes: minutes)));

    return [
      AlertItem(
        severity: AlertSeverity.critical,
        title: 'Smoke detected — Kitchen',
        message: '0.48 ppm smoke threshold exceeded (Safe max: 0.15 ppm)',
        time: ago(14),
        tag: 'Smoke Critical',
        trailing: 'Telemetry',
        icon: Icons.cloud_outlined,
        actionRequired: true,
      ),
      AlertItem(
        severity: AlertSeverity.warning,
        title: 'Rapid Temp Rise (+8°F in 2m)',
        message: 'Kitchen ambient thermal gradient spike',
        time: ago(16),
        tag: 'Thermal Warning',
        trailing: 'Kitchen',
        icon: Icons.thermostat,
      ),
      AlertItem(
        severity: AlertSeverity.warning,
        title: 'High Humidity (Steam) — Kitchen',
        message: 'Humidity reached 68% while cooking, within steam tolerance',
        time: ago(34),
        tag: 'Humidity Warning',
        trailing: 'Kitchen',
        icon: Icons.water_drop_outlined,
      ),
      AlertItem(
        severity: AlertSeverity.system,
        title: 'Sprinkler Self-Test Completed',
        message: 'Example of a routine diagnostic entry',
        time: ago(95),
        tag: 'Routine Diagnostic',
        trailing: 'Simulated',
        icon: Icons.shower_outlined,
      ),
      AlertItem(
        severity: AlertSeverity.system,
        title: 'Air Quality Normalized — Living Room',
        message: 'PM2.5 returned to optimal baseline (12 µg/m³)',
        time: 'Yest. ${_clock(now.subtract(const Duration(hours: 20)))}',
        tag: 'Auto-Resolved',
        trailing: 'Duration: 18m',
        icon: Icons.air,
      ),
    ];
  }
}
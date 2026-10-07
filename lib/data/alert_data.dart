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

  /// Returns a fresh list each time so the screen can change it.
  static List<AlertItem> initial() => [
    AlertItem(
      severity: AlertSeverity.critical,
      title: 'Smoke detected — Kitchen',
      message: '0.48 ppm smoke threshold exceeded (Safe max: 0.15 ppm)',
      time: '10:24 AM',
      tag: 'Smoke Critical',
      trailing: 'Telemetry',
      icon: Icons.cloud_outlined,
      actionRequired: true,
    ),
    AlertItem(
      severity: AlertSeverity.warning,
      title: 'Rapid Temp Rise (+8°F in 2m)',
      message: 'Kitchen North Zone ambient thermal gradient spike',
      time: '10:22 AM',
      tag: 'Thermal Warning',
      trailing: 'Zone 1 Cooktop',
      icon: Icons.thermostat,
    ),
    AlertItem(
      severity: AlertSeverity.warning,
      title: 'High Humidity (Steam) — Kitchen',
      message: 'Humidity reached 68% while cooking, within steam tolerance',
      time: '10:05 AM',
      tag: 'Humidity Warning',
      trailing: 'Zone 1 Kitchen',
      icon: Icons.water_drop_outlined,
    ),
    AlertItem(
      severity: AlertSeverity.system,
      title: 'Sprinkler Self-Test Completed',
      message: 'All 6 micro-valves reported nominal backpressure',
      time: '08:30 AM',
      tag: 'Routine Diagnostic',
      trailing: 'System Verified',
      icon: Icons.shower_outlined,
    ),
    AlertItem(
      severity: AlertSeverity.system,
      title: 'Air Quality Normalized — Living Room',
      message: 'PM2.5 returned to optimal baseline (12 µg/m³)',
      time: 'Yest. 6:15 PM',
      tag: 'Auto-Resolved',
      trailing: 'Duration: 18m',
      icon: Icons.air,
    ),
  ];
}

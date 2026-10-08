import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sensor_data.dart';

enum SensorMode { none, demo }

class SensorReading {
  const SensorReading({
    required this.tempF,
    required this.smokePpm,
    required this.humidity,
    required this.health,
    required this.at,
    this.batteryPercent,
    this.rssiDbm,
  });

  final double tempF;
  final double smokePpm;
  final double humidity;
  final int health;
  final DateTime at;

  /// null means the sensor did not report it. Never invent these.
  final int? batteryPercent;
  final int? rssiDbm;
}

class SensorLink extends ChangeNotifier {
  SensorLink._();
  static final SensorLink instance = SensorLink._();

  static const _modeKey = 'sensor_mode';
  static const double smokeLimit = 0.15;
  static const double tempLimitF = 120;

  SensorMode _mode = SensorMode.none;
  SensorReading? _reading;
  Timer? _timer;
  final _rng = math.Random();

  SensorMode get mode => _mode;
  bool get isDemo => _mode == SensorMode.demo;
  bool get hasSensor => _reading != null;
  SensorReading? get reading => _reading;

  /// Week history. Only demo mode has any for now.
  List<DailyReading> get week =>
      isDemo ? SensorData.week : const <DailyReading>[];
  double get avgTemp => SensorData.avgTemp;
  double get avgSmoke => SensorData.avgSmoke;

  String get statusTitle {
    final r = _reading;
    if (r == null) return 'No sensor connected';
    if (r.smokePpm >= smokeLimit) return 'Smoke level elevated';
    if (r.tempF >= tempLimitF) return 'High temperature detected';
    return 'No anomalies detected';
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString(_modeKey) == 'demo') _beginDemo();
  }

  Future<void> startDemo() async {
    _beginDemo();
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_modeKey, 'demo');
  }

  Future<void> stopDemo() async {
    _timer?.cancel();
    _timer = null;
    _mode = SensorMode.none;
    _reading = null;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.remove(_modeKey);
  }

  void _beginDemo() {
    _mode = SensorMode.demo;
    _reading = _sample();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _reading = _sample();
      notifyListeners();
    });
  }

  SensorReading _sample() => SensorReading(
    tempF: 72 + (_rng.nextDouble() - 0.5) * 3,
    smokePpm: 0.02 + (_rng.nextDouble() - 0.5) * 0.008,
    humidity: 44 + (_rng.nextDouble() - 0.5) * 4,
    health: 98,
    at: DateTime.now(),
  );
}

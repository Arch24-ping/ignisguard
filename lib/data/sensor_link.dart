import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sensor_data.dart';

enum SensorMode { none, demo, live }

class SensorReading {
  const SensorReading({
    required this.tempF,
    required this.humidity,
    required this.at,
    this.smokePpm,
    this.smokeLevel,
    this.health,
    this.batteryPercent,
    this.rssiDbm,
  });

  final double tempF;
  final double humidity;
  final DateTime at;

  /// Demo only. A real MQ-type sensor cannot report a trustworthy ppm.
  final double? smokePpm;

  /// Live only: "Low", "Elevated" or "High", decided by the sensor.
  final String? smokeLevel;

  /// null means the sensor did not report it. Never invent these.
  final int? health;
  final int? batteryPercent;
  final int? rssiDbm;
}

class SensorLink extends ChangeNotifier {
  SensorLink._();
  static final SensorLink instance = SensorLink._();

  static const _modeKey = 'sensor_mode';
  static const double smokeLimit = 0.15;
  static const double tempLimitF = 131;
  static const Duration offlineAfter = Duration(minutes: 3);

  // Demo
  bool _demoOn = false;
  SensorReading? _demoReading;
  Timer? _timer;
  final _rng = math.Random();

  // Live (a real sensor owned by the signed-in account)
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _liveSub;
  Timer? _staleTimer;
  String? _deviceId;
  String _deviceName = '';
  String _deviceZone = '';
  String _deviceStatus = 'ok';
  DateTime? _lastSeen;
  SensorReading? _liveReading;

  bool get isPaired => _deviceId != null;
  SensorMode get mode =>
      isPaired ? SensorMode.live : (_demoOn ? SensorMode.demo : SensorMode.none);
  bool get isLive => mode == SensorMode.live;
  bool get isDemo => mode == SensorMode.demo;
  SensorReading? get reading =>
      isLive ? _liveReading : (_demoOn ? _demoReading : null);
  bool get hasSensor => reading != null;

  String get deviceName => _deviceName;
  String get deviceZone => _deviceZone;
  String? get deviceId => _deviceId;
  bool get isAlarm => isLive && isOnline && _deviceStatus == 'alarm';
  bool get isWarning => isLive && isOnline && _deviceStatus == 'warning';
  DateTime? get lastSeen => _lastSeen ?? _liveReading?.at;
  bool get isOnline {
    final t = lastSeen;
    return t != null && DateTime.now().difference(t) < offlineAfter;
  }

  /// Week history. Only demo mode has any for now.
  List<DailyReading> get week =>
      isDemo ? SensorData.week : const <DailyReading>[];
  double get avgTemp => SensorData.avgTemp;
  double get avgSmoke => SensorData.avgSmoke;

  String get statusTitle {
    final r = reading;
    if (r == null) return 'No sensor connected';
    if (isLive) {
      if (!isOnline) return 'Sensor offline';
      return switch (_deviceStatus) {
        'alarm' => 'Alarm: hazard detected',
        'warning' => 'Warning: elevated readings',
        _ => 'No anomalies detected',
      };
    }
    final p = r.smokePpm;
    if (p != null && p >= smokeLimit) return 'Smoke level elevated';
    if (r.tempF >= tempLimitF) return 'High temperature detected';
    return 'No anomalies detected';
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString(_modeKey) == 'demo') _beginDemo();
  }

  // ---------- Live ----------

  void attachLive(String uid) {
    _liveSub?.cancel();
    _liveSub = FirebaseFirestore.instance
        .collection('devices')
        .where('ownerUid', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .listen(
          _onDevices,
          onError: (Object e) => debugPrint('Live sensor listener failed: $e'),
        );
    _staleTimer?.cancel();
    _staleTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isPaired) notifyListeners();
    });
  }

  void detachLive() {
    _liveSub?.cancel();
    _liveSub = null;
    _staleTimer?.cancel();
    _staleTimer = null;
    _clearDevice();
    notifyListeners();
  }

  void _clearDevice() {
    _deviceId = null;
    _deviceName = '';
    _deviceZone = '';
    _deviceStatus = 'ok';
    _lastSeen = null;
    _liveReading = null;
  }

  void _onDevices(QuerySnapshot<Map<String, dynamic>> snap) {
    try {
      if (snap.docs.isEmpty) {
        _clearDevice();
      } else {
        final doc = snap.docs.first;
        final d = doc.data();
        _deviceId = doc.id;
        _deviceName = (d['name'] ?? 'IgnisGuard Sensor') as String;
        _deviceZone = (d['zone'] ?? '') as String;
        _deviceStatus = (d['status'] ?? 'ok') as String;
        _lastSeen = _time(d['lastSeen']);
        _liveReading = _parse(d['latest']);
      }
    } catch (e) {
      debugPrint('Bad device document: $e');
    }
    notifyListeners();
  }

  DateTime? _time(Object? v) => v is Timestamp ? v.toDate() : null;

  SensorReading? _parse(Object? raw) {
    if (raw is! Map) return null;
    double? n(String k) {
      final v = raw[k];
      return v is num ? v.toDouble() : null;
    }

    final tempC = n('tempC');
    final hum = n('humidity');
    final at = _time(raw['ts']);
    if (tempC == null || hum == null || at == null) return null;
    final level = raw['smokeLevel'];
    return SensorReading(
      tempF: tempC * 9 / 5 + 32,
      humidity: hum,
      at: at,
      smokeLevel: level is String ? level : null,
      rssiDbm: n('rssi')?.round(),
    );
  }

  // ---------- Demo ----------

  Future<void> startDemo() async {
    _beginDemo();
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_modeKey, 'demo');
  }

  Future<void> stopDemo() async {
    _timer?.cancel();
    _timer = null;
    _demoOn = false;
    _demoReading = null;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.remove(_modeKey);
  }

  void _beginDemo() {
    _demoOn = true;
    _demoReading = _sample();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _demoReading = _sample();
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
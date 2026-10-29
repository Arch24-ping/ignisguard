import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SimMode { normal, warning, alarm, offline }

class _Vals {
  const _Vals(
    this.tempC,
    this.humidity,
    this.smokeRaw,
    this.smokeLevel,
    this.flame,
    this.status,
  );
  final double tempC;
  final double humidity;
  final int smokeRaw;
  final String smokeLevel;
  final bool flame;
  final String status;
}

const _vals = <SimMode, _Vals>{
  SimMode.normal: _Vals(24.5, 45, 300, 'Low', false, 'ok'),
  SimMode.warning: _Vals(40, 42, 1800, 'Elevated', false, 'warning'),
  SimMode.alarm: _Vals(55, 38, 3200, 'High', true, 'alarm'),
  SimMode.offline: _Vals(24.5, 45, 300, 'Low', false, 'ok'),
};

/// A virtual sensor that runs inside the app for accounts whose device
/// document is marked simulated. It stands in for the ESP32 and writes the
/// same fields to the same Firestore document.
class SimSensor extends ChangeNotifier with WidgetsBindingObserver {
  SimSensor._();
  static final SimSensor instance = SimSensor._();

  static const _fw = 'sim-app-0.1';
  final _rng = math.Random();

  String? _id;
  SimMode _mode = SimMode.normal;
  Timer? _timer;
  bool _foreground = true;
  bool _dirty = true;
  bool _acking = false;
  DateTime _lastPush = DateTime.fromMillisecondsSinceEpoch(0);

  bool _pumpOn = false;
  bool _manual = false;
  DateTime? _pumpUntil;
  DateTime? _alarmSince;
  DateTime? _pausedUntil;

  SimMode get mode => _mode;
  bool get running => _id != null;

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('devices').doc(_id!);

  // ---------- creation (called once when setup completes) ----------

  static Future<bool> createFor({
    String name = 'Kitchen Detector',
    String zone = 'Kitchen',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final v = _vals[SimMode.normal]!;
    final now = Timestamp.now();
    try {
      final existing = await FirebaseFirestore.instance
        .collection('devices')
        .where('ownerUid', isEqualTo: user.uid)
        .limit(1)
        .get();
      if (existing.docs.isNotEmpty) return false;
      await FirebaseFirestore.instance.collection('devices').doc(user.uid).set({
        'ownerUid': user.uid,
        'name': name,
        'zone': zone,
        'status': v.status,
        'fw': _fw,
        'pumpOn': false,
        'pumpCmd': 'idle',
        'simulated': true,
        'lastSeen': now,
        'latest': {
          'tempC': v.tempC,
          'humidity': v.humidity,
          'smokeRaw': v.smokeRaw,
          'smokeLevel': v.smokeLevel,
          'flame': v.flame,
          'rssi': -60,
          'ts': now,
        },
      });
      return true;
    } catch (e) {
      debugPrint('Could not create simulated sensor: $e');
      return false;
    }
  }

  // ---------- lifecycle, driven by SensorLink ----------

  Future<void> attach(String id, String? cmd) async {
    if (_id != id) {
      _id = id;
      _pumpOn = false;
      _manual = false;
      _pumpUntil = null;
      _alarmSince = null;
      _pausedUntil = null;
      _dirty = true;
      try {
        final p = await SharedPreferences.getInstance();
        final saved = p.getString('sim_mode_$id');
        _mode = SimMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => SimMode.normal,
        );
      } catch (_) {
        _mode = SimMode.normal;
      }
      WidgetsBinding.instance.addObserver(this);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      notifyListeners();
    }
    _onCommand(cmd);
  }

  void detach() {
    if (_id == null) return;
    _timer?.cancel();
    _timer = null;
    _id = null;
    WidgetsBinding.instance.removeObserver(this);
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _dirty = true;
  }

  // ---------- user control ----------

  Future<void> setMode(SimMode m) async {
    if (_id == null || m == _mode) return;
    final prev = _mode;
    _mode = m;
    _dirty = true;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('sim_mode_$_id', m.name);
    } catch (_) {}
    switch (m) {
      case SimMode.alarm:
        _alert('critical', 'Fire alert', 'Flame and high smoke detected.');
      case SimMode.warning:
        _alert(
          'warning',
          'Elevated readings',
          'Temperature and smoke are above normal.',
        );
      case SimMode.normal:
        if (prev != SimMode.normal) {
          _alert('system', 'Back to normal', 'Readings are back to normal.');
        }
      case SimMode.offline:
        _pumpOn = false;
        _manual = false;
        _pumpUntil = null;
        _markStale();
    }
    notifyListeners();
  }

  // ---------- engine ----------

  void _tick() {
    if (_id == null || !_foreground) return;
    if (_mode == SimMode.offline) return;
    final now = DateTime.now();
    _runPump(now);
    if (_dirty || now.difference(_lastPush) >= const Duration(seconds: 15)) {
      _push(now);
    }
  }

  void _runPump(DateTime now) {
    if (_pumpOn && _pumpUntil != null && now.isAfter(_pumpUntil!)) {
      _setPump(
        false,
        _manual
            ? 'Manual run ended at the 30 second limit.'
            : 'Automatic run ended.',
      );
      _manual = false;
    }
    if (_mode == SimMode.alarm) {
      _alarmSince ??= now;
      final confirmed =
          now.difference(_alarmSince!) >= const Duration(seconds: 3);
      final paused = _pausedUntil != null && now.isBefore(_pausedUntil!);
      if (confirmed && !_pumpOn && !paused) {
        _manual = false;
        _pumpUntil = now.add(const Duration(seconds: 10));
        _setPump(true, 'Started automatically: fire confirmed.');
      }
    } else {
      _alarmSince = null;
      if (_pumpOn && !_manual) _setPump(false, 'Fire no longer detected.');
    }
  }

  void _setPump(bool on, String why) {
    _pumpOn = on;
    _dirty = true;
    _alert('system', on ? 'Sprinkler started' : 'Sprinkler stopped', why);
    notifyListeners();
  }

  void _onCommand(String? cmd) {
    if (cmd != 'on' && cmd != 'off') return;
    if (_acking) return;
    _acking = true;
    final now = DateTime.now();
    if (_mode != SimMode.offline) {
      if (cmd == 'on') {
        _manual = true;
        _pumpUntil = now.add(const Duration(seconds: 30));
        if (!_pumpOn) _setPump(true, 'Started manually from the app.');
      } else {
        _pausedUntil = now.add(const Duration(seconds: 30));
        if (_pumpOn) _setPump(false, 'Stopped manually from the app.');
      }
    }
    _ack();
  }

  Future<void> _ack() async {
    try {
      await _doc.update({'pumpCmd': 'idle'});
    } catch (e) {
      debugPrint('Could not reset pumpCmd: $e');
    } finally {
      _acking = false;
    }
  }

  Future<void> _push(DateTime now) async {
    _lastPush = now;
    _dirty = false;
    final v = _vals[_mode]!;
    final ts = Timestamp.fromDate(now);
    final temp = double.parse(
      (v.tempC + (_rng.nextDouble() - 0.5) * 0.6).toStringAsFixed(1),
    );
    final hum = (v.humidity + (_rng.nextDouble() - 0.5) * 2).round();
    try {
      await _doc.update({
        'status': v.status,
        'lastSeen': ts,
        'fw': _fw,
        'pumpOn': _pumpOn,
        'latest': {
          'tempC': temp,
          'humidity': hum,
          'smokeRaw': v.smokeRaw,
          'smokeLevel': v.smokeLevel,
          'flame': v.flame,
          'rssi': -60,
          'ts': ts,
        },
      });
    } catch (e) {
      debugPrint('Simulated sensor push failed: $e');
    }
  }

  Future<void> _markStale() async {
    try {
      await _doc.update({
        'pumpOn': false,
        'lastSeen': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      });
    } catch (e) {
      debugPrint('Could not mark sensor offline: $e');
    }
  }

  Future<void> _alert(String severity, String title, String message) async {
    try {
      await _doc.collection('alerts').add({
        'severity': severity,
        'title': title,
        'message': message,
        'ts': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Could not post alert: $e');
    }
  }
}

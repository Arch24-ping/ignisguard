import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Sensitivity { high, standard, low }

class Contact {
  const Contact({
    required this.name,
    required this.relation,
    required this.phone,
  });

  final String name;
  final String relation;
  final String phone;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'relation': relation,
    'phone': phone,
  };

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
    name: (j['name'] ?? '') as String,
    relation: (j['relation'] ?? '') as String,
    phone: (j['phone'] ?? '') as String,
  );
}

class DeviceInfo {
  const DeviceInfo({
    required this.name,
    required this.icon,
    required this.battery,
    this.online = true,
  });

  final String name;
  final IconData icon;
  final int battery;
  final bool online;

  // Icons are stored by index into this list. Never store raw code points:
  // non-constant IconData breaks release builds (icon tree-shaking).
  static const List<IconData> knownIcons = [
    Icons.sensors_rounded,
    Icons.dns_outlined,
  ];

  Map<String, dynamic> toJson() {
    final i = knownIcons.indexOf(icon);
    return {
      'name': name,
      'icon': i < 0 ? 0 : i,
      'battery': battery,
      'online': online,
    };
  }

  factory DeviceInfo.fromJson(Map<String, dynamic> j) {
    final i = (j['icon'] ?? 0) as int;
    return DeviceInfo(
      name: (j['name'] ?? '') as String,
      icon: knownIcons[i >= 0 && i < knownIcons.length ? i : 0],
      battery: (j['battery'] ?? 100) as int,
      online: (j['online'] ?? true) as bool,
    );
  }
}

class SettingsStore extends ChangeNotifier {
  SettingsStore._();
  static final SettingsStore instance = SettingsStore._();

  SharedPreferences? _prefs;

  Sensitivity _sensitivity = Sensitivity.standard;
  bool _thermalAlert = true;
  bool _push = true;
  bool _soundBypass = true;
  bool _sms = true;

  final List<Contact> _contacts = [
    const Contact(
      name: 'Sarah Jenkins',
      relation: 'Spouse',
      phone: '+263 700 000 000',
    ),
    const Contact(
      name: 'Michael Jenkins',
      relation: 'Son',
      phone: '+263 777 777 777',
    ),
  ];

  final List<DeviceInfo> _devices = [
    const DeviceInfo(
      name: 'Kitchen Smoke Detector #01',
      icon: Icons.sensors_rounded,
      battery: 94,
    ),
    const DeviceInfo(
      name: 'Server Room Detector',
      icon: Icons.dns_outlined,
      battery: 88,
    ),
  ];

  Sensitivity get sensitivity => _sensitivity;
  bool get thermalAlert => _thermalAlert;
  bool get push => _push;
  bool get soundBypass => _soundBypass;
  bool get sms => _sms;
  List<Contact> get contacts => List.unmodifiable(_contacts);
  List<DeviceInfo> get devices => List.unmodifiable(_devices);

  /// Call once in main() before runApp. Missing or corrupt data falls back
  /// to the defaults above.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    final s = prefs.getInt('sensitivity');
    if (s != null && s >= 0 && s < Sensitivity.values.length) {
      _sensitivity = Sensitivity.values[s];
    }
    _thermalAlert = prefs.getBool('thermalAlert') ?? _thermalAlert;
    _push = prefs.getBool('push') ?? _push;
    _soundBypass = prefs.getBool('soundBypass') ?? _soundBypass;
    _sms = prefs.getBool('sms') ?? _sms;

    final c = prefs.getString('contacts');
    if (c != null) {
      try {
        final list = (jsonDecode(c) as List)
            .map((e) => Contact.fromJson(e as Map<String, dynamic>))
            .toList();
        _contacts
          ..clear()
          ..addAll(list);
      } catch (_) {
        // keep defaults
      }
    }

    final d = prefs.getString('devices');
    if (d != null) {
      try {
        final list = (jsonDecode(d) as List)
            .map((e) => DeviceInfo.fromJson(e as Map<String, dynamic>))
            .toList();
        _devices
          ..clear()
          ..addAll(list);
      } catch (_) {
        // keep defaults
      }
    }
  }

  void _save() {
    final p = _prefs;
    if (p == null) return;
    p.setInt('sensitivity', _sensitivity.index);
    p.setBool('thermalAlert', _thermalAlert);
    p.setBool('push', _push);
    p.setBool('soundBypass', _soundBypass);
    p.setBool('sms', _sms);
    p.setString(
      'contacts',
      jsonEncode(_contacts.map((c) => c.toJson()).toList()),
    );
    p.setString(
      'devices',
      jsonEncode(_devices.map((d) => d.toJson()).toList()),
    );
  }

  void _changed() {
    _save();
    notifyListeners();
  }

  void setSensitivity(Sensitivity v) {
    _sensitivity = v;
    _changed();
  }

  void setThermalAlert(bool v) {
    _thermalAlert = v;
    _changed();
  }

  void setPush(bool v) {
    _push = v;
    _changed();
  }

  void setSoundBypass(bool v) {
    _soundBypass = v;
    _changed();
  }

  void setSms(bool v) {
    _sms = v;
    _changed();
  }

  void addContact(Contact c) {
    _contacts.add(c);
    _changed();
  }

  void insertContact(int index, Contact c) {
    _contacts.insert(index.clamp(0, _contacts.length).toInt(), c);
    _changed();
  }

  void updateContact(int index, Contact c) {
    _contacts[index] = c;
    _changed();
  }

  void removeContact(int index) {
    _contacts.removeAt(index);
    _changed();
  }

  void addDevice(DeviceInfo d) {
    _devices.add(d);
    _changed();
  }

  void removeDevice(int index) {
    _devices.removeAt(index);
    _changed();
  }
}

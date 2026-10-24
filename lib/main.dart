import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/profile_store.dart';
import 'data/sensor_link.dart';
import 'data/settings_store.dart';
import 'firebase_options.dart';
import 'splash/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Boot());
}

/// Runs the startup steps, then hands over to the real app.
/// If a step stalls or throws, the screen says which one.
class _Boot extends StatefulWidget {
  const _Boot();

  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  String _step = 'Starting';
  Object? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _do(String name, Future<void> Function() job) async {
    if (mounted) setState(() => _step = name);
    await job().timeout(const Duration(seconds: 20));
  }

  Future<void> _run() async {
    setState(() {
      _error = null;
      _ready = false;
    });
    try {
      await _do('Firebase', () async {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      });
      await _do('Screen orientation', () async {
        await SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitUp]);
      });
      await _do('Settings', () => SettingsStore.instance.load());
      await _do('Profile', () => ProfileStore.instance.load());
      await _do('Sensor link', () => SensorLink.instance.load());
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const IgnisGuardApp();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error == null) const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  _error == null
                      ? 'Starting: $_step'
                      : 'Startup failed at: $_step\n\n$_error',
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _run, child: const Text('Retry')),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IgnisGuardApp extends StatelessWidget {
  const IgnisGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IgnisGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/settings_store.dart';
import 'theme/app_theme.dart';
import 'splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SettingsStore.instance.load();
  runApp(const IgnisGuardApp());
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

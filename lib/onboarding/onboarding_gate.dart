import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/profile_store.dart';
import '../shell/main_shell.dart';
import 'onboarding_flow.dart';
import 'profile_screen.dart';

const kOnboardingDoneKey = 'onboarding_done';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late bool _hasProfile = ProfileStore.instance.hasProfile;
  late final Future<bool> _onboardingDone = _loadDone();

  Future<bool> _loadDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kOnboardingDoneKey) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasProfile) {
      return ProfileScreen(onSaved: () => setState(() => _hasProfile = true));
    }
    return FutureBuilder<bool>(
      future: _onboardingDone,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snap.data! ? const MainShell() : const OnboardingFlow();
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../data/cloud_store.dart';
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

  @override
  Widget build(BuildContext context) {
    if (!_hasProfile) {
      return ProfileScreen(onSaved: () => setState(() => _hasProfile = true));
    }
    return CloudStore.instance.onboardingDone
        ? const MainShell()
        : const OnboardingFlow();
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shell/main_shell.dart';
import '../theme/app_colors.dart';
import 'onboarding_flow.dart';

const kOnboardingDoneKey = 'onboarding_done';

/// Shows onboarding only on first launch, otherwise goes straight to the app.
class OnboardingGate extends StatelessWidget {
  const OnboardingGate({super.key});

  Future<bool> _isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kOnboardingDoneKey) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isDone(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(backgroundColor: AppColors.background);
        }
        return snap.data! ? const MainShell() : const OnboardingFlow();
      },
    );
  }
}

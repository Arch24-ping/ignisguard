import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/cloud_store.dart';

import '../onboarding/onboarding_gate.dart';
import 'auth_screen.dart';
import 'auth_service.dart';

/// Signed out -> sign-in screen. Signed in -> the existing onboarding gate.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.changes,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) return const AuthScreen();
        // Keyed by uid so a different account never inherits old screen state.
        return KeyedSubtree(
          key: ValueKey(user.uid),
          child: _CloudLoader(uid: user.uid),
        );
      },
    );
  }
}
class _CloudLoader extends StatefulWidget {
  const _CloudLoader({required this.uid});
  final String uid;

  @override
  State<_CloudLoader> createState() => _CloudLoaderState();
}

class _CloudLoaderState extends State<_CloudLoader> {
  late Future<void> _load = CloudStore.instance.attach(widget.uid);

  void _retry() =>
      setState(() => _load = CloudStore.instance.attach(widget.uid));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _load,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Could not load your account data. '
                      'Check your internet connection.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('Try again'),
                    ),
                    TextButton(
                      onPressed: AuthService.instance.signOut,
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const OnboardingGate();
      },
    );
  }
}
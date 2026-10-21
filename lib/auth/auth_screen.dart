import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _validEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

  Future<void> _submit() async {
    final email = _email.text;
    final pw = _password.text;
    if (!_validEmail(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (pw.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (_signUp && pw != _confirm.text) {
      setState(() => _error = 'The two passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_signUp) {
        await AuthService.instance.signUp(email, pw);
      } else {
        await AuthService.instance.signIn(email, pw);
      }
      // AuthGate swaps this screen out by itself on success.
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    if (!_validEmail(_email.text)) {
      setState(() => _error = 'Type your email above, then tap Forgot password.');
      return;
    }
    try {
      await AuthService.instance.resetPassword(_email.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If an account exists for that email, a reset link has been sent.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.message(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                _signUp ? 'Create your account' : 'Welcome back',
                textAlign: TextAlign.center,
                style: AppTheme.heading(size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                _signUp
                    ? 'Your setup and contacts are saved to your account.'
                    : 'Sign in to continue to IgnisGuard.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                obscureText: _hide,
                textInputAction:
                    _signUp ? TextInputAction.next : TextInputAction.done,
                onSubmitted: (_) => _signUp ? null : _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
              ),
              if (_signUp) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _confirm,
                  obscureText: _hide,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_signUp ? 'Create account' : 'Sign in'),
              ),
              if (!_signUp)
                TextButton(
                  onPressed: _busy ? null : _forgot,
                  child: const Text('Forgot password?'),
                ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _signUp = !_signUp;
                          _error = null;
                        }),
                child: Text(
                  _signUp
                      ? 'Already have an account? Sign in'
                      : 'New here? Create an account',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
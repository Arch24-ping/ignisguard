import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'onboarding_widgets.dart';
import 'wifi_scanner.dart';

class _Net {
  const _Net(
    this.name,
    this.note, {
    this.secured = true,
    this.hidden = false,
    this.enterprise = false,
  });
  final String name;
  final String note;
  final bool secured;
  final bool hidden;
  final bool enterprise;
}

class WifiStep extends StatefulWidget {
  const WifiStep({super.key, required this.onContinue});
  final void Function(String network) onContinue;

  @override
  State<WifiStep> createState() => _WifiStepState();
}

class _WifiStepState extends State<WifiStep> {
  List<_Net> _scanned = [];
  final List<_Net> _manual = [];
  String? _selected;
  String? _problem;
  bool _scanning = false;
  bool _obscure = true;
  bool _connecting = false;
  final _password = TextEditingController();
  final _hidden = TextEditingController();

  /// Manually entered networks first, then scan results without duplicates.
  List<_Net> get _all {
    final names = _manual.map((n) => n.name).toSet();
    return [..._manual, ..._scanned.where((n) => !names.contains(n.name))];
  }

  _Net? get _current {
    for (final n in _all) {
      if (n.name == _selected) return n;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _scan();
  }

  @override
  void dispose() {
    _password.dispose();
    _hidden.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _problem = null;
    });

    final result = await WifiScanner.scan();
    if (!mounted) return;

    final nets = <_Net>[];
    for (var i = 0; i < result.networks.length; i++) {
      final n = result.networks[i];
      final label = n.enterprise
          ? 'School/work network • not supported'
          : (i == 0 && n.level >= -67)
          ? 'Recommended • ${n.signalLabel}'
          : n.signalLabel;
      nets.add(
        _Net(n.ssid, label, secured: n.secured, enterprise: n.enterprise),
      );
    }

    setState(() {
      _scanning = false;
      _problem = result.problem;
      _scanned = nets;
      if (_current == null) {
        final usable = _all.where((n) => !n.enterprise).toList();
        _selected = usable.isEmpty ? null : usable.first.name;
      }
    });
  }

  void _select(String name) {
    if (_selected != name) _password.clear();
    setState(() => _selected = name);
  }

  Future<void> _addHidden() async {
    _hidden.clear();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hidden network'),
        content: TextField(
          controller: _hidden,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Network name (SSID)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _hidden.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    setState(() {
      _manual.removeWhere((n) => n.name == name);
      _manual.insert(0, _Net(name, 'Entered manually', hidden: true));
      _password.clear();
      _selected = name;
    });
  }

  //true = joined with that password, false = refect/timed out,
  //null = this phone could not run the check.
  Future<bool?> _verify(_Net net) async {
    try {
      final ok = await WiFiForIoTPlugin.connect(
        net.name,
        password: _password.text,
        security: NetworkSecurity.WPA,
        joinOnce: true,
        isHidden: net.hidden,
        timeoutInSeconds: 25,
      );
      debugPrint('VERIFY result for ${net.name}: $ok');
      if (ok) await WiFiForIoTPlugin.disconnect();
      return ok;
    } catch (e) {
      debugPrint('VERIFY error: $e');
      return null;
    }
  }

  Future<void> _connect() async {
    final net = _current;
    if (net == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a Wi-Fi network first')),
      );
      return;
    }

    if (net.enterprise) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Networks that need a username (school or work WiFi) are not supported. Choose your home WiFi or a phone hotspot.',
          ),
        ),
      );
      return;
    }

    debugPrint(
      'CONNECT tapped: "${net.name}" secured=${net.secured}'
      'hidden=${net.hidden} pwLen=${_password.text.length}',
    );
    if (net.secured) {
      final pw = _password.text;
      if (pw.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter the Wi-Fi password to continue')),
        );
        return;
      }
      final isHexKey = RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(pw);
      if (pw.length < 8 || (pw.length > 63 && !isHexKey)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wi-Fi passwords are 8 to 63 characters long'),
          ),
        );
        return;
      }
    }
    setState(() => _connecting = true);

    if (net.secured) {
      final ok = await _verify(net);
      if (!mounted) return;
      if (ok == false) {
        setState(() => _connecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not join "${net.name}". Check the password and try again.',
            ),
          ),
        );
        return;
      }
      if (ok == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This phone could not verify the password, continuing without it.',
            ),
          ),
        );
      }
    }

    //Pairing the sensor itself is still simulated (no hardware yet).
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _connecting = false);
    widget.onContinue(net.name);
  }

  Widget _networkTile(_Net n) {
    final selected = n.name == _selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _select(n.name),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.wifi_rounded,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            n.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (n.secured) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.lock_outline,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n.note,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : AppColors.border,
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _problemCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$_problem\nYou can still add your network with '
              '"Connect to Hidden Network" below.',
              style: const TextStyle(fontSize: 11, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final networks = _all;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          const OnboardingHeader(step: 1),
          const SizedBox(height: 20),
          const SensorBeacon(),
          const SizedBox(height: 8),
          const BeaconPill(label: 'Beacon ID: IG-982-S • Ready to Pair'),
          const SizedBox(height: 20),
          Text('Connect to Wi-Fi', style: AppTheme.heading(size: 30)),
          const SizedBox(height: 8),
          const Text(
            'Connect your IgnisGuard sensor to your 2.4 GHz home Wi-Fi '
            'network so it can send instant fire alerts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'SELECT HOME NETWORK',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (_scanning)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _scan,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Scan again',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_scanning && networks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text(
                          'Scanning for networks...',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  for (final n in networks) _networkTile(n),
                  if (!_scanning && _problem != null) _problemCard(),
                  Center(
                    child: TextButton(
                      onPressed: _addHidden,
                      child: const Text(
                        '+ Connect to Hidden Network...',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password for ${_current?.name ?? 'your network'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'Wi-Fi password',
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'IgnisGuard hardware operates on high-reliability '
                          'WPA2/WPA3 encrypted mesh protocols.',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _connecting ? null : _connect,
            child: _connecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Connect Sensor & Continue'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Need help finding your network?',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

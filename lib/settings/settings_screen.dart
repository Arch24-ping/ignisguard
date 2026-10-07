import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/settings_store.dart';
import '../onboarding/onboarding_flow.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_header.dart';
import 'contact_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _store = SettingsStore.instance;
  bool _testingSiren = false;

  void _snack(String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
  }

  Future<void> _testSiren() async {
    if (_testingSiren) return;
    setState(() => _testingSiren = true);
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    _snack('Test siren tone playing (3 sec)');
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _testingSiren = false);
  }

  Future<void> _editContact({int? index}) async {
    final existing = index == null ? null : _store.contacts[index];
    final result = await showDialog<Contact>(
      context: context,
      builder: (_) => ContactDialog(initial: existing),
    );
    if (result == null) return;
    if (index == null) {
      _store.addContact(result);
      _snack('${result.name} added as an emergency contact');
    } else {
      _store.updateContact(index, result);
    }
  }

  void _removeContact(int index) {
    final removed = _store.contacts[index];
    _store.removeContact(index);
    _snack(
      '${removed.name} removed',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => _store.insertContact(index, removed),
      ),
    );
  }

  void _showDevice(int index) {
    final d = _store.devices[index];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d.name, style: AppTheme.heading(size: 22)),
            const SizedBox(height: 14),
            _kv('Status', d.online ? 'Online' : 'Offline'),
            _kv('Battery', '${d.battery}%'),
            _kv('Model', 'IG-930 All-in-One Detector'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _store.removeDevice(index);
                _snack('${d.name} removed');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.critical,
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.critical),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Remove device'),
            ),
          ],
        ),
      ),
    );
  }

  void _pairNew() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnboardingFlow(
          onFinished: (nickname) {
            _store.addDevice(
              DeviceInfo(
                name: nickname,
                icon: Icons.sensors_rounded,
                battery: 100,
              ),
            );
            Navigator.of(context).pop();
            _snack('$nickname paired');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: _store,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(title: 'Settings'),
              const SizedBox(height: 18),
              Text('Settings & Preferences', style: AppTheme.heading(size: 28)),
              const SizedBox(height: 6),
              const Text(
                'Hardware sensitivity thresholds, emergency dispatch '
                'circles, and critical siren alerts.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              _sectionHeader(
                Icons.tune,
                'Sensor Sensitivity',
                'OPTICS & THERMAL',
              ),
              const SizedBox(height: 10),
              _sensitivityCard(),
              const SizedBox(height: 22),
              _sectionHeader(
                Icons.notifications_none_rounded,
                'Siren & Notifications',
                'OVERRIDE PROTOCOLS',
              ),
              const SizedBox(height: 10),
              _notificationsCard(),
              const SizedBox(height: 22),
              _sectionHeader(
                Icons.contact_phone_outlined,
                'Emergency Contacts & Dispatch',
                '${_store.contacts.length} Active',
                tagColor: AppColors.primary,
              ),
              const SizedBox(height: 10),
              _contactsCard(),
              const SizedBox(height: 22),
              _sectionHeader(
                Icons.sensors_rounded,
                'Registered Devices',
                'HARDWARE',
              ),
              const SizedBox(height: 10),
              _devicesCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
    IconData icon,
    String title,
    String tag, {
    Color tagColor = AppColors.textSecondary,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: AppTheme.heading(size: 20))),
        Text(
          tag,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: tagColor,
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            k,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            v,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ---------- Sensor sensitivity ----------

  String get _sensitivityText {
    switch (_store.sensitivity) {
      case Sensitivity.high:
        return 'High: alerts at the earliest trace of smoke. Expect more '
            'false alarms near cooking.';
      case Sensitivity.standard:
        return 'Dynamic baseline: Standard mode tolerates moderate cooking '
            'vapor and steam bursts while detecting true hydrocarbon '
            'combustion immediately.';
      case Sensitivity.low:
        return 'Low (Cooking): raises the smoke threshold while you cook to '
            'reduce nuisance alarms. Flame and rapid-heat detection stay '
            'fully active.';
    }
  }

  Widget _segment(Sensitivity s, String label) {
    final selected = _store.sensitivity == s;
    return Expanded(
      child: GestureDetector(
        onTap: () => _store.setSensitivity(s),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sensitivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PRIMARY DETECTOR',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kitchen Smoke Sensitivity',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _segment(Sensitivity.high, 'High'),
                  _segment(Sensitivity.standard, 'Standard'),
                  _segment(Sensitivity.low, 'Low (Cooking)'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _sensitivityText,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Divider(height: 28, color: AppColors.border),
            _toggleRow(
              icon: Icons.thermostat,
              title: 'Thermal Gradient Alert',
              subtitle: 'Triggers on rapid spike (+8°F in ≤ 2 min)',
              value: _store.thermalAlert,
              onChanged: _store.setThermalAlert,
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Siren & notifications ----------

  Widget _toggleRow({
    IconData? icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? badge,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (badge != null) ...[const SizedBox(width: 8), badge],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.border,
          ),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ],
    );
  }

  Widget _notificationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _toggleRow(
              title: 'Push Notifications',
              subtitle: 'Real-time status changes and air quality warnings',
              value: _store.push,
              onChanged: _store.setPush,
            ),
            const SizedBox(height: 16),
            _toggleRow(
              title: 'Critical Sound Bypass',
              subtitle:
                  "Overrides 'Do Not Disturb' and silent mode with "
                  'full decibel alarm during confirmed smoke hazard.',
              value: _store.soundBypass,
              onChanged: _store.setSoundBypass,
              badge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.criticalSoft,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'LIFE-SAFETY',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: AppColors.critical,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _toggleRow(
              title: 'SMS Emergency Broadcast',
              subtitle: 'Instant text dispatch to registered family phones',
              value: _store.sms,
              onChanged: _store.setSms,
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _testSiren,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.volume_up_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _testingSiren
                          ? 'Sounding...'
                          : 'Test Phone Siren Tone (3-Sec Burst)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Emergency contacts ----------

  Widget _contactsCard() {
    final contacts = _store.contacts;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (contacts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'No emergency contacts yet. Add someone who should be '
                  'alerted if you do not respond.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            for (var i = 0; i < contacts.length; i++) _contactTile(i),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _editContact(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Add Emergency Contact',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactTile(int i) {
    final c = _store.contacts[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Text(
              c.initials,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
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
                        c.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        c.relation,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  c.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: i == 0
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.border,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Priority ${i + 1}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: i == 0 ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (v) {
              if (v == 'edit') _editContact(index: i);
              if (v == 'remove') _removeContact(i);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'remove', child: Text('Remove')),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Registered devices ----------

  Widget _devicesCard() {
    final devices = _store.devices;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < devices.length; i++) _deviceTile(i),
            const SizedBox(height: 2),
            ElevatedButton.icon(
              onPressed: _pairNew,
              icon: const Icon(Icons.add_link, size: 18),
              label: const Text('Pair New IgnisGuard Sensor'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deviceTile(int i) {
    final d = _store.devices[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDevice(i),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(d.icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.heading(size: 16),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: d.online
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          d.online ? 'Online' : 'Offline',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.battery_5_bar,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${d.battery}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

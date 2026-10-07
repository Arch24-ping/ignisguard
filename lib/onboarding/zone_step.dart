import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'onboarding_widgets.dart';

class _Zone {
  const _Zone(this.name, this.icon);
  final String name;
  final IconData icon;
}

class ZoneStep extends StatefulWidget {
  const ZoneStep({
    super.key,
    required this.wifiName,
    required this.onChangeWifi,
    required this.onConfirm,
  });

  final String wifiName;
  final VoidCallback onChangeWifi;
  final void Function(String zone, String nickname) onConfirm;

  @override
  State<ZoneStep> createState() => _ZoneStepState();
}

class _ZoneStepState extends State<ZoneStep> {
  static const _zones = [
    _Zone('Kitchen', Icons.countertops_outlined),
    _Zone('Living Room', Icons.weekend_outlined),
    _Zone('Server Room', Icons.dns_outlined),
    _Zone('Garage', Icons.garage_outlined),
    _Zone('Master Bedroom', Icons.bed_outlined),
    _Zone('Custom Room', Icons.add),
  ];

  String _zone = 'Kitchen';
  bool _nicknameEdited = false;
  final _nickname = TextEditingController(
    text: 'Main Kitchen Smoke Sensor #01',
  );

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  void _pickZone(String zone) {
    setState(() {
      _zone = zone;
      if (!_nicknameEdited) {
        _nickname.text = 'Main $zone Smoke Sensor #01';
      }
    });
  }

  Widget _zoneChip(_Zone z) {
    final selected = z.name == _zone;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _pickZone(z.name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              z.icon,
              size: 15,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              z.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingHeader(step: 2),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Wi-Fi Connected: ${widget.wifiName}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onChangeWifi,
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: SensorBeacon()),
          const SizedBox(height: 8),
          const Center(child: BeaconPill()),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where is this sensor placed?',
                    style: AppTheme.heading(size: 24),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Assign a room so emergency fire and smoke alerts '
                    'specify the exact danger zone immediately.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TARGET ZONE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Preset selected',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _zones.map(_zoneChip).toList(),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DEVICE NICKNAME',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'editable anytime',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nickname,
                    onChanged: (_) => _nicknameEdited = true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _nickname.clear(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tune,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Automatic Algorithm Tuning',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _zone == 'Kitchen'
                                    ? 'Standard Kitchen (Steam Tolerant, '
                                          'High Smoke Detection)'
                                    : 'Standard $_zone profile',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final name = _nickname.text.trim();
              widget.onConfirm(
                _zone,
                name.isEmpty ? 'Main $_zone Smoke Sensor #01' : name,
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Confirm & Continue'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () =>
                  widget.onConfirm('Kitchen', 'Main Kitchen Smoke Sensor #01'),
              child: const Text(
                'Skip to default room',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

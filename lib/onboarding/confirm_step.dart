import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'onboarding_widgets.dart';

class ConfirmStep extends StatelessWidget {
  const ConfirmStep({
    super.key,
    required this.zone,
    required this.nickname,
    required this.onEnter,
  });

  final String zone;
  final String nickname;
  final VoidCallback onEnter;

  Widget _feature(IconData icon, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _row(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          const OnboardingHeader(step: 3),
          const SizedBox(height: 24),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  size: 52,
                  color: Colors.white,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'HARDWARE PAIRED & SYNCHRONIZED • ${zone.toUpperCase()} DETECTOR #01',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'All Sensors Online & Verified',
            textAlign: TextAlign.center,
            style: AppTheme.heading(size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            'Your all-in-one IgnisGuard smart detector is fully calibrated '
            'and actively safeguarding against fire and smoke in the $zone.',
            textAlign: TextAlign.center,
            style: const TextStyle(
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
                      const Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'IgnisGuard All-in-One Detector',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Model IG-930 • $zone Unit #01',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Integrated multi-hazard protection combining flame '
                    'flicker (IR/UV), dual-optic smoke detection, thermal '
                    'gradient monitoring, and ambient humidity tracking.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _feature(
                        Icons.local_fire_department_outlined,
                        'Flame & Optical',
                      ),
                      const SizedBox(width: 8),
                      _feature(Icons.cloud_outlined, 'Dual-Optic Smoke'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _feature(Icons.thermostat, 'Rapid Thermal'),
                      const SizedBox(width: 8),
                      _feature(Icons.water_drop_outlined, 'Ambient Moisture'),
                    ],
                  ),
                  const Divider(height: 28, color: AppColors.border),
                  _row('Assigned Zone', '$zone • Zone 1'),
                  _row('Device Name', nickname),
                  _row(
                    'Sprinkler Interlock',
                    'Sprinkler Valve Ready (Zone 1)',
                    valueColor: AppColors.success,
                  ),
                  _row('Battery & Signal', '96% • -52 dBm'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onEnter,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Enter Dashboard'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Test burst sent to siren (simulated)'),
              ),
            ),
            icon: const Icon(Icons.volume_up_outlined, size: 16),
            label: const Text(
              'Test Siren & Flame Optical Sensor (3-Sec Burst)',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

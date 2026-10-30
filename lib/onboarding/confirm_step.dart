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
                    color: AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
          'SETUP SAVED • SIMULATED SENSOR READY',
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
            'Setup Complete',
            textAlign: TextAlign.center,
            style: AppTheme.heading(size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            'Your zone and device name are saved to your account. Your account '
            'comes with a simulated sensor, so you can try live readings, '
            'alerts and sprinkler control. A physical sensor can be paired later.',
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
                              'IgnisGuard Sensor',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28, color: AppColors.border),
                  _row('Assigned Zone', zone),
                                    _row(
                    'Sprinkler Interlock',
                    'Simulated',
                    valueColor: AppColors.textSecondary,
                  ),
                  _row(
                    'Battery & Signal',
                    'Shown once a physical sensor reports in',
                    valueColor: AppColors.textSecondary,
                  ),
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
                content: Text('No physical siren connected. Nothing was sent'),
              ),
            ),
            icon: const Icon(Icons.volume_up_outlined, size: 16),
            label: const Text(
              'Test Siren (needs a physical sensor)',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

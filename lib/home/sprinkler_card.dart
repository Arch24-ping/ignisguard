import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class SprinklerCard extends StatefulWidget {
  const SprinklerCard({super.key});

  @override
  State<SprinklerCard> createState() => _SprinklerCardState();
}

class _SprinklerCardState extends State<SprinklerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _hold =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _trigger();
          });
  }

  void _trigger() {
    _hold.reset();
    setState(() => _running = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sprinkler test activated (simulated)')),
    );
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _running = false);
    });
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shower_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automated Sprinkler Valve',
                        style: AppTheme.heading(size: 19),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _running
                                  ? AppColors.critical
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _running
                                ? 'Sprinkler Running (test)'
                                : 'Sprinkler Off — Ready',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Text('System self-test', style: TextStyle(fontSize: 12)),
                  Spacer(),
                  Text(
                    'Today, 08:30 AM',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTapDown: (_) => _hold.forward(),
              onTapUp: (_) => _hold.reverse(),
              onTapCancel: () => _hold.reverse(),
              child: AnimatedBuilder(
                animation: _hold,
                builder: (context, _) {
                  final holding = _hold.value > 0;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 54,
                      color: AppColors.primary,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _hold.value,
                              child: Container(color: AppColors.critical),
                            ),
                          ),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_circle_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _running
                                      ? 'SPRINKLER ACTIVE (TEST)'
                                      : holding
                                      ? 'KEEP HOLDING...'
                                      : 'TEST / TRIGGER SPRINKLER',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Manual Override • Requires 3-Second Confirmation',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

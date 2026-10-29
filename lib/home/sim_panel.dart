import 'package:flutter/material.dart';

import '../data/sim_sensor.dart';

class SimPanel extends StatelessWidget {
  const SimPanel({super.key});

  static String _label(SimMode m) => switch (m) {
        SimMode.normal => 'Normal',
        SimMode.warning => 'Warning',
        SimMode.alarm => 'Alarm',
        SimMode.offline => 'Offline',
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SimSensor.instance,
      builder: (context, _) {
        final sim = SimSensor.instance;
        if (!sim.running) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Simulated sensor',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'No physical sensor is attached. Choose what it reports. '
                'It runs only while this app is open.',
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in SimMode.values)
                    ChoiceChip(
                      label: Text(_label(m)),
                      selected: sim.mode == m,
                      onSelected: (_) => sim.setMode(m),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
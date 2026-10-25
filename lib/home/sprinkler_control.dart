import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/sensor_link.dart';

/// Start/Stop sprinkler control. Only shown in live mode.
/// Writes pumpCmd ("on"/"off") on the owner's device document; the sensor
/// executes it and reports the real state back in pumpOn.
class SprinklerControl extends StatefulWidget {
  const SprinklerControl({super.key});

  @override
  State<SprinklerControl> createState() => _SprinklerControlState();
}

class _SprinklerControlState extends State<SprinklerControl> {
  bool _sending = false;
  String? _error;
  Timer? _timeout;

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  Future<void> _send(String id, String cmd) async {
    setState(() {
      _sending = true;
      _error = null;
    });
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 20), () {
      if (mounted && _sending) {
        setState(() {
          _sending = false;
          _error = 'The sensor did not respond. Check it is online.';
        });
      }
    });
    try {
      await FirebaseFirestore.instance
          .collection('devices')
          .doc(id)
          .update({'pumpCmd': cmd});
    } catch (e) {
      _timeout?.cancel();
      if (mounted) {
        setState(() {
          _sending = false;
          _error = 'Could not send the command. Check your connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final link = SensorLink.instance;
    final id = link.deviceId;
    if (!link.isLive || id == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final online = link.isOnline;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('devices').doc(id).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final pumpOn = data?['pumpOn'] == true;
        final cmd = data?['pumpCmd'];

        // A command has been applied once the sensor resets it to idle.
        if (_sending && cmd == 'idle') {
          _timeout?.cancel();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _sending = false);
          });
        }

        final label = !online
            ? 'Sensor offline, sprinkler cannot be controlled'
            : _sending
                ? 'Sending command...'
                : pumpOn
                    ? 'Sprinkler is running'
                    : 'Sprinkler is off';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    pumpOn ? Icons.water_drop : Icons.water_drop_outlined,
                    color: pumpOn ? scheme.primary : scheme.outline,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: (!online || _sending || pumpOn)
                          ? null
                          : () => _send(id, 'on'),
                      child: const Text('Start sprinkler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: (!online || _sending || !pumpOn)
                          ? null
                          : () => _send(id, 'off'),
                      child: const Text('Stop sprinkler'),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: TextStyle(fontSize: 13, color: scheme.error)),
              ],
            ],
          ),
        );
      },
    );
  }
}
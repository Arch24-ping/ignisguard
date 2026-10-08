import 'package:wifi_scan/wifi_scan.dart';

class ScannedNetwork {
  const ScannedNetwork({
    required this.ssid,
    required this.level,
    required this.secured,
    this.enterprise = false,
  });

  final String ssid;
  final int level; // signal strength in dBm, closer to 0 is stronger
  final bool secured;
  final bool enterprise; // needs a username, e.g. school or work Wi-Fi

  String get signalLabel {
    if (level >= -55) return 'Excellent Signal';
    if (level >= -67) return 'Good Signal';
    if (level >= -80) return 'Fair Signal';
    return 'Weak Signal';
  }
}

class WifiScanResult {
  const WifiScanResult(this.networks, {this.problem});

  final List<ScannedNetwork> networks;

  /// Plain-language reason the scan could not run, or null if it worked.
  final String? problem;
}

class WifiScanner {
  WifiScanner._();

  static Future<WifiScanResult> scan() async {
    try {
      final can = await WiFiScan.instance.canStartScan(askPermissions: true);
      if (can != CanStartScan.yes) {
        return WifiScanResult(const [], problem: _startProblem(can));
      }

      // Android limits how often a new scan may start. If this returns false
      // we still read the most recent results below.
      await WiFiScan.instance.startScan();

      final canGet = await WiFiScan.instance.canGetScannedResults(
        askPermissions: true,
      );
      if (canGet != CanGetScannedResults.yes) {
        return const WifiScanResult(
          [],
          problem: 'Location permission is needed to list nearby networks.',
        );
      }

      final aps = await WiFiScan.instance.getScannedResults();
      final best = <String, ScannedNetwork>{};
      for (final ap in aps) {
        final ssid = ap.ssid.trim();
        if (ssid.isEmpty) continue; // hidden networks have no name
        final caps = ap.capabilities.toUpperCase();
        final enterprise = caps.contains('EAP');
        final secured =
            enterprise ||
            caps.contains('WEP') ||
            caps.contains('WPA') ||
            caps.contains('PSK') ||
            caps.contains('SAE');
        final old = best[ssid];
        if (old == null || ap.level > old.level) {
          best[ssid] = ScannedNetwork(
            ssid: ssid,
            level: ap.level,
            secured: secured,
            enterprise: enterprise,
          );
        }
      }
      final list = best.values.toList()
        ..sort((a, b) => b.level.compareTo(a.level));
      if (list.isEmpty) {
        return const WifiScanResult(
          [],
          problem: 'No networks were found. Try scanning again.',
        );
      }
      return WifiScanResult(list);
    } catch (e) {
      return WifiScanResult(const [], problem: 'Scan failed: $e');
    }
  }

  static String _startProblem(CanStartScan can) {
    switch (can) {
      case CanStartScan.notSupported:
        return 'Wi-Fi scanning is not supported on this device.';
      case CanStartScan.noLocationServiceDisabled:
        return 'Turn on Location in your phone settings, then scan again.';
      case CanStartScan.noLocationPermissionDenied:
        return 'Location permission was denied. Allow it in App settings, '
            'or enter your network name manually.';
      default:
        return 'Location permission is needed to list nearby networks.';
    }
  }
}

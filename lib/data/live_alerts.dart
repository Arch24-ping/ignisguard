import 'package:cloud_firestore/cloud_firestore.dart';

/// One alert document at devices/{id}/alerts/{alertId}.
class LiveAlert {
  const LiveAlert({
    required this.id,
    required this.severity,
    required this.title,
    required this.message,
    required this.at,
  });

  final String id;

  /// "critical", "warning" or "system".
  final String severity;
  final String title;
  final String message;
  final DateTime? at;

  factory LiveAlert.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    String text(String k, String fallback) {
      final v = d[k];
      return v is String ? v : fallback;
    }

    final ts = d['ts'];
    return LiveAlert(
      id: doc.id,
      severity: text('severity', 'system'),
      title: text('title', 'Alert'),
      message: text('message', ''),
      at: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

Stream<List<LiveAlert>> liveAlertsStream(String deviceId) {
  return FirebaseFirestore.instance
      .collection('devices')
      .doc(deviceId)
      .collection('alerts')
      .orderBy('ts', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(LiveAlert.fromDoc).toList());
}
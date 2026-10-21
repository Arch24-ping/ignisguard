import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'profile_store.dart';
import 'settings_store.dart';

/// Keeps the signed-in user's data in Firestore at users/{uid}.
class CloudStore {
  CloudStore._();
  static final CloudStore instance = CloudStore._();

  String? _uid;
  bool onboardingDone = false;

  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  /// Loads this account's data into the local stores. Throws if it cannot
  /// reach Firestore, so the caller can offer a retry.
  Future<void> attach(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = snap.data();
    _uid = uid; // only after a successful load, so nothing writes early
    onboardingDone = (data?['onboardingDone'] ?? false) as bool;
    ProfileStore.instance.applyCloud(data?['profile'] as Map<String, dynamic>?);
    SettingsStore.instance.applyCloud(
      data?['settings'] as Map<String, dynamic>?,
    );
  }

  /// Call after sign-out so the next account never sees this one's data.
  void detach() {
    _uid = null;
    onboardingDone = false;
    ProfileStore.instance.applyCloud(null);
    SettingsStore.instance.applyCloud(null);
  }

  void push(String field, Map<String, dynamic> value) {
    _write({field: value});
  }

  void setOnboardingDone(bool v) {
    onboardingDone = v;
    _write({'onboardingDone': v});
  }

  void _write(Map<String, dynamic> data) {
    final doc = _doc;
    if (doc == null) return;
    doc.set(data, SetOptions(merge: true)).catchError((Object e) {
      debugPrint('Cloud save failed: $e');
    });
  }
}
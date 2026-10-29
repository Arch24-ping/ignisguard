import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WelcomeMailer {
  static const _url = 'https://script.google.com/macros/s/AKfycby4FjnInCfSV_J7sQz46gQLxxHyBg1JE4tcb10dCYvJITi3lKbDP5s8352Kzf1DCj1i/exec';

  static Future<void> send(String name) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await user.getIdToken(true);
      final res = await http
          .post(
            Uri.parse(_url),
            headers: {'Content-Type': 'text/plain;charset=utf-8'},
            body: jsonEncode({'idToken': token, 'name': name}),
          )
          .timeout(const Duration(seconds: 20));
      debugPrint('Welcome email: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('Welcome email request ended: $e');
    }
  }
}
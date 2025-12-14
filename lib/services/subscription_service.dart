import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/backend_config.dart';

class SubscriptionStatus {
  final bool active;
  final String plan;
  final String status;
  final DateTime? periodEnd;

  SubscriptionStatus({
    required this.active,
    required this.plan,
    required this.status,
    required this.periodEnd,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      active: json['active'] ?? false,
      plan: json['plan'] ?? 'free',
      status: json['status'] ?? 'inactive',
      periodEnd: json['period_end'] != null
          ? DateTime.parse(json['period_end'])
          : null,
    );
  }
}

class SubscriptionService {
  /// 🔎 Obtener estado actual
  static Future<SubscriptionStatus> getStatus(String uid) async {
    final url = Uri.parse(
      '${BackendConfig.baseUrl}/api/subscription/status?uid=',
    );

    try {
      final res = await http.get(url);
      if (res.statusCode != 200) {
        throw Exception(res.body);
      }
      return SubscriptionStatus.fromJson(jsonDecode(res.body));
    } catch (e) {
      debugPrint("❌ getStatus error: $e");
      return SubscriptionStatus(
        active: false,
        plan: 'free',
        status: 'inactive',
        periodEnd: null,
      );
    }
  }

  /// 💳 Crear Checkout de Stripe
  static Future<String?> createCheckoutSession({
    required String uid,
    required String plan, // "pro" | "ultra"
  }) async {
    final url = Uri.parse('${BackendConfig.baseUrl}/subscription/checkout');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'plan': plan}),
      );

      if (res.statusCode != 200) {
        throw Exception(res.body);
      }

      final json = jsonDecode(res.body);
      return json['checkout_url'];
    } catch (e) {
      debugPrint("❌ createCheckoutSession error: $e");
      return null;
    }
  }
}

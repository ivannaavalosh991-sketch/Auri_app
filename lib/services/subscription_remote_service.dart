import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionRemoteService {
  static const String _baseUrl =
      "https://auri-backend-production-ef14.up.railway.app";

  /// 🔄 Sincroniza el plan desde el backend y lo guarda en prefs
  static Future<void> syncPlanFromBackend() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // no logueado → free
      await _savePlan("free");
      return;
    }

    final uid = user.uid;

    try {
      final url = Uri.parse("$_baseUrl/api/subscription/status?uid=$uid");

      final res = await http.get(url);

      if (res.statusCode != 200) {
        throw Exception(res.body);
      }

      final json = jsonDecode(res.body);
      final plan = (json["plan"] ?? "free").toString().toLowerCase();

      await _savePlan(plan);

      print("✅ PLAN sync desde backend: $plan");
    } catch (e) {
      print("⚠️ No se pudo sync plan desde backend → fallback local");
      // fallback: no tocar prefs
    }
  }

  static Future<void> _savePlan(String plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("auri_plan", plan);
  }
}

import 'package:flutter/material.dart';
import 'package:auri_app/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String uid = "";
  String name = "";
  String plan = "free"; // free, pro, ultra
  bool active = false;
  DateTime? periodEnd;

  bool get isPro => plan == "pro" && active;
  bool get isUltra => plan == "ultra" && active;

  // ============================================================
  // Cargar info inicial (desde SharedPrefs)
  // ============================================================
  Future<void> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    uid = prefs.getString("firebase_uid") ?? "";
    name = prefs.getString("userName") ?? "";
    plan = prefs.getString("user_plan") ?? "free";
    notifyListeners();
  }

  // ============================================================
  // Guardar información
  // ============================================================
  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_plan", plan);
  }

  // ============================================================
  // Actualizar estado de Stripe (cuando abre la app)
  // ============================================================
  Future<void> refreshSubscription() async {
    if (uid.isEmpty) return;

    final status = await SubscriptionService.getStatus(uid);

    active = status.active;
    plan = status.plan;
    periodEnd = status.periodEnd;

    await _saveLocal();
    notifyListeners();
  }

  // ============================================================
  // Setters para datos locales del usuario
  // ============================================================
  void setUID(String id) {
    uid = id;
    notifyListeners();
  }

  void setName(String n) {
    name = n;
    notifyListeners();
  }
}

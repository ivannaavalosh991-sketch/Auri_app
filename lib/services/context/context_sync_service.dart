import 'dart:convert';
import 'package:http/http.dart' as http;
import 'context_models.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContextSyncService {
  static const String baseUrl =
      "https://auri-backend-production-ef14.up.railway.app";

  static bool _syncing = false;

  static Future<void> sync(AuriContextPayload payload) async {
    if (_syncing) return; // evita doble sync
    _syncing = true;

    try {
      final url = Uri.parse("$baseUrl/api/context/sync");

      // 🔥 UID del usuario actual (o guest si no está logueado)
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "guest";

      final fullJson = payload.toJson();
      fullJson["firebase_uid"] = uid;

      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(fullJson),
      );

      if (resp.statusCode != 200) {
        print("⚠️ ContextSync ERROR: ${resp.statusCode} → ${resp.body}");
      } else {
        print("✅ ContextSync OK — UID enviado: $uid");
      }
    } catch (e) {
      print("🔥 ERROR ContextSync: $e");
    } finally {
      _syncing = false;
    }
  }
}

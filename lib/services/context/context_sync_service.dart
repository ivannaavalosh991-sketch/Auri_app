import 'dart:convert';
import 'package:http/http.dart' as http;
import 'context_models.dart';

class ContextSyncService {
  static const String baseUrl =
      "https://auri-backend-production-ef14.up.railway.app";

  static bool _syncing = false;

  static Future<void> sync(AuriContextPayload payload) async {
    if (_syncing) return; // evita doble sync
    _syncing = true;

    try {
      final url = Uri.parse("$baseUrl/api/context/sync");
      final body = jsonEncode(payload.toJson());

      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (resp.statusCode != 200) {
        print("⚠️ ContextSync ERROR: ${resp.statusCode} → ${resp.body}");
      } else {
        print("✅ ContextSync OK");
      }
    } catch (e) {
      print("🔥 ERROR ContextSync: $e");
    } finally {
      _syncing = false;
    }
  }
}

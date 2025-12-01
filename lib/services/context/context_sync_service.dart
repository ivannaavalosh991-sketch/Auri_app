import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:auri_app/services/context/context_models.dart';

class ContextSyncService {
  static const String baseUrl =
      "https://auri-backend-production-ef14.up.railway.app";

  /// Envía el payload completo al backend
  static Future<void> sync(AuriContextPayload payload) async {
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
    }
  }
}

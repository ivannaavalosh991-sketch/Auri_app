// lib/services/context/context_sync_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:auri_app/services/context/context_models.dart';

class ContextSyncService {
  static const String baseUrl =
      "https://auri-backend-production-ef14.up.railway.app";

  /// Enviar el payload completo al backend
  static Future<void> sync(AuriContextPayload payload) async {
    try {
      final url = Uri.parse("$baseUrl/context/sync");

      final body = jsonEncode(payload.toJson());

      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (resp.statusCode != 200) {
        print("⚠ ContextSync ERROR: ${resp.body}");
      } else {
        print("✅ ContextSync OK");
      }
    } catch (e) {
      print("🔥 ERROR ContextSync: $e");
    }
  }
}

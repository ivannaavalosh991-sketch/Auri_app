// lib/auri/mind/auri_brain.dart

import 'package:auri_app/auri/mind/auri_mind_engine.dart';
import 'package:auri_app/auri/mind/tts/tts_engine.dart';

/// Resultado final de Auri Brain hacia la UI.
class AuriBrainOutput {
  final String replyText; // Lo que Auri dice en texto
  final String intent; // Intent detectado
  final Map<String, dynamic> data; // Extra (weather, reminderId, etc.)
  final String emotion; // Modo emocional simple
  final bool spoken; // Si se reprodujo TTS

  AuriBrainOutput({
    required this.replyText,
    required this.intent,
    required this.data,
    required this.emotion,
    required this.spoken,
  });
}

class AuriBrain {
  static final AuriBrain instance = AuriBrain._internal();
  AuriBrain._internal();

  // Estado emocional ultra simple por ahora
  String _emotion = "neutral";

  String get currentEmotion => _emotion;

  void _updateEmotion(String intent) {
    if (intent.startsWith("smalltalk_")) {
      _emotion = "happy";
    } else if (intent == "fallback") {
      _emotion = "confused";
    } else if (intent == "add_reminder" ||
        intent == "get_agenda" ||
        intent == "add_alarm") {
      _emotion = "focused";
    } else {
      _emotion = "neutral";
    }
  }

  /// Procesa el texto del usuario, calcula intent, acción y
  /// opcionalmente habla usando TTS.
  Future<AuriBrainOutput> process(String userText, {bool speak = true}) async {
    // 1) Procesar con el Mind Engine (intents + acciones)
    final mindReply = await AuriMindEngine.instance.processUserMessage(
      userText,
    );

    // 2) Actualizar estado emocional ultra simple
    _updateEmotion(mindReply.intent);

    // 3) Hablar si corresponde
    bool spoken = false;
    if (speak && mindReply.reply.trim().isNotEmpty) {
      try {
        await TTSEngine.instance.speak(mindReply.reply);
        spoken = true;
      } catch (e) {
        // No rompemos el flujo si TTS falla
        // ignore: avoid_print
        print("TTS error: $e");
      }
    }

    return AuriBrainOutput(
      replyText: mindReply.reply,
      intent: mindReply.intent,
      data: mindReply.data,
      emotion: _emotion,
      spoken: spoken,
    );
  }
}

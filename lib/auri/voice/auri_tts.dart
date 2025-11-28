import 'package:flutter_tts/flutter_tts.dart';

class AuriTTS {
  AuriTTS._();
  static final AuriTTS instance = AuriTTS._();

  final FlutterTts _tts = FlutterTts();

  Future<void> init() async {
    await _tts.setLanguage("es-ES");
    await _tts.setSpeechRate(0.92);
    await _tts.setPitch(1.05);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    print("🔊 Auri TTS: $text");
    await _tts.stop();
    await _tts.speak(text);
  }
}

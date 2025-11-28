import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:auri_app/auri/voice/stt_whisper_online.dart';
//import 'package:auri_app/services/realtime/auri_realtime.dart';
import 'package:auri_app/auri/voice/slime_voice_state.dart';

enum VoiceState { idle, listening, thinking, talking }

class VoiceSessionController {
  static final ValueNotifier<VoiceState> voiceState = ValueNotifier(
    VoiceState.idle,
  );

  static bool _recording = false;
  static Timer? _silenceTimer;

  // ------------------------------------------------------------------
  static Future<void> startRecording() async {
    if (_recording) return;

    _recording = true;
    voiceState.value = VoiceState.listening;
    SlimeVoiceStates.listening();

    print("🎙 Iniciando grabación…");
    await STTWhisperOnline.instance.startRecording();

    _startSilenceWatcher();
  }

  // ------------------------------------------------------------------
  static void _startSilenceWatcher() {
    _silenceTimer?.cancel();

    int elapsed = 0;
    const int minMs = 1200;
    const int maxMs = 8000;

    _silenceTimer = Timer.periodic(const Duration(milliseconds: 180), (
      timer,
    ) async {
      elapsed += 180;

      if (!_recording) {
        timer.cancel();
        return;
      }

      final amp = STTWhisperOnline.instance.lastAmplitude;

      if (elapsed < minMs) return;

      if (amp < 0.06 || elapsed > maxMs) {
        timer.cancel();
        await stopRecording();
        return;
      }
    });
  }

  // ------------------------------------------------------------------
  static Future<void> stopRecording() async {
    if (!_recording) return;

    _recording = false;
    _silenceTimer?.cancel();

    print("🎙 Deteniendo grabación…");

    await STTWhisperOnline.instance.stopRecording();

    voiceState.value = VoiceState.thinking;
    SlimeVoiceStates.thinking();

    // El backend enviará partial + final → AuriRealtime triggers UI
    print("🧠 Auri esperando respuesta WS…");

    // Cuando llegue final → UI la muestra y pasamos a talking
    // Luego idle lo maneja la HUD después
  }

  // ------------------------------------------------------------------
  static Future<void> cancel() async {
    if (!_recording) return;

    print("🛑 Cancelando grabación");

    _recording = false;
    _silenceTimer?.cancel();

    await STTWhisperOnline.instance.stopRecording();

    voiceState.value = VoiceState.idle;
    SlimeVoiceStates.idle();
  }
}

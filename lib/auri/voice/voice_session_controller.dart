import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:auri_app/auri/voice/stt_whisper_online.dart';
import 'package:auri_app/auri/voice/slime_voice_state.dart';
import 'package:auri_app/services/realtime/auri_realtime.dart';

enum VoiceState { idle, listening, thinking, talking }

class VoiceSessionController {
  static final ValueNotifier<VoiceState> voiceState = ValueNotifier(
    VoiceState.idle,
  );

  static bool _recording = false;
  static Timer? _silenceTimer;

  // ========================================================
  // START RECORDING
  // ========================================================
  static Future<void> startRecording() async {
    if (_recording) return; // STOP LOOP
    _recording = true;

    voiceState.value = VoiceState.listening;
    SlimeVoiceStates.listening();

    print("🎙 Iniciando grabación…");

    await STTWhisperOnline.instance.startRecording();
    _startSilenceWatcher();
  }

  // ========================================================
  // WATCHER DE SILENCIO
  // ========================================================
  static void _startSilenceWatcher() {
    _silenceTimer?.cancel();
    int elapsed = 0;

    const int minMs = 900;
    const int maxMs = 9000;

    _silenceTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (!_recording) {
        t.cancel();
        return;
      }

      elapsed += 200;

      final amp = STTWhisperOnline.instance.lastAmplitude;

      if (elapsed < minMs) return;

      if (amp < 0.03) {
        print("🔇 Silencio detectado");
        stopRecording();
        t.cancel();
        return;
      }

      if (elapsed >= maxMs) {
        print("⏳ Timeout de voz");
        stopRecording();
        t.cancel();
        return;
      }
    });
  }

  // ========================================================
  // STOP RECORDING
  // ========================================================
  static Future<void> stopRecording() async {
    if (!_recording) return;

    _recording = false;
    _silenceTimer?.cancel();

    print("🎙 Deteniendo grabación…");

    await STTWhisperOnline.instance.stopRecording();

    voiceState.value = VoiceState.thinking;
    SlimeVoiceStates.thinking();

    print("🧠 Auri esperando respuesta WS…");
  }

  // ========================================================
  // CANCELACIÓN MANUAL (doble tap)
  // ========================================================
  static Future<void> cancel() async {
    if (!_recording) return;

    print("🛑 Cancelando grabación por usuario");

    _recording = false;
    _silenceTimer?.cancel();

    await STTWhisperOnline.instance.stopRecording();

    voiceState.value = VoiceState.idle;
    SlimeVoiceStates.idle();
  }
}

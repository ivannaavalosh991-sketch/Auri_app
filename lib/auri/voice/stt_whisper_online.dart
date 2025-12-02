import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:auri_app/services/realtime/auri_realtime.dart';

class STTWhisperOnline {
  STTWhisperOnline._();
  static final STTWhisperOnline instance = STTWhisperOnline._();

  final FlutterSoundRecorder _rec = FlutterSoundRecorder();
  bool _ready = false;
  bool _recording = false;

  /// 👈 FIX: Getter público para saber si está grabando
  bool get isRecording => _recording;

  StreamSubscription<RecordingDisposition>? _pcmTap;

  final ValueNotifier<double> amplitude = ValueNotifier(0.0);
  double lastAmplitude = 0.0;

  // ---------------------------------------------------
  Future<void> init() async {
    if (_ready) return;

    final perm = await Permission.microphone.request();
    if (!perm.isGranted) throw Exception("Micrófono denegado.");

    await _rec.openRecorder();
    await _rec.setSubscriptionDuration(const Duration(milliseconds: 40));

    _ready = true;
  }

  // ---------------------------------------------------
  Future<void> startRecording() async {
    await init();
    if (_recording) return;

    await AuriRealtime.instance.ensureConnected();
    AuriRealtime.instance.startSession();

    print("🎤 Auri escuchando…");

    _recording = true;
    amplitude.value = 0;

    // Limpia taps previos
    await _pcmTap?.cancel();

    // ===================================================
    // TAP DE AMPLITUD: decibeles o fallback simulado
    // ===================================================
    _pcmTap = _rec.onProgress!.listen((event) {
      if (event.decibels != null) {
        final db = event.decibels!;
        final amp = ((db + 60) / 60).clamp(0.0, 1.0);

        lastAmplitude = amp;
        amplitude.value = amp;
      } else {
        final amp = 0.02 + Random().nextDouble() * 0.03;

        lastAmplitude = amp;
        amplitude.value = amp;
      }
    });

    // ===================================================
    // ENVÍO DE PCM16 AL WEBSOCKET
    // ===================================================
    await _rec.startRecorder(
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
      bufferSize: 2048,
      toStream: AuriRealtime.instance.micSink,
    );
  }

  // ---------------------------------------------------
  Future<void> stopRecording() async {
    if (!_recording) return;

    _recording = false;
    print("🛑 Auri dejó de escuchar");

    await _rec.stopRecorder();
    await _pcmTap?.cancel();
    _pcmTap = null;

    amplitude.value = 0;
    lastAmplitude = 0;

    AuriRealtime.instance.endAudio();
  }
}

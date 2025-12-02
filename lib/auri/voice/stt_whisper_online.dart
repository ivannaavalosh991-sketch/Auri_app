// lib/auri/voice/stt_whisper_online.dart
// Versión V5 compatible con Hands-Free Mode

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

  bool get isRecording => _recording;

  StreamSubscription<RecordingDisposition>? _pcmTap;

  final ValueNotifier<double> amplitude = ValueNotifier(0.0);
  double lastAmplitude = 0.0;

  Future<void> init() async {
    if (_ready) return;

    final perm = await Permission.microphone.request();
    if (!perm.isGranted) throw Exception("Micrófono denegado.");

    await _rec.openRecorder();
    await _rec.setSubscriptionDuration(const Duration(milliseconds: 40));

    _ready = true;
  }

  Future<void> startRecording() async {
    if (_recording) return; // STOP LOOP

    if (!_ready) {
      await init();
    }

    await AuriRealtime.instance.ensureConnected();
    AuriRealtime.instance.startSession();

    print("🎤 Auri escuchando…");
    _recording = true;
    amplitude.value = 0;

    await _pcmTap?.cancel();

    _pcmTap = _rec.onProgress!.listen((event) {
      final db = event.decibels ?? -50;
      final amp = ((db + 60) / 60).clamp(0.0, 1.0);

      lastAmplitude = amp;
      amplitude.value = amp;
    });

    await _rec.startRecorder(
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
      bufferSize: 2048,
      toStream: AuriRealtime.instance.micSink,
    );
  }

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

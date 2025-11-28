// lib/auri/mind/tts/tts_engine.dart

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class TTSEngine {
  TTSEngine._internal();
  static final TTSEngine instance = TTSEngine._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://192.168.1.42:8000", // MISMA IP QUE /stt
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  final AudioPlayer _player = AudioPlayer();

  Future<void> speak(String text, {String voice = "alloy"}) async {
    if (text.trim().isEmpty) return;

    // Si ya está hablando, paramos primero
    if (_player.playing) {
      await _player.stop();
    }

    final response = await _dio.post<List<int>>(
      "/tts",
      data: {"text": text, "voice": voice},
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) return;

    final dir = await getTemporaryDirectory();
    final file = File(
      "${dir.path}/auri_tts_${DateTime.now().millisecondsSinceEpoch}.mp3",
    );

    await file.writeAsBytes(bytes, flush: true);

    await _player.setFilePath(file.path);
    await _player.play();
  }

  Future<void> stop() async {
    if (_player.playing) {
      await _player.stop();
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

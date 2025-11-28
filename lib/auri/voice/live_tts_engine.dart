import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_sound/flutter_sound.dart';

typedef PartialCallback = void Function(String);

class LiveTTSEngine {
  LiveTTSEngine._internal();
  static final LiveTTSEngine instance = LiveTTSEngine._internal();

  WebSocketChannel? _ws;
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _connected = false;

  String _buffer = "";
  PartialCallback? onPartial;

  // Inicializar audio
  Future<void> init() async {
    await _player.openPlayer();
  }

  // Conexión WebSocket
  Future<void> connect(String ip) async {
    if (_connected) return;

    final url = "ws://$ip:8001/realtime";
    print("🔌 Conectando a $url");

    _ws = WebSocketChannel.connect(Uri.parse(url));
    _connected = true;

    // Iniciar streaming de audio PCM
    await _player.startPlayerFromStream(
      codec: Codec.pcm16,
      sampleRate: 24000,
      numChannels: 1,
      bufferSize: 2048,
      interleaved: true,
    );

    // Recepción del servidor
    _ws!.stream.listen((event) async {
      // 🔊 AUDIO PCM
      if (event is Uint8List) {
        await _player.feedFromStream(event);
        return;
      }

      // 🧠 MENSAJES JSON
      if (event is String) {
        Map<String, dynamic> obj;

        try {
          obj = jsonDecode(event);
        } catch (_) {
          print("❌ JSON inválido recibido: $event");
          return;
        }

        // 🟣 Texto parcial → Auri habla mientras piensa
        if (obj["type"] == "partial_text") {
          _buffer += obj["text"];
          onPartial?.call(_buffer);
        }

        // 🟣 Final de frase
        if (obj["type"] == "done") {
          print("🟣 Frase completada");
          _buffer = "";
        }

        return;
      }

      print("⚠ Evento desconocido: $event");
    });
  }

  // Enviar mensaje a Auri
  Future<void> speak(String text, {String voice = "alloy"}) async {
    if (!_connected) return;

    // Reiniciar el stream antes de hablar
    await _player.stopPlayer();
    await _player.startPlayerFromStream(
      codec: Codec.pcm16,
      sampleRate: 24000,
      numChannels: 1,
      bufferSize: 2048,
      interleaved: true,
    );

    final msg = jsonEncode({"text": text, "voice": voice});

    _ws!.sink.add(msg);
  }

  Future<void> dispose() async {
    await _player.closePlayer();
    await _ws?.sink.close();
  }
}

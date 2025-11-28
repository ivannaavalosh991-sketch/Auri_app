import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

typedef PartialCallback = void Function(String text);
typedef FinalCallback = void Function(String text);

class AuriRealtime {
  // ------------------------------------------------------------
  // Singleton
  // ------------------------------------------------------------
  AuriRealtime._internal();
  static final AuriRealtime instance = AuriRealtime._internal();

  WebSocketChannel? _ws;
  bool _connected = false;

  // Callbacks externos para HUD y Slime
  PartialCallback? onPartial;
  FinalCallback? onFinal;

  // Buffer para texto incremental
  String _buffer = "";

  // Reconexión automática
  Timer? _reconnectTimer;

  // ------------------------------------------------------------
  // Conectar WebSocket
  // ------------------------------------------------------------
  Future<void> connect(String ip) async {
    if (_connected) return;

    final url = "ws://$ip:8000/realtime";
    print("🔌 Conectando a $url");

    try {
      _ws = WebSocketChannel.connect(Uri.parse(url));
      _connected = true;
      print("🟢 Auri Realtime conectado");

      // Escuchar mensajes del servidor
      _ws!.stream.listen(
        (event) => _handleMessage(event),
        onError: (err) {
          print("❌ Error en Realtime: $err");
          _connected = false;
          _scheduleReconnect(ip);
        },
        onDone: () {
          print("🔌 WebSocket cerrado por el servidor");
          _connected = false;
          _scheduleReconnect(ip);
        },
      );
    } catch (e) {
      print("❌ No se pudo conectar: $e");
      _connected = false;
      _scheduleReconnect(ip);
    }
  }

  // ------------------------------------------------------------
  // RECONEXIÓN AUTOMÁTICA
  // ------------------------------------------------------------
  void _scheduleReconnect(String ip) {
    _reconnectTimer?.cancel();
    print("♻ Intentando reconectar en 2s…");

    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      connect(ip); // reintenta
    });
  }

  // ------------------------------------------------------------
  // MANEJO DE MENSAJES
  // ------------------------------------------------------------
  void _handleMessage(dynamic event) {
    // 🔊 Si por error llega audio (no debería), lo ignoramos
    if (event is Uint8List) {
      print("⚠ Evento PCM ignorado");
      return;
    }

    if (event is String) {
      Map<String, dynamic> obj;

      try {
        obj = jsonDecode(event);
      } catch (e) {
        print("⚠ JSON inválido recibido: $event");
        return;
      }

      final type = obj["type"];

      // ------------------------------
      // 🟣 Texto parcial (thinking)
      // ------------------------------
      if (type == "partial") {
        final chunk = obj["text"] ?? "";
        _buffer += chunk;
        onPartial?.call(_buffer);
        return;
      }

      // ------------------------------
      // 🟣 Texto final (respuesta completa)
      // ------------------------------
      if (type == "final") {
        final text = obj["text"] ?? "";
        onFinal?.call(text);
        _buffer = "";
        return;
      }

      print("⚠ Tipo desconocido: $obj");
    }
  }

  // ------------------------------------------------------------
  // ENVIAR MENSAJE AL BACKEND
  // ------------------------------------------------------------
  Future<void> send(String userText) async {
    if (!_connected) {
      print("❌ No conectado a WS");
      return;
    }

    final payload = jsonEncode({
      "text": userText,
      "voice": "hybrid", // tu novia pidió híbrida
    });

    _ws!.sink.add(payload);
    print("📤 Enviado a Auri Realtime: $userText");
  }

  // ------------------------------------------------------------
  // CERRAR SESIÓN
  // ------------------------------------------------------------
  Future<void> dispose() async {
    print("🔻 Cerrando Realtime…");
    await _ws?.sink.close();
    _connected = false;
  }
}

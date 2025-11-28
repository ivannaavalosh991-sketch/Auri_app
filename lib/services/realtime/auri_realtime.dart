import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:auri_app/auri/voice/auri_tts.dart';

/// ----------------------------------------------------------------
///  A U R I   R E A L T I M E   —   V4
/// ----------------------------------------------------------------
///  - PCM → STT final
///  - TTS vía FlutterTTS (temporal)
///  - Eventos: partial, final, thinking, lip-sync, acciones
///  - Reconexión automática
///  - Manejo de sesiones: start / stop / audio_end
/// ----------------------------------------------------------------

class AuriRealtime {
  static final AuriRealtime instance = AuriRealtime._();
  AuriRealtime._();

  WebSocketChannel? _ch;
  bool _connected = false;
  bool get connected => _connected;

  String _ip = "";
  Timer? _retryTimer;

  // ------------------------------------------------------------
  // STREAM PCM → WS
  // ------------------------------------------------------------
  final StreamController<Uint8List> _micStream =
      StreamController<Uint8List>.broadcast();

  StreamSink<Uint8List> get micSink => _micStream.sink;

  // ------------------------------------------------------------
  // EVENTOS — listeners múltiples
  // ------------------------------------------------------------
  final List<void Function(String)> _onPartial = [];
  final List<void Function(String)> _onFinal = [];
  final List<void Function(bool)> _onThinking = [];
  final List<void Function(double)> _onLip = [];
  final List<void Function(Map<String, dynamic>)> _onAction = [];
  final List<void Function(Uint8List)> _onAudio = [];

  void addOnPartial(void Function(String) f) => _onPartial.add(f);
  void addOnFinal(void Function(String) f) => _onFinal.add(f);
  void addOnThinking(void Function(bool) f) => _onThinking.add(f);
  void addOnLip(void Function(double) f) => _onLip.add(f);
  void addOnAction(void Function(Map<String, dynamic>) f) => _onAction.add(f);
  void addOnAudio(void Function(Uint8List) f) => _onAudio.add(f);

  // ------------------------------------------------------------
  // CONEXIÓN
  // ------------------------------------------------------------
  Future<void> connect(String ip) async {
    if (_connected) return;
    _ip = ip;

    final url = "ws://$ip:8000/realtime";
    print("🔌 Conectando WS → $url");

    try {
      _ch = WebSocketChannel.connect(Uri.parse(url));
      _connected = true;
      _retryTimer?.cancel();

      print("🟢 WS conectado");

      _sendJsonSafe({
        "type": "client_hello",
        "client": "auri_app",
        "version": "0.2.0",
      });

      // AUDIO saliente
      _micStream.stream.listen((pcmBytes) {
        try {
          _ch?.sink.add(pcmBytes);
        } catch (e) {
          print("❌ Error enviando PCM: $e");
        }
      });

      // MANEJO DE RESPUESTAS
      _ch!.stream.listen(
        (data) {
          if (data is Uint8List) {
            // (A futuro) audio de TTS real-time
            for (var cb in _onAudio) cb(data);
            return;
          }
          _handleMessage(data);
        },
        onError: (err) {
          print("❌ WS error: $err");
          _connected = false;
          _scheduleReconnect();
        },
        onDone: () {
          print("🔌 WS desconectado");
          _connected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      print("❌ No se pudo conectar: $e");
      _connected = false;
      _scheduleReconnect();
    }
  }

  Future<void> ensureConnected(String ip) async {
    if (_connected) return;
    await connect(ip);
  }

  void _scheduleReconnect() {
    if (_retryTimer != null) return;

    _retryTimer = Timer(const Duration(seconds: 3), () {
      print("🔄 Reintentando conexión WS…");
      _retryTimer = null;
      connect(_ip);
    });
  }

  // ------------------------------------------------------------
  // ENVÍO JSON SEGURO
  // ------------------------------------------------------------
  void _sendJsonSafe(Map<String, dynamic> payload) {
    if (!_connected) return;
    try {
      _ch?.sink.add(jsonEncode(payload));
    } catch (e) {
      print("❌ Error enviando JSON: $e");
    }
  }

  // ------------------------------------------------------------
  // SESIONES DE VOZ
  // ------------------------------------------------------------
  void startSession() => _sendJsonSafe({"type": "start_session"});

  void stopSession() => _sendJsonSafe({"type": "stop_session"});

  void endAudio() => _sendJsonSafe({"type": "audio_end"});

  void sendText(String text) =>
      _sendJsonSafe({"type": "text_command", "text": text});

  // ------------------------------------------------------------
  // MANEJO DE MENSAJES
  // ------------------------------------------------------------
  void _handleMessage(dynamic data) {
    late final Map<String, dynamic> msg;

    try {
      msg = Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      print("⚠ Mensaje no JSON: $data");
      return;
    }

    final type = msg["type"];

    switch (type) {
      case "stt_partial":
      case "reply_partial":
        for (var cb in _onPartial) cb(msg["text"] ?? "");
        break;

      case "stt_final":
        for (var cb in _onFinal) cb(msg["text"] ?? "");
        break;

      case "reply_final":
        final text = msg["text"] ?? "";
        for (var cb in _onFinal) cb(text);
        AuriTTS.instance.speak(text); // 🔊 HABLAR AQUI
        break;

      case "thinking":
        for (var cb in _onThinking) cb(msg["state"] == true);
        break;

      case "lip_sync":
        final e = (msg["energy"] ?? 0.0).toDouble();
        for (var cb in _onLip) cb(e);
        break;

      case "action_create_reminder":
        for (var cb in _onAction) cb(msg);
        break;

      default:
        print("ℹ Evento desconocido: $msg");
    }
  }

  // ------------------------------------------------------------
  // CERRAR
  // ------------------------------------------------------------
  Future<void> close() async {
    await _micStream.close();
    await _ch?.sink.close();
    _connected = false;
  }
}

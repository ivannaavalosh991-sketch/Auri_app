// lib/services/realtime/auri_realtime.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

// Voice / TTS
import 'package:auri_app/auri/voice/tts_player_stream.dart';
import 'package:auri_app/auri/voice/stt_whisper_online.dart';

// Reminder Bridge
import 'package:auri_app/models/reminder_hive.dart';
import 'package:auri_app/controllers/reminder/reminder_controller.dart';
import 'package:auri_app/services/reminder_scheduler.dart';

class AuriRealtime {
  AuriRealtime._();
  static final AuriRealtime instance = AuriRealtime._();

  WebSocketChannel? _ch;
  bool _connected = false;
  bool _connecting = false;

  Timer? _retryTimer;
  Timer? _heartbeat;

  // Dominio del backend Railway
  static const String _host = "auri-backend-production-ef14.up.railway.app";

  // ---------------- MIC STREAM ----------------
  final StreamController<Uint8List> _micStream =
      StreamController<Uint8List>.broadcast();
  StreamSink<Uint8List> get micSink => _micStream.sink;

  // ---------------- CALLBACKS ----------------
  final _onPartial = <void Function(String)>[];
  final _onFinal = <void Function(String)>[];
  final _onThinking = <void Function(bool)>[];
  final _onLip = <void Function(double)>[];
  final _onAction = <void Function(Map<String, dynamic>)>[];

  void addOnPartial(void Function(String) f) => _onPartial.add(f);
  void addOnFinal(void Function(String) f) => _onFinal.add(f);
  void addOnThinking(void Function(bool) f) => _onThinking.add(f);
  void addOnLip(void Function(double) f) => _onLip.add(f);
  void addOnAction(void Function(Map<String, dynamic>) f) => _onAction.add(f);

  // =========================================================
  // CONEXIÓN
  // =========================================================
  Future<void> ensureConnected() async {
    if (_connected || _connecting) return;
    connect();
  }

  Future<void> connect() async {
    if (_connected || _connecting) return;

    // Construcción segura de URL WebSocket para evitar el puerto :0
    final url = Uri(scheme: "wss", host: _host, path: "/realtime").toString();

    print("🔌 WS conectando → $url");

    _connecting = true;

    try {
      _ch = WebSocketChannel.connect(Uri.parse(url));
      _connected = true;
      _connecting = false;
      print("🟢 WS conectado");

      // HELLO
      _sendJson({
        "type": "client_hello",
        "client": "auri_app",
        "version": "1.0.0",
      });

      // enviar audio del micro al WS
      _micStream.stream.listen((bytes) {
        if (_connected) _ch?.sink.add(bytes);
      });

      // heartbeat
      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(
        const Duration(seconds: 20),
        (_) => _sendJson({"type": "ping"}),
      );

      // escuchar mensajes
      _ch!.stream.listen(
        _onWsMessage,
        onDone: _handleClose,
        onError: (_) => _handleClose(),
      );
    } catch (e) {
      print("❌ Error WS: $e");
      _connected = false;
      _connecting = false;
      _scheduleReconnect();
    }
  }

  void _handleClose() {
    print("🔌 WS cerrado");
    _connected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_retryTimer != null) return;

    _retryTimer = Timer(const Duration(seconds: 3), () {
      print("🔄 Reintentando WS…");
      _retryTimer = null;
      connect();
    });
  }

  void _sendJson(Map<String, dynamic> map) {
    if (!_connected) return;
    try {
      _ch?.sink.add(jsonEncode(map));
    } catch (_) {}
  }

  // =========================================================
  void startSession() => _sendJson({"type": "start_session"});
  void endAudio() => _sendJson({"type": "audio_end"});
  void sendText(String t) => _sendJson({"type": "text_command", "text": t});

  // =========================================================
  // MENSAJES DEL BACKEND
  // =========================================================
  Future<void> _onWsMessage(dynamic data) async {
    // AUDIO MP3 STREAM
    if (data is List<int>) {
      Uint8List bytes = Uint8List.fromList(data);
      await AuriTtsStreamPlayer.instance.addChunk(bytes);
      return;
    }

    // JSON
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(data);
    } catch (_) {
      print("⚠ JSON inválido recibido");
      return;
    }

    switch (msg["type"]) {
      case "reply_partial":
        for (final f in _onPartial) f(msg["text"] ?? "");
        break;

      case "reply_final":
        for (final f in _onPartial) f("");
        for (final f in _onFinal) f(msg["text"] ?? "");
        break;

      case "stt_final":
        for (final f in _onFinal) f(msg["text"] ?? "");
        break;

      case "thinking":
        final isThinking = msg["state"] == true;
        for (final f in _onThinking) f(isThinking);

        if (!isThinking) {
          await STTWhisperOnline.instance.startRecording();
        }
        break;

      case "lip_sync":
        final e = (msg["energy"] ?? 0).toDouble();
        for (final f in _onLip) f(e);
        break;

      case "action":
        for (final f in _onAction) f(msg);
        await _runAction(msg["action"], msg["payload"]);
        break;

      case "tts_end":
        await AuriTtsStreamPlayer.instance.finalize();
        break;

      default:
        print("ℹ Evento desconocido: $msg");
    }
  }

  // =========================================================
  // ACTIONS BRIDGE
  // =========================================================
  Future<void> _runAction(String? action, dynamic payload) async {
    if (action == null) return;

    switch (action) {
      case "create_reminder":
        await _bridgeCreateReminder(payload);
        break;

      case "delete_reminder":
        await _bridgeDeleteReminder(payload);
        break;

      case "open_weather":
      case "open_outfit":
        break;

      default:
        print("⚠ Acción desconocida: $action");
    }
  }

  // ---------------------------------------
  // Crear recordatorio desde backend
  // ---------------------------------------
  Future<void> _bridgeCreateReminder(dynamic payload) async {
    if (payload == null) return;

    try {
      final title = payload["title"];
      final dtIso = payload["datetime"];

      if (title == null || dtIso == null) return;

      final r = ReminderHive(
        id: "${DateTime.now().millisecondsSinceEpoch}",
        title: title,
        dateIso: dtIso,
        jsonPayload: jsonEncode(payload),
      );

      await ReminderController.save(r);
      await ReminderScheduler.schedule(r);

      print("📌 [BRIDGE] Recordatorio creado: $title @ $dtIso");
    } catch (e) {
      print("❌ Error createReminder: $e");
    }
  }

  // ---------------------------------------
  // Borrar recordatorio por título aproximado
  // ---------------------------------------
  Future<void> _bridgeDeleteReminder(dynamic payload) async {
    if (payload == null) return;

    try {
      final title = payload["title"];
      if (title == null) return;

      final all = await ReminderController.getAll();

      ReminderHive? match;
      for (final r in all) {
        if (r.title.toLowerCase().contains(title.toLowerCase())) {
          match = r;
          break;
        }
      }

      if (match == null) {
        print("⚠ No encontré recordatorio para eliminar: $title");
        return;
      }

      await ReminderController.delete(match.id);
      print("🗑 [BRIDGE] Eliminado: ${match.title}");
    } catch (e) {
      print("❌ Error deleteReminder: $e");
    }
  }
}

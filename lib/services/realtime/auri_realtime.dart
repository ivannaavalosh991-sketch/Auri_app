// lib/services/realtime/auri_realtime.dart
// V6 — Hands-Free + Push-to-Talk + Firebase UID + Reconexión + Anti-Loops + Persistencia

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// 🔥 NEW: Firebase UID
import 'package:firebase_auth/firebase_auth.dart';

// Voice / Audio
import 'package:auri_app/auri/voice/tts_player_stream.dart';
import 'package:auri_app/auri/voice/stt_whisper_online.dart';

// Navegación
import 'package:auri_app/pages/reminders/reminders_page.dart';

// Modelos / Controladores
import 'package:auri_app/models/reminder_hive.dart';
import 'package:auri_app/controllers/reminder/reminder_controller.dart';
import 'package:auri_app/services/reminder_scheduler.dart';

class AuriRealtime {
  AuriRealtime._();
  static final AuriRealtime instance = AuriRealtime._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ============================================================
  // ESTADO GENERAL DE LA CONEXIÓN
  // ============================================================
  WebSocketChannel? _ch;
  bool _connected = false;
  bool _connecting = false;

  bool _contextReady = false;

  Timer? _retryTimer;
  Timer? _heartbeat;

  // Railway host
  static const String _host = "auri-backend-production-ef14.up.railway.app";

  // ============================================================
  // STREAM DEL MICRÓFONO
  // ============================================================
  final StreamController<Uint8List> _micStream =
      StreamController<Uint8List>.broadcast();
  StreamSink<Uint8List> get micSink => _micStream.sink;

  // ============================================================
  // CALLBACKS PARA UI
  // ============================================================
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

  // ============================================================
  // 🟣 HANDS-FREE MODE (persistente)
  // ============================================================
  bool _handsFree = false;
  bool get handsFree => _handsFree;

  Future<void> loadHandsFree() async {
    final prefs = await SharedPreferences.getInstance();
    _handsFree = prefs.getBool("hands_free_mode") ?? false;
    print("🔧 Hands-Free cargado: $_handsFree");
  }

  Future<void> setHandsFree(bool val) async {
    _handsFree = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("hands_free_mode", val);
    print("🔧 Hands-Free actualizado → $val");

    if (val && !STTWhisperOnline.instance.isRecording) {
      await STTWhisperOnline.instance.startRecording();
    }

    if (!val && STTWhisperOnline.instance.isRecording) {
      await STTWhisperOnline.instance.stopRecording();
    }
  }

  // ============================================================
  // CONTEXT READY → habilitar WS
  // ============================================================
  void markContextReady() {
    print("🟢 Context READY — podemos conectar WS");
    _contextReady = true;
  }

  // ============================================================
  // CONEXIÓN WS
  // ============================================================
  Future<void> ensureConnected() async {
    if (_connected) return;
    if (_connecting) return;
    if (_retryTimer != null) return;

    print("⏳ Esperando contextReady…");

    int waited = 0;
    while (!_contextReady && waited < 3000) {
      await Future.delayed(const Duration(milliseconds: 100));
      waited += 100;
    }

    if (!_contextReady) {
      print("❌ No conecté WS: contextReady no llegó");
      return;
    }

    connect();
  }

  Future<void> connect() async {
    if (_connected || _connecting) return;

    _connecting = true;

    print("⏳ Esperando UID de Firebase…");

    // 🔥 Nuevo: espera hasta 2s a que FirebaseAuth tenga usuario
    String? uid;
    int waited = 0;
    while (uid == null && waited < 2000) {
      uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited += 100;
      }
    }

    print("🔑 UID final obtenido para WS: $uid");

    final url = Uri(scheme: "wss", host: _host, path: "/realtime").toString();
    print("🔌 Conectando WS → $url");

    try {
      _ch = WebSocketChannel.connect(Uri.parse(url));

      _connected = true;
      _connecting = false;

      print("🟢 WS conectado correctamente");

      // 🔥 Enviar HELLO con UID correcto
      _sendJson({
        "type": "client_hello",
        "client": "auri_app",
        "version": "1.0.0",
        "firebase_uid": uid, // ← UID ya seguro, nunca null
      });

      // STREAM DE AUDIO
      _micStream.stream.listen((bytes) {
        if (_connected) _ch?.sink.add(bytes);
      });

      // HEARTBEAT
      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(
        const Duration(seconds: 20),
        (_) => _sendJson({"type": "ping"}),
      );

      // Escuchar WS
      _ch!.stream.listen(
        _onWsMessage,
        onDone: _handleClose,
        onError: (err) {
          print("❌ WS Error: $err");
          _handleClose();
        },
      );
    } catch (e) {
      print("❌ Error conectando WS: $e");
      _connected = false;
      _connecting = false;
      _scheduleReconnect();
    }
  }

  // ============================================================
  // CIERRE + RECONEXIÓN
  // ============================================================
  void _handleClose() {
    print("🔌 WS cerrado");

    _connected = false;

    _heartbeat?.cancel();
    _heartbeat = null;

    if (!_connecting) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_retryTimer != null) return;

    print("⛔ Reintentando WS en 3s…");

    _retryTimer = Timer(const Duration(seconds: 3), () async {
      _retryTimer = null;
      if (!_connected && !_connecting && _contextReady) {
        print("🔄 Reintentando WS…");
        connect();
      }
    });
  }

  // ============================================================
  // UTIL PARA ENVIAR JSON
  // ============================================================
  void _sendJson(Map<String, dynamic> map) {
    if (!_connected) return;
    try {
      _ch?.sink.add(jsonEncode(map));
    } catch (_) {}
  }

  // ============================================================
  // COMANDOS AL BACKEND
  // ============================================================
  void startSession() => _sendJson({"type": "start_session"});
  void endAudio() => _sendJson({"type": "audio_end"});
  void sendText(String t) => _sendJson({"type": "text_command", "text": t});

  // ============================================================
  // MANEJADOR DE MENSAJES WS
  // ============================================================
  Future<void> _onWsMessage(dynamic data) async {
    if (data is List<int>) {
      await AuriTtsStreamPlayer.instance.addChunk(Uint8List.fromList(data));
      return;
    }

    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(data);
    } catch (_) {
      print("⚠ JSON inválido");
      return;
    }

    print("📩 WS MSG: $msg");

    switch (msg["type"]) {
      case "pong":
        break;

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
        final thinking = msg["state"] == true;
        for (final f in _onThinking) f(thinking);

        if (!thinking && _handsFree) {
          if (!STTWhisperOnline.instance.isRecording) {
            await STTWhisperOnline.instance.startRecording();
          }
        }
        break;

      case "tts_end":
        await AuriTtsStreamPlayer.instance.finalize();

        if (_handsFree && !STTWhisperOnline.instance.isRecording) {
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

      default:
        print("⚠ Evento desconocido: ${msg["type"]}");
    }
  }

  // ============================================================
  // ACCIONES RECIBIDAS DEL BACKEND
  // ============================================================
  Future<void> _runAction(String? action, dynamic payload) async {
    if (action == null) return;

    switch (action) {
      case "open_reminders_list":
        _openRemindersPage();
        break;

      case "create_reminder":
        await _bridgeCreateReminder(payload);
        break;

      case "delete_reminder":
        await _bridgeDeleteReminder(payload);
        break;

      case "delete_all_reminders":
        await _bridgeDeleteAll();
        break;

      case "delete_category":
        await _bridgeDeleteCategory(payload);
        break;

      case "delete_by_date":
        await _bridgeDeleteByDate(payload);
        break;

      case "edit_reminder":
        await _bridgeEditReminder(payload);
        break;

      case "set_handsfree":
        await setHandsFree(payload["enabled"] == true);
        break;

      default:
        print("⚠ Acción desconocida: $action");
    }
  }

  // ============================================================
  // UI
  // ============================================================
  void _openRemindersPage() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      print("⚠ navigatorKey sin context");
      return;
    }

    Navigator.of(
      ctx,
    ).push(MaterialPageRoute(builder: (_) => const RemindersPage()));
  }

  // ============================================================
  // BRIDGES (Hive + Scheduler)
  // ============================================================
  Future<void> _bridgeCreateReminder(dynamic payload) async {
    if (payload == null) return;
    try {
      final r = ReminderHive(
        id: "${DateTime.now().millisecondsSinceEpoch}",
        title: payload["title"],
        dateIso: payload["datetime"],
        repeats: payload["repeats"] ?? "once",
        tag: (payload["kind"] == "payment")
            ? "payment"
            : payload["kind"] == "birthday"
            ? "birthday"
            : "",
        isAuto: false,
        jsonPayload: jsonEncode(payload),
      );

      await ReminderController.save(r);
      await ReminderScheduler.schedule(r);

      print("📌 [BRIDGE] Creado reminder: ${r.title}");
    } catch (e) {
      print("❌ Error createReminder: $e");
    }
  }

  Future<void> _bridgeDeleteReminder(dynamic payload) async {
    if (payload == null) return;
    try {
      final search = (payload["title"] ?? "").toString().toLowerCase().trim();
      if (search.isEmpty) return;

      final all = await ReminderController.getAll();
      ReminderHive? target;

      for (final r in all) {
        final t = r.title.toLowerCase();
        if (t.contains(search)) {
          target = r;
          break;
        }
      }

      if (target == null) return;

      await ReminderController.delete(target.id);
      print("🗑 [BRIDGE] Eliminado ${target.title}");
    } catch (e) {
      print("❌ Error deleteReminder: $e");
    }
  }

  Future<void> _bridgeDeleteAll() async {
    await ReminderController.overwriteAll([]);
    print("🗑 [BRIDGE] Eliminados TODOS");
  }

  Future<void> _bridgeDeleteCategory(dynamic payload) async {
    if (payload == null) return;

    final category = payload["category"];
    if (category == null) return;

    final all = await ReminderController.getAll();
    final filtered = all.where((r) => r.tag != category).toList();

    await ReminderController.overwriteAll(filtered);
    print("🗑 [BRIDGE] Eliminada categoría: $category");
  }

  Future<void> _bridgeDeleteByDate(dynamic payload) async {
    if (payload == null) return;

    final when = payload["when"];
    if (when == null) return;

    final now = DateTime.now();
    final list = await ReminderController.getAll();
    final filtered = <ReminderHive>[];

    for (final r in list) {
      final dt = DateTime.parse(r.dateIso);
      bool remove = false;

      if (when == "today") {
        remove =
            dt.year == now.year && dt.month == now.month && dt.day == now.day;
      }

      if (when == "tomorrow") {
        final t = now.add(const Duration(days: 1));
        remove = dt.year == t.year && dt.month == t.month && dt.day == t.day;
      }

      if (!remove) filtered.add(r);
    }

    await ReminderController.overwriteAll(filtered);
    print("🗑 [BRIDGE] Eliminados por fecha: $when");
  }

  Future<void> _bridgeEditReminder(dynamic payload) async {
    if (payload == null) return;

    final oldTitle = payload["oldTitle"];
    final newTitle = payload["newTitle"];
    final dt = payload["datetime"];

    if (oldTitle == null || newTitle == null || dt == null) return;

    final all = await ReminderController.getAll();
    ReminderHive? target;

    for (final r in all) {
      if (r.title.toLowerCase() == oldTitle.toLowerCase()) {
        target = r;
        break;
      }
    }

    if (target == null) return;

    final updated = ReminderHive(
      id: target.id,
      title: newTitle,
      dateIso: dt,
      repeats: payload["repeats"] ?? target.repeats,
      tag: target.tag,
      isAuto: target.isAuto,
      jsonPayload: target.jsonPayload,
    );

    await ReminderController.save(updated);
    await ReminderScheduler.schedule(updated);

    print("✏️ [BRIDGE] Editado: $oldTitle → $newTitle");
  }
}

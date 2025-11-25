// lib/services/notification_service.dart

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:auri_app/models/reminder_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String androidChannelId = 'auri_channel';
  static const String androidChannelName = 'Auri Recordatorios';
  static const String androidChannelDesc =
      'Recordatorios automáticos y manuales de Auri';

  bool _initialized = false;

  // ============================================================
  // INIT PÚBLICO (idempotente)
  // ============================================================
  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("🔔 Notificación pulsada: ${details.payload}");
      },
    );

    await _createAndroidChannel();
    await _requestPermissions();

    _initialized = true;
    debugPrint("🔔 NotificationService inicializado");
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  // ============================================================
  // PERMISOS (FCM + locales, Android/iOS)
  // ============================================================
  Future<void> _requestPermissions() async {
    // 1) Permiso de notificaciones para FCM (iOS/Android)
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (e) {
      debugPrint("⚠️ Error pidiendo permiso FCM: $e");
    }

    // 2) Android 13+ → POST_NOTIFICATIONS (local + push)
    try {
      if (Platform.isAndroid) {
        final android = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await android?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint("⚠️ Error pidiendo permiso local (Android): $e");
    }

    // 3) iOS → permisos locales
    try {
      if (Platform.isIOS) {
        final ios = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        await ios?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      debugPrint("⚠️ Error pidiendo permiso local (iOS): $e");
    }
  }

  // ============================================================
  // ANDROID CHANNEL
  // ============================================================
  Future<void> _createAndroidChannel() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        androidChannelId,
        androidChannelName,
        description: androidChannelDesc,
        importance: Importance.max,
      );
      await androidPlugin.createNotificationChannel(channel);
      debugPrint("📡 Canal de notificaciones creado: $androidChannelId");
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================
  int _internalIdFromString(String id) => id.hashCode & 0x7fffffff;

  NotificationDetails _buildDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannelId,
        androidChannelName,
        channelDescription: androidChannelDesc,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  tz.TZDateTime _normalizeDate(DateTime dateTime) {
    final now = tz.TZDateTime.now(tz.local);
    var target = tz.TZDateTime.from(dateTime, tz.local);

    // Si por algún motivo ya pasó, lo muevo unos segundos al futuro
    if (target.isBefore(now)) {
      target = now.add(const Duration(seconds: 5));
    }

    return target;
  }

  // ============================================================
  // TEST NOTIFICATION
  // ============================================================
  Future<void> showTestNotification() async {
    await _ensureInitialized();

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final details = _buildDetails();

    await flutterLocalNotificationsPlugin.show(
      id,
      'Notificación de prueba',
      'Esto es una prueba de Auri 🟣',
      details,
    );
  }

  // ============================================================
  // SCHEDULE: Reminder (manual o auto)
  // ============================================================
  Future<void> scheduleReminder(Reminder reminder) async {
    await _ensureInitialized();

    final details = _buildDetails();
    final tzDate = _normalizeDate(reminder.dateTime);
    final id = _internalIdFromString(reminder.id);

    debugPrint(
      "⏰ Programando reminder [${reminder.id}] "
      "'${reminder.title}' para $tzDate (local=${tz.local.name})",
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      reminder.title,
      reminder.description,
      tzDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminder.id,
    );
  }

  /// Alias para mantener compatibilidad con código antiguo
  Future<void> scheduleReminderNotification(Reminder r) => scheduleReminder(r);

  /// Alias extra por si en algún punto lo usas para manuales
  Future<void> scheduleManualReminder(Reminder r) => scheduleReminder(r);

  // ============================================================
  // SCHEDULE from JSON (AutoReminderService u otros)
  // ============================================================
  Future<void> scheduleFromJson(Map<String, dynamic> jsonData) async {
    await _ensureInitialized();

    final idStr =
        jsonData['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final title = jsonData['title'] ?? 'Recordatorio';
    final dateString = jsonData['date'];
    final repeats = (jsonData['repeats'] ?? 'once').toLowerCase();
    final body = jsonData['body'];

    if (dateString == null) return;
    final parsed = DateTime.tryParse(dateString);
    if (parsed == null) return;

    final details = _buildDetails();
    final internalId = _internalIdFromString(idStr);

    tz.TZDateTime base = _normalizeDate(parsed);
    DateTimeComponents? match;

    switch (repeats) {
      case 'daily':
        match = DateTimeComponents.time;
        break;
      case 'weekly':
        match = DateTimeComponents.dayOfWeekAndTime;
        break;
      case 'monthly':
        match = DateTimeComponents.dayOfMonthAndTime;
        break;
      case 'yearly':
        match = DateTimeComponents.dateAndTime;
        break;
      default:
        match = null;
    }

    debugPrint(
      "📆 scheduleFromJson: id=$idStr title=$title date=$base repeats=$repeats",
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      internalId,
      title,
      body,
      base,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: match,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: idStr,
    );
  }

  // ============================================================
  // CANCEL
  // ============================================================
  Future<void> cancel(int id) async {
    await _ensureInitialized();
    await flutterLocalNotificationsPlugin.cancel(id);
    debugPrint("🗑️ Cancelada notificación con id interno $id");
  }

  Future<void> cancelAll() async {
    await _ensureInitialized();
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint("🧹 Todas las notificaciones locales canceladas");
  }

  Future<void> cancelByStringId(String id) async {
    final internalId = _internalIdFromString(id);
    await cancel(internalId);
  }
}

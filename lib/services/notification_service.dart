import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder_model.dart';

/// Canal de notificaciones
const String notificationChannelId = 'auri_reminders_channel';
const String notificationChannelName = 'Recordatorios de Auri';
const String notificationChannelDescription =
    'Notificaciones para recordatorios personales y pagos.';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ----------------------------------------------------------
  // INIT
  // ----------------------------------------------------------
  Future<void> init() async {
    if (_initialized) return;

    // Timezones
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        debugPrint("📩 Notificación tocada: ${resp.payload}");
      },
    );

    await _requestAndroidNotificationPermission();
    await _createNotificationChannel();

    _initialized = true;
    debugPrint("✅ NotificationService inicializado correctamente.");
  }

  // ----------------------------------------------------------
  // PERMISOS
  // ----------------------------------------------------------
  Future<void> _requestAndroidNotificationPermission() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  // ----------------------------------------------------------
  // CREAR CANAL
  // ----------------------------------------------------------
  Future<void> _createNotificationChannel() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      notificationChannelName,
      description: notificationChannelDescription,
      importance: Importance.max,
      playSound: true,
      showBadge: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 300, 150, 300]),
    );

    await androidPlugin.createNotificationChannel(channel);

    debugPrint("📡 Canal de notificación creado correctamente.");
  }

  // ----------------------------------------------------------
  // DETALLES DE NOTIFICACIÓN  ← ← ← ESTE ES EL MÉTODO CORRECTO
  // ----------------------------------------------------------
  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelName,
        channelDescription: notificationChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );
  }

  // ----------------------------------------------------------
  // PROGRAMAR NOTIFICACIÓN
  // ----------------------------------------------------------
  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!_initialized) await init();
    if (kIsWeb) return;

    final scheduled = tz.TZDateTime.from(reminder.dateTime, tz.local);

    if (scheduled.isBefore(DateTime.now())) {
      debugPrint("⏩ Recordatorio pasado ignorado: ${reminder.title}");
      return;
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        reminder.hashCode,
        reminder.title,
        reminder.title,
        scheduled,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
      );

      debugPrint("🕒 Notificación programada para: $scheduled");
    } catch (e) {
      debugPrint("❌ Error programando notificación: $e");
    }
  }

  // ----------------------------------------------------------
  // CANCELAR
  // ----------------------------------------------------------
  Future<void> cancelReminderNotification(Reminder reminder) async {
    if (!_initialized) await init();
    await flutterLocalNotificationsPlugin.cancel(reminder.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    if (!_initialized) await init();
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // ----------------------------------------------------------
  // ACCESO EXTERNO PARA USAR EN UI
  // ----------------------------------------------------------
  NotificationDetails notificationDetails() => _notificationDetails();
}

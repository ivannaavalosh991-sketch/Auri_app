// lib/services/reminder_scheduler.dart

import 'package:auri_app/models/reminder_hive.dart';
import 'package:auri_app/models/reminder_model.dart';
import 'package:auri_app/services/notification_service.dart';

/// Capa responsable de traducir [ReminderHive] → [Reminder]
/// y programar / cancelar notificaciones locales.
class ReminderScheduler {
  static final _notifier = NotificationService();

  static int _id(ReminderHive r) => r.id.hashCode & 0x7fffffff;
  static int _idFromString(String id) => id.hashCode & 0x7fffffff;

  // -------------------------------------------------------------
  // PROGRAMAR UN SOLO RECORDATORIO
  // -------------------------------------------------------------
  static Future<void> schedule(ReminderHive r) async {
    // Cancelamos cualquier notificación anterior con este ID
    await _notifier.cancel(_id(r));

    final date = DateTime.tryParse(r.dateIso);
    if (date == null) return;

    // No programar si ya es pasado (por seguridad extra)
    if (date.isBefore(DateTime.now())) return;

    final model = Reminder(
      id: r.id,
      title: r.title,
      dateTime: date,
      description: r.tag.isNotEmpty ? r.tag : null,
      isAuto: r.isAuto,
    );

    // Usa la API unificada del NotificationService
    await _notifier.scheduleReminder(model);
  }

  // -------------------------------------------------------------
  // PROGRAMAR VARIOS RECORDATORIOS
  // -------------------------------------------------------------
  static Future<void> scheduleAll(List<ReminderHive> list) async {
    for (final r in list) {
      await schedule(r);
    }
  }

  // -------------------------------------------------------------
  // CANCELAR
  // -------------------------------------------------------------
  static Future<void> cancel(ReminderHive r) async {
    await _notifier.cancel(_id(r));
  }

  static Future<void> cancelById(String id) async {
    await _notifier.cancel(_idFromString(id));
  }

  static Future<void> cancelAllFor(List<ReminderHive> list) async {
    for (final r in list) {
      await cancel(r);
    }
  }
}

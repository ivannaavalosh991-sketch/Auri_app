// lib/services/reminder_generator.dart

import 'package:uuid/uuid.dart';
import 'package:auri_app/models/reminder_hive.dart';
import 'auto_reminder_service.dart';

class ReminderGeneratorV7 {
  static final _uuid = const Uuid();

  /// Convierte los ReminderAuto generados por AutoReminderService
  /// en ReminderHive listos para almacenarse en Hive.
  static List<ReminderHive> convert(List<ReminderAuto> list) {
    return list.map((r) {
      return ReminderHive(
        id: _uuid.v4(),
        title: r.title.trim(),
        dateIso: r.date.toIso8601String(),
        repeats: "once",
        tag: r.isPayment
            ? "payment"
            : r.isBirthday
            ? "birthday"
            : "",
        isAuto: true,
        jsonPayload: "{}", // reservado para expansión futura
      );
    }).toList();
  }
}

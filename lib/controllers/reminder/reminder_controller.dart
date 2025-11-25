// lib/controllers/reminder/reminder_controller.dart

import 'package:hive/hive.dart';
import 'package:auri_app/models/reminder_hive.dart';
import 'package:auri_app/services/cleanup_service_v7_hive.dart';
import 'package:auri_app/services/reminder_scheduler.dart';

class ReminderController {
  static const String boxName = "remindersBox";

  static Future<Box<ReminderHive>> _open() async {
    return await Hive.openBox<ReminderHive>(boxName);
  }

  /// Obtiene todos los recordatorios limpios
  static Future<List<ReminderHive>> getAll() async {
    final box = await _open();
    final list = box.values.toList();
    final cleaned = CleanupServiceHiveV7.clean(list, DateTime.now());
    return cleaned;
  }

  /// Guarda un recordatorio manual
  static Future<void> save(ReminderHive r) async {
    final box = await _open();
    await box.put(r.id, r);
    await ReminderScheduler.schedule(r);
  }

  /// Reescribe toda la caja después de auto-generación
  static Future<void> overwriteAll(List<ReminderHive> list) async {
    final box = await _open();
    await box.clear();

    for (final r in list) {
      await box.put(r.id, r);
      await ReminderScheduler.schedule(r);
    }
  }

  static Future<void> delete(String id) async {
    final box = await _open();
    await box.delete(id);
  }
}

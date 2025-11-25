import 'package:hive/hive.dart';
import 'package:auri_app/models/reminder_hive.dart';
import 'package:auri_app/services/reminder_scheduler.dart';

import 'package:auri_app/services/cleanup_service_v7_hive.dart';

class ReminderController {
  static Box<ReminderHive> _box() => Hive.box<ReminderHive>('reminders');

  // -------------------------------------------------------------
  // OBTENER TODOS (ya limpios y ordenados)
  // -------------------------------------------------------------
  static Future<List<ReminderHive>> getAll() async {
    final box = _box();
    final now = DateTime.now();

    final list = box.values.cast<ReminderHive>().toList();
    final cleaned = CleanupServiceHiveV7.clean(list, now);

    if (cleaned.length != list.length) {
      await _persist(cleaned);
    }

    return cleaned;
  }

  // -------------------------------------------------------------
  // GUARDAR / ACTUALIZAR
  // -------------------------------------------------------------
  static Future<void> save(ReminderHive r) async {
    final box = _box();
    await box.put(r.id, r);

    final now = DateTime.now();
    final list = box.values.cast<ReminderHive>().toList();
    final cleaned = CleanupServiceHiveV7.clean(list, now);

    await _persist(cleaned);
  }

  // -------------------------------------------------------------
  // ELIMINAR
  // -------------------------------------------------------------
  static Future<void> delete(String id) async {
    final box = _box();
    await box.delete(id);

    final now = DateTime.now();
    final list = box.values.cast<ReminderHive>().toList();
    final cleaned = CleanupServiceHiveV7.clean(list, now);

    await _persist(cleaned);
  }

  // -------------------------------------------------------------
  // PERSISTIR LISTA LIMPIA
  // -------------------------------------------------------------
  static Future<void> _persist(List<ReminderHive> list) async {
    final box = _box();
    await box.clear();
    for (final r in list) {
      await box.put(r.id, r);
    }
  }

  // -------------------------------------------------------------
  // OVERWRITE ALL (para Survey)  ⭐ NUEVO ⭐
  // -------------------------------------------------------------
  static Future<void> overwriteAll(List<ReminderHive> list) async {
    final box = _box();

    // 1. Limpiamos duplicados y pasados
    final cleaned = CleanupServiceHiveV7.clean(list, DateTime.now());

    // 2. Reescribimos TODO desde cero
    await box.clear();

    for (final r in cleaned) {
      await box.put(r.id, r);
    }

    // 3. Programar todas las notificaciones nuevamente
    for (final r in cleaned) {
      final date = DateTime.tryParse(r.dateIso);
      if (date != null && date.isAfter(DateTime.now())) {
        await ReminderScheduler.schedule(r);
      }
    }
  }
}

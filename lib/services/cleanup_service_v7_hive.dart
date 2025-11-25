// lib/services/cleanup_service_v7_hive.dart

import 'package:auri_app/models/reminder_hive.dart';

class CleanupServiceHiveV7 {
  /// Limpieza de recordatorios basada en la lógica V7 original.
  /// - Elimina vencidos
  /// - Evita duplicados exactos
  /// - Normaliza títulos
  /// - Elimina "Pronto" huérfanos
  /// - Colapsa pagos y cumpleaños duplicados por mes/año
  /// - Ordena por fecha
  static List<ReminderHive> clean(List<ReminderHive> input, DateTime now) {
    // -------------------------------------------------------
    // 1) eliminar vencidos
    // -------------------------------------------------------
    final noPast = input.where((r) {
      DateTime? date;
      try {
        date = DateTime.parse(r.dateIso);
      } catch (_) {
        return false;
      }
      return date.isAfter(now);
    }).toList();

    // -------------------------------------------------------
    // 2) evitar duplicados exactos (misma fecha + título + tag)
    // -------------------------------------------------------
    final byKey = <String, ReminderHive>{};

    for (final r in noPast) {
      final key = "${r.title.trim()}_${r.dateIso}_${r.tag}";
      byKey[key] = r; // conserva el último con esa clave
    }

    final unique = byKey.values.toList();

    // -------------------------------------------------------
    // 3) normalización de títulos
    // -------------------------------------------------------
    final normalized = <ReminderHive>[];

    for (final r in unique) {
      normalized.add(_normalize(r));
    }

    // -------------------------------------------------------
    // 4) eliminar PRONTO incorrectos (que no tengan evento principal)
    // -------------------------------------------------------
    normalized.removeWhere((r) {
      final titleLower = r.title.toLowerCase();
      if (!titleLower.startsWith("pronto")) return false;

      final originalTitle = r.title.replaceFirst("Pronto: ", "");

      return !normalized.any(
        (x) => x.title == originalTitle && _date(x).isAfter(_date(r)),
      );
    });

    // -------------------------------------------------------
    // 5) eliminar pagos generados dos veces (mismo mes)
    //    Se mantiene:
    //      - 1 "Pronto: Pago X" (si aplica)
    //      - 1 "Pago X" por mes
    // -------------------------------------------------------
    final seenPayments = <String, ReminderHive>{};

    normalized.removeWhere((r) {
      if (r.tag != "payment") return false;

      final d = _date(r);
      final key = "${r.title}_${d.year}_${d.month}";

      if (seenPayments.containsKey(key)) {
        return true; // ya vimos ese pago en ese mes
      }

      seenPayments[key] = r;
      return false;
    });

    // -------------------------------------------------------
    // 6) eliminar cumpleaños duplicados (mismo año)
    //    Igual que pagos: se permite "Pronto:" + "Cumpleaños:"
    // -------------------------------------------------------
    final seenBirthdays = <String, ReminderHive>{};

    normalized.removeWhere((r) {
      if (r.tag != "birthday") return false;

      final d = _date(r);
      final key = "${r.title}_${d.year}";

      if (seenBirthdays.containsKey(key)) {
        return true;
      }

      seenBirthdays[key] = r;
      return false;
    });

    // -------------------------------------------------------
    // 7) ordenar por fecha ascendente
    // -------------------------------------------------------
    normalized.sort((a, b) {
      return _date(a).compareTo(_date(b));
    });

    return normalized;
  }

  /// Normalización básica de títulos para evitar casos raros:
  /// - "Pago Pago agua" → "Pago agua"
  /// - "Cumpleaños pronto: Usuario" → "Pronto: Cumpleaños: Usuario"
  /// - "Pronto: Pronto: X" → "Pronto: X"
  static ReminderHive _normalize(ReminderHive r) {
    String title = r.title.trim();

    // 1. Corregir “Pago Pago agua”
    title = title.replaceAll("Pago Pago", "Pago");

    // 2. Corregir “Cumpleaños pronto: Usuario”
    title = title.replaceAll("Cumpleaños pronto:", "Pronto: Cumpleaños:");

    // 3. Normalizar “Pronto: Pronto: X”
    if (title.startsWith("Pronto: Pronto")) {
      title = title.replaceFirst("Pronto: Pronto:", "Pronto:");
    }

    return ReminderHive(
      id: r.id,
      title: title,
      dateIso: r.dateIso,
      repeats: r.repeats,
      tag: r.tag,
      isAuto: r.isAuto,
      jsonPayload: r.jsonPayload,
    );
  }

  static DateTime _date(ReminderHive r) => DateTime.parse(r.dateIso).toLocal();
}

// lib/services/auto_reminder_service.dart

import 'package:auri_app/pages/survey/models/survey_models.dart';
import 'package:auri_app/models/reminder_model.dart';

class AutoReminderServiceV7 {
  /// Genera TODOS los recordatorios automáticos (pagos, cumpleaños, agenda).
  static List<ReminderAuto> generateAll({
    required List<PaymentEntry> basicPayments,
    required List<PaymentEntry> extraPayments,
    required List<BirthdayEntry> birthdays,
    required int anticipationDays,
    required List<UserTask> tasks,
    required DateTime now,
  }) {
    final list = <ReminderAuto>[];

    // 1) Pagos (básicos + extras)
    list.addAll(
      _generateMonthly(
        [...basicPayments, ...extraPayments],
        anticipationDays,
        now,
      ),
    );

    // 2) Cumpleaños (usuario, pareja, extras)
    list.addAll(_generateBirthdays(birthdays, anticipationDays, now));

    // 3) Agenda semanal
    list.add(_generateWeeklyAgenda(tasks, now));

    return list;
  }

  /// (Opcional) Si en algún momento quieres convertir directamente a [Reminder].
  static List<Reminder> mapToReminders(List<ReminderAuto> autos) {
    return autos
        .map(
          (a) => Reminder(
            id: "${a.title}_${a.date.toIso8601String()}",
            title: a.title,
            description: a.isPayment
                ? "Recordatorio de pago"
                : (a.isBirthday ? "Cumpleaños" : "Recordatorio automático"),
            dateTime: a.date,
          ),
        )
        .toList();
  }

  // ================================================================
  // PAGOS MENSUALES
  // ================================================================
  static List<ReminderAuto> _generateMonthly(
    List<PaymentEntry> payments,
    int anticipation,
    DateTime now,
  ) {
    final out = <ReminderAuto>[];

    for (final p in payments) {
      if (p.day <= 0) continue;

      final title = "Pago ${p.name}".trim();

      final thisMonth = _safeDate(now.year, now.month, p.day);
      final nextMonth = _safeDate(
        now.month == 12 ? now.year + 1 : now.year,
        now.month == 12 ? 1 : now.month + 1,
        p.day,
      );

      // --- Este mes ---
      if (thisMonth.isAfter(now)) {
        out.add(ReminderAuto(title, thisMonth, isPayment: true));

        if (anticipation > 0) {
          final soon = thisMonth.subtract(Duration(days: anticipation));
          if (soon.isAfter(now)) {
            out.add(ReminderAuto("Pronto: $title", soon, isPayment: true));
          }
        }
      }

      // --- Próximo mes ---
      if (nextMonth.isAfter(now)) {
        out.add(ReminderAuto(title, nextMonth, isPayment: true));

        if (anticipation > 0) {
          final soon = nextMonth.subtract(Duration(days: anticipation));
          if (soon.isAfter(now)) {
            out.add(ReminderAuto("Pronto: $title", soon, isPayment: true));
          }
        }
      }
    }

    return out;
  }

  // ================================================================
  // CUMPLEAÑOS
  // ================================================================
  static List<ReminderAuto> _generateBirthdays(
    List<BirthdayEntry> list,
    int anticipation,
    DateTime now,
  ) {
    final out = <ReminderAuto>[];

    // 👇 Horizonte: solo generamos cumpleaños que estén
    // dentro de los próximos 60 días (aprox. 2 meses).
    const maxDaysAhead = 60;

    for (final b in list) {
      if (b.day <= 0 || b.month <= 0) continue;

      final title = "Cumpleaños: ${b.name}".trim();
      final next = _nextAnnual(b, now);

      final diff = next.difference(now).inDays;
      if (diff < 0 || diff > maxDaysAhead) {
        // Muy lejos todavía, no generamos nada aún.
        continue;
      }

      // Día del cumple
      out.add(ReminderAuto(title, next, isBirthday: true));

      // "Pronto" antes del cumple
      if (anticipation > 0) {
        final soon = next.subtract(Duration(days: anticipation));
        if (soon.isAfter(now)) {
          out.add(ReminderAuto("Pronto: $title", soon, isBirthday: true));
        }
      }
    }

    return out;
  }

  // ================================================================
  // AGENDA SEMANAL
  // ================================================================
  static ReminderAuto _generateWeeklyAgenda(
    List<UserTask> tasks,
    DateTime now,
  ) {
    if (tasks.isEmpty) {
      final next = _nextWeekday(now, DateTime.monday, hour: 8);
      return ReminderAuto("Revisión semanal automática", next);
    }

    tasks.sort((a, b) => a.date.compareTo(b.date));
    return ReminderAuto("Revisión semanal automática", tasks.first.date);
  }

  // ================================================================
  // HELPERS DE FECHA
  // ================================================================
  static DateTime _nextAnnual(BirthdayEntry b, DateTime now) {
    final thisYear = DateTime(now.year, b.month, b.day, 9);
    if (thisYear.isAfter(now)) return thisYear;
    return DateTime(now.year + 1, b.month, b.day, 9);
  }

  static DateTime _nextWeekday(
    DateTime from,
    int weekday, {
    int hour = 9,
    int minute = 0,
  }) {
    var diff = (weekday - from.weekday) % 7;
    if (diff == 0) diff = 7;
    return DateTime(from.year, from.month, from.day + diff, hour, minute);
  }

  static DateTime _safeDate(int year, int month, int day) {
    final max = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > max ? max : day, 9);
  }
}

// -----------------------------------------------------------------
// MODELOS INTERNOS
// -----------------------------------------------------------------

class ReminderAuto {
  final String title;
  final DateTime date;
  final bool isPayment;
  final bool isBirthday;

  ReminderAuto(
    this.title,
    this.date, {
    this.isPayment = false,
    this.isBirthday = false,
  });
}

class UserTask {
  final DateTime date;
  UserTask(this.date);
}

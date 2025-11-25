// lib/services/auto_reminder_service.dart

import 'package:auri_app/pages/survey/models/survey_models.dart';

class AutoReminderServiceV7 {
  static List<ReminderAuto> generateAll({
    required MonthlyPayments payments,
    required BirthdayData birthdays,
    required ReminderSettings settings,
    required List<UserTask> tasks,
    required DateTime now,

    // NUEVO: pagos y cumpleaños extra
    List<ExtraPaymentEntry> extraPayments = const [],
    List<ExtraBirthdayEntry> extraBirthdays = const [],
  }) {
    final list = <ReminderAuto>[];

    // 1. Pagos mensuales base
    list.addAll(_generateMonthly(payments, settings.anticipationDays, now));

    // 2. Pagos adicionales (suscripciones)
    list.addAll(
      _generateExtraPayments(extraPayments, settings.anticipationDays, now),
    );

    // 3. Cumpleaños base (usuario / pareja)
    list.addAll(_generateBirthdays(birthdays, settings.anticipationDays, now));

    // 4. Cumpleaños extra
    list.addAll(
      _generateExtraBirthdays(extraBirthdays, settings.anticipationDays, now),
    );

    // 5. Agenda semanal
    list.add(_generateWeeklyAgenda(tasks, now));

    return list;
  }

  // -------------------------- PAGOS BASE --------------------------
  static List<ReminderAuto> _generateMonthly(
    MonthlyPayments p,
    int anticipation,
    DateTime now,
  ) {
    final out = <ReminderAuto>[];

    final items = {
      "Pago agua": p.waterDay,
      "Pago luz": p.lightDay,
      "Pago internet": p.internetDay,
      "Pago teléfono": p.phoneDay,
      "Pago renta": p.rentDay,
    };

    items.forEach((title, day) {
      if (day <= 0) return;

      final thisMonth = _safeDate(now.year, now.month, day);
      final nextMonth = _safeDate(
        now.month == 12 ? now.year + 1 : now.year,
        now.month == 12 ? 1 : now.month + 1,
        day,
      );

      // Este mes
      if (thisMonth.isAfter(now)) {
        out.add(ReminderAuto(title, thisMonth, isPayment: true));

        if (anticipation > 0) {
          final soon = thisMonth.subtract(Duration(days: anticipation));
          if (soon.isAfter(now)) {
            out.add(ReminderAuto("Pronto: $title", soon, isPayment: true));
          }
        }
      }

      // Próximo mes
      if (nextMonth.isAfter(now)) {
        out.add(ReminderAuto(title, nextMonth, isPayment: true));

        if (anticipation > 0) {
          final soon = nextMonth.subtract(Duration(days: anticipation));
          if (soon.isAfter(now)) {
            out.add(ReminderAuto("Pronto: $title", soon, isPayment: true));
          }
        }
      }
    });

    return out;
  }

  // -------------------------- PAGOS EXTRA --------------------------
  static List<ReminderAuto> _generateExtraPayments(
    List<ExtraPaymentEntry> list,
    int anticipation,
    DateTime now,
  ) {
    final out = <ReminderAuto>[];

    for (final p in list) {
      if (p.day <= 0) continue;

      final thisMonth = _safeDate(now.year, now.month, p.day);
      final nextMonth = _safeDate(
        now.month == 12 ? now.year + 1 : now.year,
        now.month == 12 ? 1 : now.month + 1,
        p.day,
      );

      final title = "Pago ${p.name}";

      if (thisMonth.isAfter(now)) {
        out.add(ReminderAuto(title, thisMonth, isPayment: true));

        if (anticipation > 0) {
          final soon = thisMonth.subtract(Duration(days: anticipation));
          if (soon.isAfter(now)) {
            out.add(ReminderAuto("Pronto: $title", soon, isPayment: true));
          }
        }
      }

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

  // -------------------------- CUMPLEAÑOS BASE --------------------------
  static List<ReminderAuto> _generateBirthdays(
    BirthdayData b,
    int anticipation,
    DateTime now,
  ) {
    final out = <ReminderAuto>[];

    final data = {
      "Cumpleaños: Usuario": b.userBirthday,
      "Cumpleaños: Pareja": b.partnerBirthday,
    };

    data.forEach((title, date) {
      if (date == null) return;

      final next = _nextAnnual(date, now);
      out.add(ReminderAuto(title, next, isBirthday: true));

      if (anticipation > 0) {
        final soon = next.subtract(Duration(days: anticipation));
        if (soon.isAfter(now)) {
          out.add(ReminderAuto("Pronto: $title", soon, isBirthday: true));
        }
      }
    });

    return out;
  }

  // -------------------------- CUMPLEAÑOS EXTRA --------------------------
  static List<ReminderAuto> _generateExtraBirthdays(
    List<ExtraBirthdayEntry> list,
    int anticipation,
    DateTime now,
  ) {
    final out = <ReminderAuto>[];

    for (final b in list) {
      final base = DateTime(now.year, b.month, b.day, 9);
      final next = _nextAnnual(base, now);
      final title = "Cumpleaños: ${b.name}";

      out.add(ReminderAuto(title, next, isBirthday: true));

      if (anticipation > 0) {
        final soon = next.subtract(Duration(days: anticipation));
        if (soon.isAfter(now)) {
          out.add(ReminderAuto("Pronto: $title", soon, isBirthday: true));
        }
      }
    }

    return out;
  }

  // -------------------------- AGENDA SEMANAL --------------------------
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

  // -------------------------- HELPERS --------------------------
  static DateTime _nextAnnual(DateTime birth, DateTime now) {
    final thisYear = DateTime(now.year, birth.month, birth.day, 9);
    if (thisYear.isAfter(now)) return thisYear;

    return DateTime(now.year + 1, birth.month, birth.day, 9);
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

// ---------------------------------------------------------------------------
// MODELOS
// ---------------------------------------------------------------------------

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

class MonthlyPayments {
  final int waterDay, lightDay, internetDay, phoneDay, rentDay;

  MonthlyPayments({
    required this.waterDay,
    required this.lightDay,
    required this.internetDay,
    required this.phoneDay,
    required this.rentDay,
  });

  factory MonthlyPayments.empty() => MonthlyPayments(
    waterDay: 0,
    lightDay: 0,
    internetDay: 0,
    phoneDay: 0,
    rentDay: 0,
  );
}

class BirthdayData {
  final DateTime? userBirthday;
  final DateTime? partnerBirthday;

  BirthdayData({required this.userBirthday, required this.partnerBirthday});
}

class ReminderSettings {
  final int anticipationDays;

  ReminderSettings({required this.anticipationDays});
}

class UserTask {
  final DateTime date;

  UserTask(this.date);
}

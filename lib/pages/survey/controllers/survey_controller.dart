// lib/pages/survey/controller/survey_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/survey_models.dart';
import '../storage/survey_storage.dart';

// 💜 Auto recordatorios V7.5
import 'package:auri_app/services/auto_reminder_service.dart';
import 'package:auri_app/services/reminder_generator.dart';
import 'package:auri_app/services/reminder_scheduler.dart';
import 'package:auri_app/storage/reminder_storage.dart';

class SurveyController {
  //---------------------------------------------------------------------------
  // TEXT FIELDS
  //---------------------------------------------------------------------------
  final name = TextEditingController();
  final occupation = TextEditingController();
  final city = TextEditingController();

  final wakeUp = TextEditingController();
  final sleep = TextEditingController();

  final reminderAdvance = TextEditingController();

  // cumpleaños del usuario (formato visual "dd/MM")
  final userBirthday = TextEditingController();

  //---------------------------------------------------------------------------
  // SWITCHES
  //---------------------------------------------------------------------------
  bool wantsWeeklyAgenda = false;

  bool hasClasses = false;
  bool hasExams = false;
  bool wantsPaymentReminders = false;

  bool hasPartner = false;
  bool wantsFriendBirthdays = false;

  //---------------------------------------------------------------------------
  // UI TEXT FIELDS (legacy)
  //---------------------------------------------------------------------------
  final classesInfo = TextEditingController();
  final examsInfo = TextEditingController();

  final waterPayment = TextEditingController();
  final electricPayment = TextEditingController();
  final internetPayment = TextEditingController();
  final phonePayment = TextEditingController();
  final rentPayment = TextEditingController();

  final partnerBirthday = TextEditingController();
  final familyBirthdays = TextEditingController();
  final friendBirthdays = TextEditingController();

  //---------------------------------------------------------------------------
  // STRUCTURED MODELS
  //---------------------------------------------------------------------------
  List<ClassEntry> classes = [];
  List<ExamEntry> exams = [];
  List<ActivityEntry> activities = [];
  List<PaymentEntry> payments = [];
  List<BirthdayEntry> birthdays = [];

  // NUEVO V2.0: pagos y cumpleaños extra (estructurados)
  List<ExtraPaymentEntry> extraPayments = [];
  List<ExtraBirthdayEntry> extraBirthdays = [];

  bool loaded = false;

  //---------------------------------------------------------------------------
  // LOAD
  //---------------------------------------------------------------------------
  Future<void> load() async {
    final data = await SurveyStorage.loadSurvey();
    if (data == null) {
      loaded = true;
      return;
    }

    // PERFIL
    name.text = data.profile.name;
    occupation.text = data.profile.occupation;
    city.text = data.profile.city;

    // RUTINA
    wakeUp.text = data.routine.wakeUpTime;
    sleep.text = data.routine.sleepTime;

    // PREFERENCIAS
    reminderAdvance.text = data.preferences.reminderAdvance;
    wantsWeeklyAgenda = data.preferences.wantsWeeklyAgenda;

    // MODELOS
    classes = data.classes;
    exams = data.exams;
    payments = data.payments;
    birthdays = data.birthdays;
    activities = data.activities;

    // NUEVO: cargar estructuras extra (si existen)
    extraPayments = data.extraPayments;
    extraBirthdays = data.extraBirthdays;

    // SYNC UI FIELDS
    hasClasses = classes.isNotEmpty;
    classesInfo.text = _classesToMultiline(classes);

    hasExams = exams.isNotEmpty;
    examsInfo.text = _examsToMultiline(exams);

    wantsPaymentReminders = payments.isNotEmpty;
    _fillPaymentFields(payments);

    _fillBirthdayFields(birthdays);

    loaded = true;
  }

  //---------------------------------------------------------------------------
  // MODELS → TEXT
  //---------------------------------------------------------------------------
  String _classesToMultiline(List<ClassEntry> list) {
    if (list.isEmpty) return "";
    return list.map((c) => "${c.day} ${c.time} - ${c.name}").join('\n');
  }

  String _examsToMultiline(List<ExamEntry> list) {
    if (list.isEmpty) return "";
    return list.map((e) => "${e.date} ${e.time} - ${e.name}").join('\n');
  }

  void _fillPaymentFields(List<PaymentEntry> list) {
    PaymentEntry _find(String keyword) {
      return list.firstWhere(
        (e) => e.name.toLowerCase().contains(keyword),
        orElse: () => PaymentEntry(name: "", day: 0, time: ""),
      );
    }

    final agua = _find("agua");
    if (agua.name.isNotEmpty) waterPayment.text = agua.day.toString();

    final luz = _find("luz");
    if (luz.name.isNotEmpty) electricPayment.text = luz.day.toString();

    final internet = _find("internet");
    if (internet.name.isNotEmpty) {
      internetPayment.text = internet.day.toString();
    }

    final tel = _find("tel");
    if (tel.name.isNotEmpty) phonePayment.text = tel.day.toString();

    final renta = _find("renta");
    if (renta.name.isNotEmpty) rentPayment.text = renta.day.toString();
  }

  void _fillBirthdayFields(List<BirthdayEntry> list) {
    // Usuario
    final me = list.firstWhere(
      (e) => e.name.toLowerCase() == "usuario",
      orElse: () => BirthdayEntry(name: "", day: 0, month: 0),
    );
    if (me.name.isNotEmpty) {
      userBirthday.text =
          "${me.day.toString().padLeft(2, '0')}/${me.month.toString().padLeft(2, '0')}";
    }

    // Pareja
    final partner = list.firstWhere(
      (e) => e.name.toLowerCase() == "pareja",
      orElse: () => BirthdayEntry(name: "", day: 0, month: 0),
    );

    if (partner.name.isNotEmpty) {
      hasPartner = true;
      partnerBirthday.text =
          "${partner.day.toString().padLeft(2, '0')}/${partner.month.toString().padLeft(2, '0')}";
    }

    final fam = <String>[];
    final friends = <String>[];

    for (final b in list) {
      final lname = b.name.toLowerCase();
      if (lname == "usuario" || lname == "pareja") continue;

      final date =
          "${b.day.toString().padLeft(2, '0')}/${b.month.toString().padLeft(2, '0')}";

      if (lname.contains("mam") ||
          lname.contains("pap") ||
          lname.contains("herman") ||
          lname.contains("tío") ||
          lname.contains("tio") ||
          lname.contains("abu")) {
        fam.add("${b.name} - $date");
      } else {
        friends.add("${b.name} - $date");
      }
    }

    familyBirthdays.text = fam.join('\n');
    friendBirthdays.text = friends.join('\n');
    wantsFriendBirthdays = friends.isNotEmpty;
  }

  //---------------------------------------------------------------------------
  // TEXT → MODELS
  //---------------------------------------------------------------------------
  List<ClassEntry> _buildClasses() {
    if (!hasClasses) return [];
    final lines = classesInfo.text.trim().split('\n');

    return lines.where((l) => l.trim().isNotEmpty).map((line) {
      final parts = line.split('-');
      if (parts.length < 2) {
        return ClassEntry(name: line.trim(), day: "Lunes", time: "08:00");
      }

      final left = parts[0].trim();
      final name = parts[1].trim();

      final tokens = left.split(' ');
      final day = tokens.isNotEmpty ? tokens[0] : "Lunes";
      final time = tokens.length >= 2 ? tokens[1] : "09:00";

      return ClassEntry(name: name, day: day, time: time);
    }).toList();
  }

  List<ExamEntry> _buildExams() {
    if (!hasExams) return [];
    final lines = examsInfo.text.trim().split('\n');

    return lines.where((l) => l.trim().isNotEmpty).map((line) {
      final parts = line.split('-');
      final name = parts.length >= 2 ? parts[1].trim() : "Examen";

      final left = parts[0].trim();
      final tokens = left.split(' ');

      final date = tokens.isNotEmpty ? tokens[0] : "2025-01-01";
      final time = tokens.length >= 2 ? tokens[1] : "09:00";

      return ExamEntry(name: name, date: date, time: time);
    }).toList();
  }

  List<PaymentEntry> _buildPayments() {
    if (!wantsPaymentReminders) return [];

    int parseDay(String s) {
      final v = int.tryParse(s.trim());
      if (v == null || v < 1) return 1;
      if (v > 31) return 31;
      return v;
    }

    final list = <PaymentEntry>[];

    void add(String name, TextEditingController c) {
      if (c.text.trim().isNotEmpty) {
        list.add(
          PaymentEntry(name: name, day: parseDay(c.text), time: "09:00"),
        );
      }
    }

    add("Pago agua", waterPayment);
    add("Pago luz", electricPayment);
    add("Pago internet", internetPayment);
    add("Pago teléfono", phonePayment);
    add("Pago renta", rentPayment);

    return list;
  }

  List<BirthdayEntry> _buildBirthdays() {
    final result = <BirthdayEntry>[];

    int d(String x) => int.tryParse(x) ?? 1;

    String? parseDate(String s) {
      final m = RegExp(r'(\d{1,2})[\/\-](\d{1,2})').firstMatch(s);
      return m == null ? null : "${m.group(1)}/${m.group(2)}";
    }

    // Usuario
    if (userBirthday.text.trim().isNotEmpty) {
      final raw = parseDate(userBirthday.text.trim());
      if (raw != null) {
        final p = raw.split('/');
        result.add(
          BirthdayEntry(name: "Usuario", day: d(p[0]), month: d(p[1])),
        );
      }
    }

    // Pareja
    if (hasPartner && partnerBirthday.text.trim().isNotEmpty) {
      final raw = parseDate(partnerBirthday.text.trim());
      if (raw != null) {
        final p = raw.split('/');
        result.add(BirthdayEntry(name: "Pareja", day: d(p[0]), month: d(p[1])));
      }
    }

    // Familia
    for (final line in familyBirthdays.text.split('\n')) {
      final l = line.trim();
      if (l.isEmpty) continue;

      final parts = l.split('-');
      if (parts.length >= 2) {
        final name = parts[0].trim();
        final raw = parseDate(parts[1].trim());
        if (raw != null) {
          final p = raw.split('/');
          result.add(BirthdayEntry(name: name, day: d(p[0]), month: d(p[1])));
        }
      }
    }

    // Amigos
    if (wantsFriendBirthdays) {
      for (final line in friendBirthdays.text.split('\n')) {
        final l = line.trim();
        if (l.isEmpty) continue;

        final parts = l.split('-');
        if (parts.length >= 2) {
          final name = parts[0].trim();
          final raw = parseDate(parts[1].trim());
          if (raw != null) {
            final p = raw.split('/');
            result.add(BirthdayEntry(name: name, day: d(p[0]), month: d(p[1])));
          }
        }
      }
    }

    return result;
  }

  //---------------------------------------------------------------------------
  // BUILD FINAL MODEL
  //---------------------------------------------------------------------------
  SurveyData toSurvey() {
    final builtClasses = _buildClasses();
    final builtExams = _buildExams();
    final builtPayments = _buildPayments();
    final builtBirthdays = _buildBirthdays();

    return SurveyData(
      profile: UserProfile(
        name: name.text.trim(),
        occupation: occupation.text.trim(),
        city: city.text.trim(),
      ),
      routine: UserRoutine(
        wakeUpTime: wakeUp.text.trim(),
        sleepTime: sleep.text.trim(),
      ),
      preferences: UserPreferences(
        reminderAdvance: reminderAdvance.text.trim(),
        wantsWeeklyAgenda: wantsWeeklyAgenda,
      ),
      classes: builtClasses,
      exams: builtExams,
      activities: activities,
      payments: builtPayments,
      birthdays: builtBirthdays,

      // V2.0: de momento se mantienen como listas independientes
      // que podrán llenarse desde una UI más avanzada.
      extraPayments: extraPayments,
      extraBirthdays: extraBirthdays,
    );
  }

  //---------------------------------------------------------------------------
  // AUTO-REMINDERS V7.5 HELPERS
  //---------------------------------------------------------------------------
  MonthlyPayments _toMonthlyPayments(SurveyData data) {
    final p = data.payments;

    int getDayByName(String keyword) {
      final f = p.firstWhere(
        (e) => e.name.toLowerCase().contains(keyword),
        orElse: () => PaymentEntry(name: "", day: 0, time: ""),
      );
      return f.day;
    }

    return MonthlyPayments(
      waterDay: getDayByName("agua"),
      lightDay: getDayByName("luz"),
      internetDay: getDayByName("internet"),
      phoneDay: getDayByName("tel"),
      rentDay: getDayByName("renta"),
    );
  }

  BirthdayData _toBirthdayData(SurveyData data) {
    final list = data.birthdays;

    DateTime? findExact(String keyword) {
      final f = list.firstWhere(
        (e) => e.name.toLowerCase() == keyword,
        orElse: () => BirthdayEntry(name: "", day: 0, month: 0),
      );
      if (f.day == 0) return null;
      final now = DateTime.now();
      return DateTime(now.year, f.month, f.day, 9, 0);
    }

    return BirthdayData(
      userBirthday: findExact("usuario"),
      partnerBirthday: findExact("pareja"),
    );
  }

  List<UserTask> _toUserTasks(SurveyData data) {
    final out = <UserTask>[];

    // Clases → siguiente ocurrencia de ese día/hora
    for (final c in data.classes) {
      out.add(UserTask(_parseClassDate(c)));
    }

    // Exámenes → fecha exacta
    for (final e in data.exams) {
      final dt =
          DateTime.tryParse("${e.date} ${e.time}") ??
          DateTime.now().add(const Duration(days: 1));
      out.add(UserTask(dt));
    }

    return out;
  }

  DateTime _parseClassDate(ClassEntry c) {
    final now = DateTime.now();
    final targetWeekday = _weekdayNumber(c.day);

    int diff = (targetWeekday - now.weekday) % 7;
    if (diff == 0) diff = 7;

    final parts = c.time.split(':');
    final hh = int.tryParse(parts[0]) ?? 8;
    final mm = int.tryParse(parts.length >= 2 ? parts[1] : "0") ?? 0;

    return DateTime(now.year, now.month, now.day + diff, hh, mm);
  }

  int _weekdayNumber(String d) {
    switch (d.toLowerCase()) {
      case "lunes":
        return DateTime.monday;
      case "martes":
        return DateTime.tuesday;
      case "miércoles":
      case "miercoles":
        return DateTime.wednesday;
      case "jueves":
        return DateTime.thursday;
      case "viernes":
        return DateTime.friday;
      case "sábado":
      case "sabado":
        return DateTime.saturday;
      default:
        return DateTime.sunday;
    }
  }

  //---------------------------------------------------------------------------
  // SAVE
  //---------------------------------------------------------------------------
  Future<void> save() async {
    final newData = toSurvey();
    final oldData = await SurveyStorage.loadSurvey();

    final changes = <String>[];

    bool diff(a, b) => jsonEncode(a) != jsonEncode(b);

    if (oldData == null) {
      changes.addAll([
        "classes",
        "exams",
        "payments",
        "birthdays",
        "activities",
        "preferences",
      ]);
    } else {
      if (diff(oldData.classes, newData.classes)) changes.add("classes");
      if (diff(oldData.exams, newData.exams)) changes.add("exams");
      if (diff(oldData.payments, newData.payments)) changes.add("payments");
      if (diff(oldData.birthdays, newData.birthdays)) changes.add("birthdays");
      if (diff(oldData.activities, newData.activities)) {
        changes.add("activities");
      }
      if (diff(oldData.preferences.toJson(), newData.preferences.toJson())) {
        changes.add("preferences");
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("userName", newData.profile.name);
    await prefs.setString("userCity", newData.profile.city);

    await SurveyStorage.saveSurvey(newData);

    if (oldData == null) {
      await SurveyStorage.setSurveyCompleted();
    }

    // 🔮 V7.5: si hubo cambios relevantes → regenerar TODOS los auto-recordatorios
    if (changes.isNotEmpty) {
      final now = DateTime.now();

      final autoList = AutoReminderServiceV7.generateAll(
        payments: _toMonthlyPayments(newData),
        birthdays: _toBirthdayData(newData),
        settings: ReminderSettings(
          anticipationDays:
              int.tryParse(newData.preferences.reminderAdvance) ?? 1,
        ),
        tasks: _toUserTasks(newData),
        now: now,

        // 🔥 NUEVO: compatibilidad con Survey 2.0
        extraPayments: newData.extraPayments,
        extraBirthdays: newData.extraBirthdays,
      );

      final hiveList = ReminderGeneratorV7.convert(autoList);

      final box = await ReminderStorage.openBox();
      await box.clear();
      for (final r in hiveList) {
        await box.put(r.id, r);
      }

      await ReminderScheduler.scheduleAll(hiveList);
    }
  }

  //---------------------------------------------------------------------------
  // DISPOSE
  //---------------------------------------------------------------------------
  void dispose() {
    name.dispose();
    occupation.dispose();
    city.dispose();

    wakeUp.dispose();
    sleep.dispose();

    classesInfo.dispose();
    examsInfo.dispose();

    waterPayment.dispose();
    electricPayment.dispose();
    internetPayment.dispose();
    phonePayment.dispose();
    rentPayment.dispose();

    partnerBirthday.dispose();
    familyBirthdays.dispose();
    friendBirthdays.dispose();

    userBirthday.dispose();
    reminderAdvance.dispose();
  }
}

// lib/pages/survey/controller/survey_controller.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/survey_models.dart';
import '../storage/survey_storage.dart';

import 'package:auri_app/services/auto_reminder_service.dart';
import 'package:auri_app/services/reminder_generator.dart';
import 'package:auri_app/controllers/reminder/reminder_controller.dart';

class SurveyController {
  // ----------------------------------------------------------
  // TEXT FIELDS BÁSICOS
  // ----------------------------------------------------------
  final name = TextEditingController();
  final occupation = TextEditingController();
  final city = TextEditingController();

  final wakeUp = TextEditingController();
  final sleep = TextEditingController();

  final reminderAdvance = TextEditingController();

  // Cumpleaños principales
  final userBirthday = TextEditingController();
  final partnerBirthday = TextEditingController();

  // ----------------------------------------------------------
  // SWITCHES / FLAGS
  // ----------------------------------------------------------
  bool wantsWeeklyAgenda = false;

  bool hasClasses = false;
  bool hasExams = false;
  bool wantsPaymentReminders = true;
  bool hasPartner = false;
  bool wantsMoreBirthdays = false;

  // ----------------------------------------------------------
  // CAMPOS LEGACY MULTILÍNEA (clases / exámenes)
  // ----------------------------------------------------------
  final classesInfo = TextEditingController();
  final examsInfo = TextEditingController();

  // ----------------------------------------------------------
  // MODELOS ESTRUCTURADOS
  // ----------------------------------------------------------
  List<ClassEntry> classes = [];
  List<ExamEntry> exams = [];
  List<ActivityEntry> activities = [];

  List<PaymentEntry> basicPayments = [];
  List<PaymentEntry> extraPayments = [];

  List<BirthdayEntry> birthdays = [];
  List<BirthdayEntry> extraBirthdays = [];

  bool loaded = false;

  // ----------------------------------------------------------
  // LOAD
  // ----------------------------------------------------------
  Future<void> load() async {
    final data = await SurveyStorage.loadSurvey();

    if (data == null) {
      // Estado inicial por defecto
      wakeUp.text = "08:00";
      sleep.text = "23:00";
      reminderAdvance.text = "1";

      // Pagos básicos predefinidos (opción A)
      basicPayments = [
        PaymentEntry(name: "Agua", day: 5, time: "09:00"),
        PaymentEntry(name: "Luz", day: 7, time: "09:00"),
        PaymentEntry(name: "Internet", day: 10, time: "09:00"),
        PaymentEntry(name: "Teléfono", day: 22, time: "09:00"),
        PaymentEntry(name: "Renta", day: 1, time: "09:00"),
      ];
      extraPayments = [];

      birthdays = [];
      extraBirthdays = [];

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

    // MODELOS BASE
    classes = data.classes;
    exams = data.exams;
    activities = data.activities;
    basicPayments = data.basicPayments;
    extraPayments = data.extraPayments;
    birthdays = data.birthdays;

    // ESTADOS UI
    hasClasses = classes.isNotEmpty;
    classesInfo.text = _classesToMultiline(classes);

    hasExams = exams.isNotEmpty;
    examsInfo.text = _examsToMultiline(exams);

    wantsPaymentReminders =
        basicPayments.isNotEmpty || extraPayments.isNotEmpty;

    // Cumpleaños: usuario, pareja, extra
    _fillBirthdayFieldsFromModel();

    loaded = true;
  }

  void _fillBirthdayFieldsFromModel() {
    extraBirthdays = [];

    // Usuario
    final me = birthdays.firstWhere(
      (b) => b.name.toLowerCase() == "usuario",
      orElse: () => BirthdayEntry(name: "", day: 0, month: 0),
    );
    if (me.day > 0 && me.month > 0) {
      userBirthday.text =
          "${me.day.toString().padLeft(2, '0')}/${me.month.toString().padLeft(2, '0')}";
    }

    // Pareja
    final partner = birthdays.firstWhere(
      (b) => b.name.toLowerCase() == "pareja",
      orElse: () => BirthdayEntry(name: "", day: 0, month: 0),
    );
    if (partner.day > 0 && partner.month > 0) {
      hasPartner = true;
      partnerBirthday.text =
          "${partner.day.toString().padLeft(2, '0')}/${partner.month.toString().padLeft(2, '0')}";
    }

    // Extras (familia, amigos, etc.)
    for (final b in birthdays) {
      final lname = b.name.toLowerCase();
      if (lname == "usuario" || lname == "pareja") continue;
      extraBirthdays.add(b);
    }

    wantsMoreBirthdays = extraBirthdays.isNotEmpty;
  }

  // ----------------------------------------------------------
  // HELPERS: MULTILÍNEA
  // ----------------------------------------------------------
  String _classesToMultiline(List<ClassEntry> list) {
    if (list.isEmpty) return "";
    return list.map((c) => "${c.day} ${c.time} - ${c.name}").join('\n');
  }

  String _examsToMultiline(List<ExamEntry> list) {
    if (list.isEmpty) return "";
    return list.map((e) => "${e.date} ${e.time} - ${e.name}").join('\n');
  }

  // ----------------------------------------------------------
  // BUILD: CLASES / EXÁMENES
  // ----------------------------------------------------------
  List<ClassEntry> _buildClasses() {
    if (!hasClasses) return [];

    final lines = classesInfo.text.trim().split('\n');

    return lines.where((l) => l.trim().isNotEmpty).map((line) {
      final parts = line.split('-');
      final name = parts.length >= 2 ? parts[1].trim() : "Clase";

      final left = parts[0].trim();
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

  // ----------------------------------------------------------
  // BUILD: CUMPLEAÑOS
  // ----------------------------------------------------------
  List<BirthdayEntry> _buildBirthdays() {
    final out = <BirthdayEntry>[];

    int d(String x) => int.tryParse(x) ?? 1;

    String? parseDate(String s) {
      final m = RegExp(r'(\d{1,2})[\/\-](\d{1,2})').firstMatch(s);
      return m == null ? null : "${m.group(1)}/${m.group(2)}";
    }

    // Usuario
    if (userBirthday.text.trim().isNotEmpty) {
      final raw = parseDate(userBirthday.text.trim());
      if (raw != null) {
        final parts = raw.split('/');
        out.add(
          BirthdayEntry(name: "Usuario", day: d(parts[0]), month: d(parts[1])),
        );
      }
    }

    // Pareja
    if (hasPartner && partnerBirthday.text.trim().isNotEmpty) {
      final raw = parseDate(partnerBirthday.text.trim());
      if (raw != null) {
        final parts = raw.split('/');
        out.add(
          BirthdayEntry(name: "Pareja", day: d(parts[0]), month: d(parts[1])),
        );
      }
    }

    // Extras
    if (wantsMoreBirthdays) {
      out.addAll(extraBirthdays);
    }

    return out;
  }

  // ----------------------------------------------------------
  // SURVEY FINAL
  // ----------------------------------------------------------
  SurveyData toSurvey() {
    final builtClasses = _buildClasses();
    final builtExams = _buildExams();
    final builtBirthdays = _buildBirthdays();

    final effectiveBasic = wantsPaymentReminders
        ? basicPayments
        : <PaymentEntry>[];
    final effectiveExtra = wantsPaymentReminders
        ? extraPayments
        : <PaymentEntry>[];

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
      basicPayments: effectiveBasic,
      extraPayments: effectiveExtra,
      birthdays: builtBirthdays,
    );
  }

  // ----------------------------------------------------------
  // AUTO-REMINDERS: USER TASKS
  // ----------------------------------------------------------
  List<UserTask> _toUserTasks(SurveyData data) {
    if (!data.preferences.wantsWeeklyAgenda) {
      return [];
    }

    final out = <UserTask>[];

    for (final c in data.classes) {
      out.add(UserTask(_parseClassDate(c)));
    }

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

  // ----------------------------------------------------------
  // SAVE
  // ----------------------------------------------------------
  Future<void> save() async {
    final newData = toSurvey();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("userName", newData.profile.name);
    await prefs.setString("userCity", newData.profile.city);

    await SurveyStorage.saveSurvey(newData);
    await SurveyStorage.setSurveyCompleted();

    // AUTO-REMINDERS: regeneración SIEMPRE
    final now = DateTime.now();

    final autoList = AutoReminderServiceV7.generateAll(
      basicPayments: newData.basicPayments,
      extraPayments: newData.extraPayments,
      birthdays: newData.birthdays,
      anticipationDays: int.tryParse(newData.preferences.reminderAdvance) ?? 1,
      tasks: _toUserTasks(newData),
      now: now,
    );

    final hiveList = ReminderGeneratorV7.convert(autoList);

    // Usamos el ReminderController para reescribir caja + notifs
    await ReminderController.overwriteAll(hiveList);
  }

  // ----------------------------------------------------------
  // DISPOSE
  // ----------------------------------------------------------
  void dispose() {
    name.dispose();
    occupation.dispose();
    city.dispose();

    wakeUp.dispose();
    sleep.dispose();

    classesInfo.dispose();
    examsInfo.dispose();

    reminderAdvance.dispose();
    userBirthday.dispose();
    partnerBirthday.dispose();
  }
}

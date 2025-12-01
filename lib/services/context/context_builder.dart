// lib/services/context/context_builder.dart

import 'package:auri_app/services/context/context_models.dart';
import 'package:auri_app/services/context/context_sync_service.dart';
import 'package:auri_app/services/weather_service.dart';
import 'package:auri_app/models/weather_model.dart';

import 'package:auri_app/services/auto_reminder_service.dart';

// Memoria interna Flutter
import 'package:auri_app/auri/memory/memory_manager.dart';

// Survey
import 'package:auri_app/pages/survey/storage/survey_storage.dart';
import 'package:auri_app/pages/survey/models/survey_models.dart';

class ContextBuilder {
  // ============================================================
  static Future<AuriContextPayload> build() async {
    final survey = await SurveyStorage.loadSurvey();
    final now = DateTime.now();

    // ============================================================
    // USER
    // ============================================================
    final user = AuriContextUser(
      name: survey?.profile.name ?? "Usuario",
      city: survey?.profile.city ?? "San José",
      occupation: survey?.profile.occupation,
      birthday: _extractBirthday(survey),
    );

    // ============================================================
    // WEATHER
    // ============================================================
    AuriContextWeather? weatherBlock;

    try {
      final WeatherModel w = await WeatherService().getWeather(
        user.city ?? "San José",
      );

      weatherBlock = AuriContextWeather(
        temp: w.temperature,
        description: w.description,
      );
    } catch (_) {
      weatherBlock = null;
    }

    // ============================================================
    // RAW DATA FROM SURVEY
    // ============================================================
    final classesJson =
        survey?.classes
            .map((e) => e.toJson())
            .toList()
            .cast<Map<String, dynamic>>() ??
        [];

    final examsJson =
        survey?.exams
            .map((e) => e.toJson())
            .toList()
            .cast<Map<String, dynamic>>() ??
        [];

    final birthdaysJson =
        survey?.birthdays
            .map((e) => e.toJson())
            .toList()
            .cast<Map<String, dynamic>>() ??
        [];

    final paymentsJson = [
      ...(survey?.basicPayments.map((e) => e.toJson()) ?? []),
      ...(survey?.extraPayments.map((e) => e.toJson()) ?? []),
    ].cast<Map<String, dynamic>>();

    // ============================================================
    // AUTO EVENTS
    // ============================================================
    final tasks = _buildTasksFromSurvey(survey);

    final auto = AutoReminderServiceV7.generateAll(
      basicPayments: survey?.basicPayments ?? [],
      extraPayments: survey?.extraPayments ?? [],
      birthdays: survey?.birthdays ?? [],
      anticipationDays:
          int.tryParse(survey?.preferences.reminderAdvance ?? "1") ?? 1,
      tasks: tasks,
      now: now,
    );

    final events = auto
        .map(
          (a) => AuriContextEvent(title: a.title, urgent: false, when: a.date),
        )
        .toList();

    // ============================================================
    // PREFS
    // ============================================================
    final prefsMemory = AuriMemoryManager.instance.search("pref");

    final shortReplies = prefsMemory.any(
      (m) => m.value.contains("respuestas cortas"),
    );

    final softVoice = prefsMemory.any((m) => m.value.contains("voz_suave"));

    final prefs = AuriContextPrefs(
      shortReplies: shortReplies,
      softVoice: softVoice,
      personality: "auri_classic",
    );

    // ============================================================
    // BUILD FINAL PAYLOAD (incluye payments)
    // ============================================================
    return AuriContextPayload(
      weather: weatherBlock,
      events: events,
      classes: classesJson,
      exams: examsJson,
      birthdays: birthdaysJson,
      payments: paymentsJson, // <-- REQUERIDO POR TU MODELO

      user: user,
      prefs: prefs,
    );
  }

  // ============================================================
  static Future<void> buildAndSync() async {
    final p = await build();
    await ContextSyncService.sync(p);
  }

  // ============================================================
  // HELPERS
  // ============================================================
  static String? _extractBirthday(SurveyData? survey) {
    if (survey == null) return null;

    final b = survey.birthdays.firstWhere(
      (e) =>
          e.name.toLowerCase().contains("yo") ||
          e.name.toLowerCase().contains("usuario") ||
          e.name.toLowerCase().contains("me"),
      orElse: () => BirthdayEntry(name: "", day: 0, month: 0),
    );

    if (b.day <= 0) return null;

    return "${b.month.toString().padLeft(2, '0')}-${b.day.toString().padLeft(2, '0')}";
  }

  static List<UserTask> _buildTasksFromSurvey(SurveyData? survey) {
    final out = <UserTask>[];

    if (survey == null) return out;
    if (!survey.preferences.wantsWeeklyAgenda) return out;

    for (final c in survey.classes) {
      out.add(UserTask(_parseClassDate(c)));
    }

    for (final e in survey.exams) {
      final dt =
          DateTime.tryParse("${e.date} ${e.time}") ??
          DateTime.now().add(const Duration(days: 1));

      out.add(UserTask(dt));
    }

    return out;
  }

  static DateTime _parseClassDate(ClassEntry c) {
    final now = DateTime.now();
    final weekday = _weekdayNumber(c.day);

    int diff = (weekday - now.weekday) % 7;
    if (diff == 0) diff = 7;

    final parts = c.time.split(":");
    final hh = int.tryParse(parts[0]) ?? 8;
    final mm = int.tryParse(parts.length >= 2 ? parts[1] : "0") ?? 0;

    return DateTime(now.year, now.month, now.day + diff, hh, mm);
  }

  static int _weekdayNumber(String d) {
    switch (d.toLowerCase()) {
      case "lunes":
        return DateTime.monday;
      case "martes":
        return DateTime.tuesday;
      case "miercoles":
      case "miércoles":
        return DateTime.wednesday;
      case "jueves":
        return DateTime.thursday;
      case "viernes":
        return DateTime.friday;
      case "sabado":
      case "sábado":
        return DateTime.saturday;
      default:
        return DateTime.sunday;
    }
  }
}

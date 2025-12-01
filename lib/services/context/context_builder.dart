import 'package:auri_app/services/context/context_models.dart';
import 'package:auri_app/services/context/context_sync_service.dart';
import 'package:auri_app/services/weather_service.dart';
import 'package:auri_app/models/weather_model.dart';

import 'package:auri_app/services/auto_reminder_service.dart';
import 'package:auri_app/auri/memory/memory_manager.dart';

import 'package:auri_app/pages/survey/storage/survey_storage.dart';
import 'package:auri_app/pages/survey/models/survey_models.dart';

import 'package:auri_app/controllers/reminder/reminder_controller.dart';
import 'manual_reminder_classifier.dart';
import 'manual_reminder_merger.dart';
import 'package:auri_app/services/realtime/auri_realtime.dart';

class ContextBuilder {
  static Future<AuriContextPayload> build() async {
    final survey = await SurveyStorage.loadSurvey();
    final now = DateTime.now();

    // USER
    final user = AuriContextUser(
      name: survey?.profile.name ?? "Usuario",
      city: survey?.profile.city ?? "San José",
      occupation: survey?.profile.occupation,
      birthday: _extractBirthday(survey),
    );

    // WEATHER
    AuriContextWeather? weatherBlock;
    try {
      final WeatherModel w = await WeatherService().getWeather(
        user.city ?? "San José",
      );
      weatherBlock = AuriContextWeather(
        temp: w.temperature,
        description: w.description,
      );
    } catch (_) {}

    // RAW SURVEY BLOCKS
    final classesJson = survey?.classes.map((e) => e.toJson()).toList() ?? [];
    final examsJson = survey?.exams.map((e) => e.toJson()).toList() ?? [];
    final birthdaysJson =
        survey?.birthdays.map((e) => e.toJson()).toList() ?? [];
    final paymentsJson = [
      ...(survey?.basicPayments.map((e) => e.toJson()) ?? []),
      ...(survey?.extraPayments.map((e) => e.toJson()) ?? []),
    ];

    // AUTO REMINDERS – TRIM TO 30 DAYS
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

    final horizon = now.add(const Duration(days: 30));
    final autoTrimmed = auto.where((a) => a.date.isBefore(horizon)).toList();

    final autoEvents = autoTrimmed
        .map(
          (a) => AuriContextEvent(
            title: a.title,
            urgent: false,
            when: a.date.toIso8601String(),
          ),
        )
        .toList();

    // MANUAL REMINDERS
    final manualHive = await ReminderController.getAll();
    final expandedManual = <ExpandedReminder>[];

    for (final r in manualHive) {
      expandedManual.addAll(expandReminder(r, survey));
    }

    // MERGE FINAL
    final mergedEvents = mergeAllEvents(
      manual: expandedManual,
      autoEvents: autoEvents,
      survey: survey,
    );

    // PREFS
    final prefsMemory = AuriMemoryManager.instance.search("pref");

    final prefs = AuriContextPrefs(
      shortReplies: prefsMemory.any(
        (m) => m.value.contains("respuestas cortas"),
      ),
      softVoice: prefsMemory.any((m) => m.value.contains("voz_suave")),
      personality: "auri_classic",
    );

    return AuriContextPayload(
      weather: weatherBlock,
      events: mergedEvents,
      classes: classesJson.cast<Map<String, dynamic>>(),
      exams: examsJson.cast<Map<String, dynamic>>(),
      birthdays: birthdaysJson.cast<Map<String, dynamic>>(),
      payments: paymentsJson.cast<Map<String, dynamic>>(),
      user: user,
      prefs: prefs,
      timezone: now.timeZoneName,
    );
  }

  static Future<void> buildAndSync() async {
    final p = await build();
    AuriRealtime.instance.markContextReady();
    await ContextSyncService.sync(p);
  }

  static String? _extractBirthday(SurveyData? survey) {
    if (survey == null) return null;
    final b = survey.birthdays.firstWhere(
      (e) => e.name.toLowerCase().contains("usuario"),
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

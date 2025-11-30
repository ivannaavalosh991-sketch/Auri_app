// lib/services/context/context_builder.dart

import 'package:auri_app/services/context/context_models.dart';
import 'package:auri_app/services/context/context_sync_service.dart';
import 'package:auri_app/services/weather_service.dart';
import 'package:auri_app/models/weather_model.dart';

import 'package:auri_app/services/auto_reminder_service.dart';
import 'package:auri_app/controllers/reminder/reminder_controller.dart';

// Memoria interna Flutter
import 'package:auri_app/auri/memory/memory_manager.dart';

// User data (Survey)
import 'package:auri_app/pages/survey/storage/survey_storage.dart';
import 'package:auri_app/pages/survey/models/survey_models.dart';

class ContextBuilder {
  /// Construye el paquete maestro para enviar al backend.
  static Future<AuriContextPayload> build() async {
    // -------------------------------
    // 1. USER PROFILE
    // -------------------------------
    final survey = await SurveyStorage.loadSurvey();
    final userName = survey?.profile.name ?? "Usuario";
    final userCity = survey?.profile.city ?? "San José";

    final user = AuriContextUser(name: userName, city: userCity);

    // -------------------------------
    // 2. WEATHER
    // -------------------------------
    AuriContextWeather? weatherBlock;

    try {
      final WeatherModel w = await WeatherService().getWeather(userCity);

      weatherBlock = AuriContextWeather(
        temp: w.temperature,
        description: w.description,
      );
    } catch (e) {
      print("⚠ Error obteniendo clima: $e");
      weatherBlock = null;
    }

    // -------------------------------
    // 3. EVENTS (pagos, cumpleaños, agenda)
    // -------------------------------
    final now = DateTime.now();

    // 🔥 reconstruir tasks como en SurveyController
    final List<UserTask> tasks = _buildTasksFromSurvey(survey);

    final auto = AutoReminderServiceV7.generateAll(
      basicPayments: survey?.basicPayments ?? [],
      extraPayments: survey?.extraPayments ?? [],
      birthdays: survey?.birthdays ?? [],
      anticipationDays:
          int.tryParse(survey?.preferences.reminderAdvance ?? "1") ?? 1,
      tasks: tasks,
      now: now,
    );

    // Convertimos ReminderAuto → AuriContextEvent
    final events = auto
        .map(
          (a) => AuriContextEvent(title: a.title, urgent: false, when: a.date),
        )
        .toList();

    // -------------------------------
    // 4. PREFERENCIAS / MEMORIA LOCAL
    // -------------------------------
    final prefsMemory = AuriMemoryManager.instance.search("pref");

    final hasShortReplies = prefsMemory.any(
      (m) => m.value.contains("respuestas cortas"),
    );

    final softVoice = prefsMemory.any((m) => m.value.contains("voz_suave"));

    final personality = "auri_classic"; // luego será dinámico

    final prefs = AuriContextPrefs(
      shortReplies: hasShortReplies,
      softVoice: softVoice,
      personality: personality,
    );

    // -------------------------------
    // 5. ENSAMBLAR PAYLOAD
    // -------------------------------
    return AuriContextPayload(
      weather: weatherBlock,
      events: events,
      user: user,
      prefs: prefs,
    );
  }

  /// Construye y sincroniza automáticamente con el backend.
  static Future<void> buildAndSync() async {
    final payload = await build();
    await ContextSyncService.sync(payload);
  }

  // ============================================================
  // 🔧 Helpers internos (clases → DateTime, exámenes → DateTime)
  // ============================================================

  static List<UserTask> _buildTasksFromSurvey(SurveyData? survey) {
    final out = <UserTask>[];

    if (survey == null) return out;

    if (!survey.preferences.wantsWeeklyAgenda) return out;

    // CLASES
    for (final c in survey.classes) {
      out.add(UserTask(_parseClassDate(c)));
    }

    // EXÁMENES
    for (final e in survey.exams) {
      final dt =
          DateTime.tryParse("${e.date} ${e.time}") ??
          DateTime.now().add(Duration(days: 1));
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
}

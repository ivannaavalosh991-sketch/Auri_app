// lib/auri/mind/auri_mind_engine.dart

import 'package:auri_app/auri/memory/memory_manager.dart';

import 'package:auri_app/auri/mind/intents/auri_intent_engine.dart';
import 'package:auri_app/auri/mind/intents/reminder_intents.dart';
import 'package:auri_app/auri/mind/reply/auri_reply_engine.dart';
import 'package:auri_app/auri/mind/auri_brain_v3.dart';
import 'package:auri_app/auri/actions/auri_actions_engine.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:auri_app/services/weather_service.dart';
import 'package:auri_app/models/weather_model.dart';

class AuriReply {
  final String reply;
  final String intent;
  final Map<String, dynamic> data;

  AuriReply(this.reply, {required this.intent, required this.data});
}

class AuriMindEngine {
  static final AuriMindEngine instance = AuriMindEngine._internal();
  AuriMindEngine._internal();

  // ============================================================
  // UTILIDAD: obtener ciudad usando memoria + SharedPrefs
  // ============================================================
  Future<String> _getUserCity() async {
    final mem = AuriMemoryManager.instance.getLastOfType("user_city");
    if (mem != null && mem.value.isNotEmpty) return mem.value;

    final prefs = await SharedPreferences.getInstance();
    final fallback = prefs.getString("userCity") ?? "San José";

    AuriMemoryManager.instance.remember(
      type: "user_city",
      value: fallback,
      importance: 4,
    );

    return fallback;
  }

  // ============================================================
  // NÚCLEO MENTAL
  // ============================================================
  Future<AuriReply> processUserMessage(String text) async {
    // Guardar conversación efímera
    await AuriMemoryManager.instance.remember(
      type: "conversation",
      value: text,
      importance: 1,
      ephemeral: true,
    );

    // Preferencias tipo "me gusta..."
    _detectPreferences(text);

    // Detectar intención
    final intentResult = AuriIntentEngine.instance.detectIntent(text);

    AuriReply baseReply;

    switch (intentResult.intent) {
      // --------------------------------------------------------
      // CLIMA
      // --------------------------------------------------------
      case "get_weather":
        baseReply = await _handleWeatherIntent();
        break;

      // --------------------------------------------------------
      // OUTFIT
      // --------------------------------------------------------
      case "get_outfit":
        baseReply = await _handleOutfitIntent();
        break;

      // --------------------------------------------------------
      // RECORDATORIOS (ya conectados con ReminderIntents + Hive)
      // --------------------------------------------------------
      case "add_reminder":
        baseReply = await _handleAddReminder(intentResult.entities);
        break;

      // --------------------------------------------------------
      // CIUDAD DEL USUARIO (ACCIONES ENGINE)
      // --------------------------------------------------------
      case "update_city":
        baseReply = await _handleUpdateCity(intentResult.entities);
        break;

      // --------------------------------------------------------
      // PAGOS (ACCIONES ENGINE)
      // --------------------------------------------------------
      case "add_payment":
        baseReply = await _handleAddPayment(intentResult.entities);
        break;

      // --------------------------------------------------------
      // CUMPLEAÑOS (ACCIONES ENGINE)
      // --------------------------------------------------------
      case "add_birthday":
        baseReply = await _handleAddBirthday(intentResult.entities);
        break;

      // --------------------------------------------------------
      // SMALLTALK
      // --------------------------------------------------------
      case "smalltalk_greeting":
        await AuriMemoryManager.instance.remember(
          type: "positive_interaction",
          value: "El usuario saludó",
          importance: 2,
        );
        baseReply = AuriReply(
          "¡Hola! 💜 ¿En qué puedo ayudarte hoy?",
          intent: "smalltalk_greeting",
          data: {},
        );
        break;

      case "smalltalk_thanks":
        await AuriMemoryManager.instance.remember(
          type: "positive_interaction",
          value: "El usuario agradeció",
          importance: 2,
        );
        baseReply = AuriReply(
          "¡Con gusto! ✨ ¿Necesitas algo más?",
          intent: "smalltalk_thanks",
          data: {},
        );
        break;

      case "smalltalk_identity":
        baseReply = AuriReply(
          "Soy Auri 💜, tu asistente personal inteligente.",
          intent: "smalltalk_identity",
          data: {},
        );
        break;

      // --------------------------------------------------------
      // FALLBACK
      // --------------------------------------------------------
      default:
        final fb = AuriReplyEngine.instance.generate(intentResult, text);
        baseReply = AuriReply(
          fb,
          intent: intentResult.intent,
          data: intentResult.entities,
        );
        break;
    }

    // ------------------------------------------------------------
    // ETAPA FINAL: personalidad → emoción (AuriBrainV3)
    // ------------------------------------------------------------
    final personalized = _injectPersonality(baseReply.reply);
    final finalReply = AuriBrainV3.instance.enhance(personalized);

    return AuriReply(
      finalReply,
      intent: baseReply.intent,
      data: baseReply.data,
    );
  }

  // ============================================================
  // PERSONALIDAD (memoria “pref”)
  // ============================================================
  String _injectPersonality(String base) {
    final prefs = AuriMemoryManager.instance.search("pref");

    if (prefs.any((p) => p.value.contains("respuestas cortas"))) {
      return base.split(".").first + ".";
    }

    if (prefs.any((p) => p.value.contains("voz_suave"))) {
      return "Suavemente... $base 🌙";
    }

    return base;
  }

  // ============================================================
  // DETECTAR PREFERENCIAS
  // ============================================================
  void _detectPreferences(String text) {
    final t = text.toLowerCase();

    if (t.contains("responde corto") || t.contains("habla corto")) {
      AuriMemoryManager.instance.remember(
        type: "pref",
        value: "respuestas cortas",
        importance: 5,
      );
    }

    if (t.contains("voz suave") || t.contains("me gusta tu voz")) {
      AuriMemoryManager.instance.remember(
        type: "pref",
        value: "voz_suave",
        importance: 4,
      );
    }
  }

  // ============================================================
  // HANDLERS
  // ============================================================

  // CLIMA
  Future<AuriReply> _handleWeatherIntent() async {
    final city = await _getUserCity();
    final weather = await WeatherService().getWeather(city);

    final reply =
        "En ${weather.cityName} la temperatura es de ${weather.temperature.toStringAsFixed(1)}°C "
        "con ${weather.description} ${weather.emoji}.";

    return AuriReply(reply, intent: "get_weather", data: {"weather": weather});
  }

  // OUTFIT
  Future<AuriReply> _handleOutfitIntent() async {
    final city = await _getUserCity();
    final weather = await WeatherService().getWeather(city);

    final suggestion = weather.outfitSuggestion;

    final reply =
        "Con un clima de ${weather.temperature.toStringAsFixed(1)}°C en ${weather.cityName}, "
        "te recomiendo: $suggestion.";

    return AuriReply(
      reply,
      intent: "get_outfit",
      data: {"weather": weather, "suggestion": suggestion},
    );
  }

  // RECORDATORIOS (usa ReminderIntents, que ya guarda en Hive)
  Future<AuriReply> _handleAddReminder(Map<String, dynamic> entities) async {
    final reminder = await ReminderIntents.createReminderFromEntities(entities);

    final dt = DateTime.tryParse(reminder.dateIso);
    final friendlyDate = dt != null
        ? ReminderIntents.humanReadableDate(dt)
        : "la fecha indicada";

    final reply =
        "Perfecto 💜. Creé un recordatorio para \"${reminder.title}\" el $friendlyDate.";

    return AuriReply(
      reply,
      intent: "add_reminder",
      data: {...entities, "reminderId": reminder.id, "saved": true},
    );
  }

  // CIUDAD → AuriActionsEngine
  Future<AuriReply> _handleUpdateCity(Map<String, dynamic> entities) async {
    final raw = entities["city"]?.toString() ?? "";

    if (raw.isEmpty) {
      return AuriReply(
        "Entendí que quieres cambiar tu ciudad, pero no capté el nombre. ¿Me lo repites? 💜",
        intent: "update_city",
        data: entities,
      );
    }

    await AuriActionsEngine.instance.updateUserCity(raw);

    final reply =
        "Listo, actualizaré tu ciudad a $raw para el clima y tus recordatorios.";
    return AuriReply(
      reply,
      intent: "update_city",
      data: {...entities, "newCity": raw},
    );
  }

  // PAGO → AuriActionsEngine
  Future<AuriReply> _handleAddPayment(Map<String, dynamic> entities) async {
    final name = entities["name"]?.toString() ?? "pago";
    final dayStr = entities["day"]?.toString() ?? "1";
    final time = entities["time"]?.toString() ?? "09:00";
    final extra =
        entities["extra"] == true ||
        entities["type"]?.toString().toLowerCase() == "extra";

    final day = int.tryParse(dayStr) ?? 1;

    await AuriActionsEngine.instance.quickAddPayment(
      name: name,
      day: day,
      time: time,
      extra: extra,
    );

    final reply =
        "Perfecto 💜. Agregué el pago de $name el día $day a las $time.";
    return AuriReply(
      reply,
      intent: "add_payment",
      data: {...entities, "saved": true},
    );
  }

  // CUMPLEAÑOS → AuriActionsEngine
  Future<AuriReply> _handleAddBirthday(Map<String, dynamic> entities) async {
    final name = entities["name"]?.toString() ?? "alguien especial";
    final dayStr = entities["day"]?.toString() ?? "1";
    final monthStr = entities["month"]?.toString() ?? "1";

    final day = int.tryParse(dayStr) ?? 1;
    final month = int.tryParse(monthStr) ?? 1;

    await AuriActionsEngine.instance.quickAddBirthday(
      name: name,
      day: day,
      month: month,
    );

    final reply =
        "Anotado 💜. Guardé el cumpleaños de $name el $day/$month y lo tendré presente.";
    return AuriReply(
      reply,
      intent: "add_birthday",
      data: {...entities, "saved": true},
    );
  }
}

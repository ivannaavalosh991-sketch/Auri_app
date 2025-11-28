// lib/auri/mind/intents/auri_intent_engine.dart

import 'package:auri_app/auri/mind/nlp/nlp_tools.dart';

import 'package:auri_app/auri/mind/intents/reminder_intents.dart';
import 'package:auri_app/auri/mind/intents/weather_intents.dart';
import 'package:auri_app/auri/mind/intents/outfit_intents.dart';
import 'package:auri_app/auri/mind/intents/smalltalk_intents.dart' as st;
import 'package:auri_app/auri/mind/intents/fallback_intents.dart' as fb;
import 'package:auri_app/auri/mind/intents/agenda_intents.dart';
import 'package:auri_app/auri/mind/intents/alarm_intents.dart';

class AuriIntentResult {
  final String intent;
  final Map<String, dynamic> entities;

  AuriIntentResult(this.intent, this.entities);

  @override
  String toString() => 'AuriIntentResult(intent: $intent, entities: $entities)';
}

class AuriIntentEngine {
  static final AuriIntentEngine instance = AuriIntentEngine._internal();
  AuriIntentEngine._internal();

  AuriIntentResult detectIntent(String rawText) {
    final text = NLPTools.normalize(rawText);

    // 1) ⏰ Recordatorios
    final rem = ReminderIntents.detect(text);
    if (rem != null) return rem;

    // 2) 🔔 Alarmas
    final alarm = AlarmIntents.detect(text);
    if (alarm != null) return alarm;

    // 3) 📆 Agenda / “qué tengo hoy”
    final agenda = AgendaIntents.detect(text);
    if (agenda != null) return agenda;

    // 4) ⛅ Clima
    final weather = WeatherIntents.detect(text);
    if (weather != null) return weather;

    // 5) 👕 Outfit
    final outfit = OutfitIntents.detect(text);
    if (outfit != null) return outfit;

    // 6) 💬 Smalltalk
    final talk = st.SmalltalkIntents.detect(text);
    if (talk != null) return talk;

    // 7) ❓ Fallback
    return fb.FallbackIntents.detect(text);
  }
}

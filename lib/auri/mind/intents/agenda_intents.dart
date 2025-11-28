// lib/auri/mind/intents/agenda_intents.dart

import 'package:auri_app/auri/mind/intents/auri_intent_engine.dart';

class AgendaIntents {
  static AuriIntentResult? detect(String text) {
    // Ejemplos: "que tengo hoy", "qué hay para mañana", "mi agenda", "que tengo esta semana"
    final hasAgendaWord =
        text.contains("agenda") ||
        text.contains("que tengo") ||
        text.contains("qué tengo") ||
        text.contains("que hay") ||
        text.contains("qué hay");

    if (!hasAgendaWord) return null;

    // Entidad simple: dayScope = today / tomorrow / week
    String dayScope = "today";

    if (text.contains("mañana")) {
      dayScope = "tomorrow";
    } else if (text.contains("semana") || text.contains("esta semana")) {
      dayScope = "week";
    } else if (text.contains("hoy")) {
      dayScope = "today";
    }

    return AuriIntentResult("get_agenda", {"dayScope": dayScope});
  }
}

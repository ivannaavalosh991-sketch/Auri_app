// lib/auri/mind/intents/alarm_intents.dart

import 'package:flutter/material.dart';
import 'package:auri_app/auri/mind/intents/auri_intent_engine.dart';
import 'package:auri_app/auri/mind/parser/entity_parser.dart';

class AlarmIntents {
  static AuriIntentResult? detect(String text) {
    final hasTrigger =
        text.contains("alarma") ||
        text.contains("pon una alarma") ||
        text.contains("pon alarma") ||
        text.contains("despiertame") ||
        text.contains("despiértame");

    if (!hasTrigger) return null;

    // Re-usamos EntityParser para sacar fecha / hora.
    final entities = EntityParser.extract(text);

    // Marcamos que es tipo "alarm" aunque internamente lo tratemos parecido a reminder.
    entities["type"] = "alarm";

    return AuriIntentResult("add_alarm", entities);
  }
}

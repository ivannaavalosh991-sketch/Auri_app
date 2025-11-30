// lib/models/reminder_hive.dart
import 'dart:convert';

/// Modelo simple para almacenar recordatorios en Hive
class ReminderHive {
  String id;
  String title;
  String dateIso;
  String repeats;
  String tag;
  bool isAuto;

  /// JSON opcional (antes required)
  String jsonPayload;

  ReminderHive({
    required this.id,
    required this.title,
    required this.dateIso,
    this.repeats = 'once',
    this.tag = '',
    this.isAuto = false,
    this.jsonPayload = "{}", // <-- ⭐ valor seguro y opcional
  });

  Map<String, dynamic> toJsonMap() => {
    'id': id,
    'title': title,
    'date': dateIso,
    'repeats': repeats,
    'tag': tag,
    'isAuto': isAuto,
    'jsonPayload': jsonPayload,
  };

  factory ReminderHive.fromJsonMap(Map<String, dynamic> m) => ReminderHive(
    id: m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: m['title']?.toString() ?? 'Recordatorio',
    dateIso: m['date']?.toString() ?? DateTime.now().toIso8601String(),
    repeats: m['repeats']?.toString() ?? 'once',
    tag: m['tag']?.toString() ?? '',
    isAuto: m['isAuto'] == true,
    jsonPayload: jsonEncode(m),
  );
}

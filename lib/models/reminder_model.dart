import 'dart:convert';

class Reminder {
  final String id;
  String title;
  String description; // ✔ Nuevo campo
  DateTime dateTime;
  bool isCompleted;
  bool isScheduled; // ✔ Nuevo campo

  Reminder({
    required this.id,
    required this.title,
    required this.dateTime,
    this.description = "",
    this.isCompleted = false,
    this.isScheduled = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description, // ✔ Guardar descripción
    'dateTime': dateTime.toIso8601String(),
    'isCompleted': isCompleted,
    'isScheduled': isScheduled, // ✔ Guardar flag
  };

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? "",
      dateTime: DateTime.parse(json['dateTime']),
      isCompleted: json['isCompleted'] ?? false,
      isScheduled: json['isScheduled'] ?? false,
    );
  }
}

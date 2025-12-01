// ============================================================
// CONTEXT MODELS V4 — completamente alineados al backend
// ============================================================

class AuriContextPayload {
  final AuriContextWeather? weather;
  final List<AuriContextEvent> events;

  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> exams;
  final List<Map<String, dynamic>> birthdays;
  final List<Map<String, dynamic>> payments;

  final AuriContextUser user;
  final AuriContextPrefs prefs;
  final String timezone;

  AuriContextPayload({
    required this.weather,
    required this.events,
    required this.classes,
    required this.exams,
    required this.birthdays,
    required this.payments,
    required this.user,
    required this.prefs,
    required this.timezone,
  });

  Map<String, dynamic> toJson() {
    return {
      "weather": weather?.toJson(),
      "events": events.map((e) => e.toJson()).toList(),
      "classes": classes,
      "exams": exams,
      "birthdays": birthdays,
      "payments": payments,
      "user": user.toJson(),
      "prefs": prefs.toJson(),
      "timezone": timezone,
    };
  }
}

// WEATHER
class AuriContextWeather {
  final double temp;
  final String description;

  AuriContextWeather({required this.temp, required this.description});

  Map<String, dynamic> toJson() => {"temp": temp, "description": description};
}

// EVENT
class AuriContextEvent {
  final String title;
  final bool urgent;
  final DateTime when;

  AuriContextEvent({
    required this.title,
    required this.urgent,
    required this.when,
  });

  Map<String, dynamic> toJson() => {
    "title": title,
    "urgent": urgent,
    "when": when.toIso8601String(),
  };
}

// USER
class AuriContextUser {
  final String name;
  final String? city;
  final String? occupation;
  final String? birthday;

  AuriContextUser({
    required this.name,
    this.city,
    this.occupation,
    this.birthday,
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "city": city,
    "occupation": occupation,
    "birthday": birthday,
  };
}

// PREFS
class AuriContextPrefs {
  final bool shortReplies;
  final bool softVoice;
  final String personality;

  AuriContextPrefs({
    required this.shortReplies,
    required this.softVoice,
    required this.personality,
  });

  Map<String, dynamic> toJson() => {
    "shortReplies": shortReplies,
    "softVoice": softVoice,
    "personality": personality,
  };
}

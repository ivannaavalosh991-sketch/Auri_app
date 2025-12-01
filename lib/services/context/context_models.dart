class AuriContextPayload {
  final AuriContextWeather? weather;
  final List<AuriContextEvent> events;
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> exams;
  final List<Map<String, dynamic>> birthdays;
  final List<Map<String, dynamic>> payments;
  final AuriContextUser user;
  final AuriContextPrefs prefs;

  // 🔹 NUEVO
  final String timezone;
  final String currentTimeIso;
  final String currentTimePretty;
  final String currentDatePretty;

  AuriContextPayload({
    this.weather,
    required this.events,
    required this.classes,
    required this.exams,
    required this.birthdays,
    required this.payments,
    required this.user,
    required this.prefs,
    required this.timezone,
    required this.currentTimeIso,
    required this.currentTimePretty,
    required this.currentDatePretty,
  });

  Map<String, dynamic> toJson() => {
    "weather": weather?.toJson(),
    "events": events.map((e) => e.toJson()).toList(),
    "classes": classes,
    "exams": exams,
    "birthdays": birthdays,
    "payments": payments,
    "user": user.toJson(),
    "prefs": prefs.toJson(),

    // 🔹 NUEVO
    "timezone": timezone,
    "current_time_iso": currentTimeIso,
    "current_time_pretty": currentTimePretty,
    "current_date_pretty": currentDatePretty,
  };
}

// ============================================================
// WEATHER
// ============================================================

class AuriContextWeather {
  final double temp;
  final String description;

  AuriContextWeather({required this.temp, required this.description});

  Map<String, dynamic> toJson() => {"temp": temp, "description": description};
}

// ============================================================
// EVENT  (💜 corregido con when como String ISO8601)
// ============================================================

class AuriContextEvent {
  final String title;
  final bool urgent;

  /// Siempre String en ISO8601 (backend lo pide así)
  final String when;

  AuriContextEvent({
    required this.title,
    required this.urgent,
    required this.when,
  });

  /// Ya NO convertimos aquí, porque ya viene como String
  Map<String, dynamic> toJson() => {
    "title": title,
    "urgent": urgent,
    "when": when,
  };
}

// ============================================================
// USER
// ============================================================

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

// ============================================================
// PREFS
// ============================================================

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

class AuriContextPayload {
  final AuriContextWeather? weather;
  final List<AuriContextEvent> events;
  final AuriContextUser user;
  final AuriContextPrefs prefs;

  AuriContextPayload({
    required this.weather,
    required this.events,
    required this.user,
    required this.prefs,
  });

  Map<String, dynamic> toJson() {
    return {
      "weather": weather?.toJson(),
      "events": events.map((e) => e.toJson()).toList(),
      "user": user.toJson(),
      "prefs": prefs.toJson(),
    };
  }
}

class AuriContextWeather {
  final double temp;
  final String description;

  AuriContextWeather({required this.temp, required this.description});

  Map<String, dynamic> toJson() => {"temp": temp, "description": description};
}

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

class AuriContextUser {
  final String name;
  final String? city;

  AuriContextUser({required this.name, this.city});

  Map<String, dynamic> toJson() => {"name": name, "city": city};
}

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
    "short_replies": shortReplies,
    "soft_voice": softVoice,
    "personality": personality,
  };
}

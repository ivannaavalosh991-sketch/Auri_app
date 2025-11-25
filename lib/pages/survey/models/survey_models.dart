// lib/pages/survey/models/survey_models.dart

// -------------------------------------------------------------
// USER PROFILE
// -------------------------------------------------------------
class UserProfile {
  String name;
  String occupation;
  String city;

  UserProfile({
    required this.name,
    required this.occupation,
    required this.city,
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "occupation": occupation,
    "city": city,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json["name"] ?? "",
    occupation: json["occupation"] ?? "",
    city: json["city"] ?? "",
  );
}

// -------------------------------------------------------------
// USER ROUTINE
// -------------------------------------------------------------
class UserRoutine {
  String wakeUpTime;
  String sleepTime;

  UserRoutine({required this.wakeUpTime, required this.sleepTime});

  Map<String, dynamic> toJson() => {
    "wakeUpTime": wakeUpTime,
    "sleepTime": sleepTime,
  };

  factory UserRoutine.fromJson(Map<String, dynamic> json) => UserRoutine(
    wakeUpTime: json["wakeUpTime"] ?? "08:00",
    sleepTime: json["sleepTime"] ?? "23:00",
  );
}

// -------------------------------------------------------------
// USER PREFERENCES
// -------------------------------------------------------------
class UserPreferences {
  String reminderAdvance;
  bool wantsWeeklyAgenda;

  UserPreferences({
    required this.reminderAdvance,
    required this.wantsWeeklyAgenda,
  });

  Map<String, dynamic> toJson() => {
    "reminderAdvance": reminderAdvance,
    "wantsWeeklyAgenda": wantsWeeklyAgenda,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        reminderAdvance: json["reminderAdvance"] ?? "1 día antes",
        wantsWeeklyAgenda: json["wantsWeeklyAgenda"] ?? false,
      );
}

// -------------------------------------------------------------
// STRUCTURED MODELS
// -------------------------------------------------------------

class ClassEntry {
  String name;
  String day;
  String time;

  ClassEntry({required this.name, required this.day, required this.time});

  Map<String, dynamic> toJson() => {"name": name, "day": day, "time": time};

  factory ClassEntry.fromJson(Map<String, dynamic> json) => ClassEntry(
    name: json["name"] ?? "",
    day: json["day"] ?? "Lunes",
    time: json["time"] ?? "08:00",
  );
}

class ExamEntry {
  String name;
  String date;
  String time;

  ExamEntry({required this.name, required this.date, required this.time});

  Map<String, dynamic> toJson() => {"name": name, "date": date, "time": time};

  factory ExamEntry.fromJson(Map<String, dynamic> json) => ExamEntry(
    name: json["name"] ?? "",
    date: json["date"] ?? "",
    time: json["time"] ?? "08:00",
  );
}

class ActivityEntry {
  String name;
  String day;
  String time;

  ActivityEntry({required this.name, required this.day, required this.time});

  Map<String, dynamic> toJson() => {"name": name, "day": day, "time": time};

  factory ActivityEntry.fromJson(Map<String, dynamic> json) => ActivityEntry(
    name: json["name"] ?? "",
    day: json["day"] ?? "Lunes",
    time: json["time"] ?? "09:00",
  );
}

class PaymentEntry {
  String name;
  int day;
  String time;

  PaymentEntry({required this.name, required this.day, required this.time});

  Map<String, dynamic> toJson() => {"name": name, "day": day, "time": time};

  factory PaymentEntry.fromJson(Map<String, dynamic> json) => PaymentEntry(
    name: json["name"] ?? "",
    day: json["day"] ?? 1,
    time: json["time"] ?? "09:00",
  );
}

class ExtraPaymentEntry {
  String name;
  int day;
  String time;

  ExtraPaymentEntry({
    required this.name,
    required this.day,
    required this.time,
  });

  Map<String, dynamic> toJson() => {"name": name, "day": day, "time": time};

  factory ExtraPaymentEntry.fromJson(Map<String, dynamic> json) =>
      ExtraPaymentEntry(
        name: json["name"] ?? "",
        day: json["day"] ?? 1,
        time: json["time"] ?? "09:00",
      );
}

class BirthdayEntry {
  String name;
  int day;
  int month;

  BirthdayEntry({required this.name, required this.day, required this.month});

  Map<String, dynamic> toJson() => {"name": name, "day": day, "month": month};

  factory BirthdayEntry.fromJson(Map<String, dynamic> json) => BirthdayEntry(
    name: json["name"] ?? "",
    day: json["day"] ?? 1,
    month: json["month"] ?? 1,
  );
}

class ExtraBirthdayEntry {
  String name;
  int day;
  int month;

  ExtraBirthdayEntry({
    required this.name,
    required this.day,
    required this.month,
  });

  Map<String, dynamic> toJson() => {"name": name, "day": day, "month": month};

  factory ExtraBirthdayEntry.fromJson(Map<String, dynamic> json) =>
      ExtraBirthdayEntry(
        name: json["name"] ?? "",
        day: json["day"] ?? 1,
        month: json["month"] ?? 1,
      );
}

// -------------------------------------------------------------
// SURVEY DATA
// -------------------------------------------------------------

class SurveyData {
  UserProfile profile;
  UserRoutine routine;
  UserPreferences preferences;

  List<ClassEntry> classes;
  List<ExamEntry> exams;
  List<ActivityEntry> activities;

  List<PaymentEntry> payments;
  List<ExtraPaymentEntry> extraPayments;

  List<BirthdayEntry> birthdays;
  List<ExtraBirthdayEntry> extraBirthdays;

  SurveyData({
    required this.profile,
    required this.routine,
    required this.preferences,
    required this.classes,
    required this.exams,
    required this.activities,
    required this.payments,
    required this.extraPayments,
    required this.birthdays,
    required this.extraBirthdays,
  });

  Map<String, dynamic> toJson() => {
    "profile": profile.toJson(),
    "routine": routine.toJson(),
    "preferences": preferences.toJson(),
    "classes": classes.map((e) => e.toJson()).toList(),
    "exams": exams.map((e) => e.toJson()).toList(),
    "activities": activities.map((e) => e.toJson()).toList(),
    "payments": payments.map((e) => e.toJson()).toList(),
    "extraPayments": extraPayments.map((e) => e.toJson()).toList(),
    "birthdays": birthdays.map((e) => e.toJson()).toList(),
    "extraBirthdays": extraBirthdays.map((e) => e.toJson()).toList(),
  };

  factory SurveyData.fromJson(Map<String, dynamic> json) => SurveyData(
    profile: UserProfile.fromJson(json["profile"]),
    routine: UserRoutine.fromJson(json["routine"]),
    preferences: UserPreferences.fromJson(json["preferences"]),
    classes: (json["classes"] as List<dynamic>)
        .map((e) => ClassEntry.fromJson(e))
        .toList(),
    exams: (json["exams"] as List<dynamic>)
        .map((e) => ExamEntry.fromJson(e))
        .toList(),
    activities: (json["activities"] as List<dynamic>)
        .map((e) => ActivityEntry.fromJson(e))
        .toList(),
    payments: (json["payments"] as List<dynamic>)
        .map((e) => PaymentEntry.fromJson(e))
        .toList(),
    extraPayments: (json["extraPayments"] as List<dynamic>? ?? [])
        .map((e) => ExtraPaymentEntry.fromJson(e))
        .toList(),
    birthdays: (json["birthdays"] as List<dynamic>)
        .map((e) => BirthdayEntry.fromJson(e))
        .toList(),
    extraBirthdays: (json["extraBirthdays"] as List<dynamic>? ?? [])
        .map((e) => ExtraBirthdayEntry.fromJson(e))
        .toList(),
  );
}

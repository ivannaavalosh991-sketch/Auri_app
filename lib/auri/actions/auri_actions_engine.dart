// lib/auri/actions/auri_actions_engine.dart

import 'package:auri_app/pages/survey/models/survey_models.dart';
import 'package:auri_app/pages/survey/storage/survey_storage.dart';

import 'package:auri_app/services/auto_reminder_service.dart';
import 'package:auri_app/services/reminder_generator.dart';
import 'package:auri_app/controllers/reminder/reminder_controller.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AuriActionsEngine {
  AuriActionsEngine._();
  static final AuriActionsEngine instance = AuriActionsEngine._();

  // ============================================================
  // 1) CIUDAD DEL USUARIO
  // ============================================================
  Future<void> updateUserCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("userCity", city);

    // Si existe survey, sincronizamos también el perfil
    final survey = await SurveyStorage.loadSurvey();
    if (survey != null) {
      survey.profile.city = city;
      await SurveyStorage.saveSurvey(survey);
    }
  }

  // ============================================================
  // 2) QUICK ADD: PAGO EXTRA (por voz)
  // ============================================================
  Future<void> quickAddPayment({
    required String name,
    required int day,
    required String time, // "HH:mm"
    bool extra = true,
  }) async {
    final survey = await _loadSurveyOrCreate();

    final entry = PaymentEntry(name: name, day: day, time: time);

    if (extra) {
      survey.extraPayments.add(entry);
    } else {
      survey.basicPayments.add(entry);
    }

    await SurveyStorage.saveSurvey(survey);
    await _regenerateAutoReminders(survey);
  }

  // ============================================================
  // 3) QUICK ADD: CUMPLEAÑOS (por voz)
  // ============================================================
  Future<void> quickAddBirthday({
    required String name,
    required int day,
    required int month,
  }) async {
    final survey = await _loadSurveyOrCreate();

    survey.birthdays.add(BirthdayEntry(name: name, day: day, month: month));

    await SurveyStorage.saveSurvey(survey);
    await _regenerateAutoReminders(survey);
  }

  // ============================================================
  // UTILIDADES INTERNAS
  // ============================================================
  Future<SurveyData> _loadSurveyOrCreate() async {
    final existing = await SurveyStorage.loadSurvey();
    if (existing != null) return existing;

    // Survey "vacío" por defecto si el usuario aún no lo rellena
    return SurveyData(
      profile: UserProfile(name: "", occupation: "", city: ""),
      routine: UserRoutine(wakeUpTime: "08:00", sleepTime: "23:00"),
      preferences: UserPreferences(
        reminderAdvance: "1",
        wantsWeeklyAgenda: false,
      ),
      classes: [],
      exams: [],
      activities: [],
      basicPayments: [],
      extraPayments: [],
      birthdays: [],
    );
  }

  Future<void> _regenerateAutoReminders(SurveyData data) async {
    final now = DateTime.now();

    final autoList = AutoReminderServiceV7.generateAll(
      basicPayments: data.basicPayments,
      extraPayments: data.extraPayments,
      birthdays: data.birthdays,
      anticipationDays: int.tryParse(data.preferences.reminderAdvance) ?? 1,
      tasks: [], // tus UserTask de clases/exámenes los puedes agregar luego
      now: now,
    );

    final hiveList = ReminderGeneratorV7.convert(autoList);

    await ReminderController.overwriteAll(hiveList);
  }
}

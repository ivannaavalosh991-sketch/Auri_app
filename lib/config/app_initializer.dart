// lib/config/app_initializer.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auri_app/models/reminder_hive.dart';
import 'package:auri_app/models/reminder_hive_adapter.dart';
import 'package:auri_app/pages/survey/storage/survey_storage.dart';
import 'package:auri_app/services/notification_service.dart';

class AppInitializer {
  Future<bool> init() async {
    // 1. Inicializar Hive
    await Hive.initFlutter();

    // 2. Registrar adapter ReminderHive
    if (!Hive.isAdapterRegistered(ReminderAdapter().typeId)) {
      Hive.registerAdapter(ReminderAdapter());
    }

    // 3. Abrir box de recordatorios
    if (Hive.isBoxOpen('reminders')) {
      await Hive.box('reminders').close();
    }
    await Hive.openBox<ReminderHive>('reminders');

    // 4. INICIALIZAR SISTEMA DE NOTIFICACIONES (⬅️ antes del survey, importantísimo)
    await NotificationService().init();

    // 5. Cargar Survey
    final survey = await SurveyStorage.loadSurvey();
    final isSurveyCompleted = survey != null;

    // (Opcional) Guardar bandera global
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('survey_completed', isSurveyCompleted);

    return isSurveyCompleted;
  }
}

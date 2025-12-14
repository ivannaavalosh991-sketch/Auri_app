import 'package:flutter/material.dart';
import 'package:auri_app/pages/welcome/welcome_screen.dart';
import 'package:auri_app/pages/survey/survey_screen.dart';
import 'package:auri_app/pages/settings/settings_screen.dart';
import 'package:auri_app/pages/home/home_screen.dart';
import 'package:auri_app/pages/reminders/reminders_page.dart';
import 'package:auri_app/pages/subscription/subscription_page.dart'; // ← NUEVO

class AppRoutes {
  static const welcome = '/welcome';
  static const survey = '/survey';
  static const home = '/home';
  static const settings = '/settings';
  static const surveyInitial = '/survey/initial';
  static const surveyEdit = '/survey/edit';
  static const reminders = '/reminders';
  static const outfitPage = '/outfit';
  static const weatherPage = "/weather";

  // 🚀 NUEVA RUTA DE TU PANTALLA DE SUSCRIPCIÓN
  static const subscription = "/subscription";

  static Map<String, WidgetBuilder> routes = {
    welcome: (_) => const WelcomeScreen(),
    survey: (_) => const SurveyScreen(isInitialSetup: true),
    surveyInitial: (_) => const SurveyScreen(isInitialSetup: true),
    surveyEdit: (_) => const SurveyScreen(isInitialSetup: false),
    home: (_) => const HomeScreen(),
    settings: (_) => const SettingsScreen(),
    reminders: (_) => const RemindersPage(),

    // ⭐ Aquí se registra la pantalla de Suscripción
    subscription: (_) => const SubscriptionPage(),
  };
}

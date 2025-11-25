// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:auri_app/firebase_options.dart';
import 'package:auri_app/firebase_background.dart';
import 'package:auri_app/config/app_initializer.dart';
import 'package:auri_app/config/app_theme.dart';
import 'package:auri_app/routes/app_routes.dart';
import 'package:auri_app/pages/reminders/reminders_page.dart';
import 'package:auri_app/widgets/auth_gate.dart';
import 'package:auri_app/config/timezone_setup.dart';
import 'package:auri_app/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Timezone local (multi país)
  await setupLocalTimezone();

  // Notificaciones locales + permisos
  await NotificationService().init();

  // Hive, Survey, etc.
  final isSurveyCompleted = await AppInitializer().init();

  runApp(AuriApp(isSurveyCompleted: isSurveyCompleted));
}

class AuriApp extends StatelessWidget {
  final bool isSurveyCompleted;

  const AuriApp({super.key, required this.isSurveyCompleted});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auri Asistente',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: AuthGate(isSurveyCompleted: isSurveyCompleted),
      routes: {
        ...AppRoutes.routes,
        AppRoutes.reminders: (_) => const RemindersPage(),
      },
    );
  }
}

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

// 🔮 Memoria y contexto
import 'package:auri_app/auri/memory/memory_manager.dart';
import 'package:auri_app/services/context/context_builder.dart';
import 'package:auri_app/services/context/auto_sync_timer.dart';
import 'package:auri_app/services/realtime/auri_realtime.dart';

// 🟣 Suscripciones (Provider)
import 'package:provider/provider.dart';
import 'package:auri_app/providers/subscription/subscription_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===============================
  // 1) Cargar .env (DEBE SER PRIMERO)
  // ===============================
  await dotenv.load(fileName: ".env");

  // ===============================
  // 2) Inicializar memoria local
  // ===============================
  await AuriMemoryManager.instance.init();

  // ===============================
  // 3) Firebase
  // ===============================
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ===============================
  // 4) Notificaciones + zona horaria
  // ===============================
  await setupLocalTimezone();
  await NotificationService().init();

  // ===============================
  // 5) Configuración inicial (survey)
  // ===============================
  final isSurveyCompleted = await AppInitializer().init();

  // ===============================
  // 6) Lanzar la UI con Provider
  // ===============================
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SubscriptionProvider()..loadStatus(),
        ),
      ],
      child: AuriApp(isSurveyCompleted: isSurveyCompleted),
    ),
  );

  // ===============================
  // 7) WebSocket — conectar después
  // ===============================
  Future.microtask(() async {
    await ContextBuilder.buildAndSync();
    AuriRealtime.instance.markContextReady();
    await AuriRealtime.instance.ensureConnected();
  });

  // ===============================
  // 8) Auto-sync de contexto
  // ===============================
  AutoSyncTimer.start();
}

class AuriApp extends StatelessWidget {
  final bool isSurveyCompleted;

  const AuriApp({super.key, required this.isSurveyCompleted});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AuriRealtime.navigatorKey,
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

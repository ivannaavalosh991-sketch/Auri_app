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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // 🔮 Inicializar memoria
  await AuriMemoryManager.instance.init();

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Notificaciones + timezone
  await setupLocalTimezone();
  await NotificationService().init();

  // Survey / settings
  final isSurveyCompleted = await AppInitializer().init();

  // ⚠️ ⚠️ NO sincronizamos AURI aún
  // Esperamos a que la app se construya primero

  runApp(AuriApp(isSurveyCompleted: isSurveyCompleted));

  // 🔄 Ahora sí → sincronizamos sin bloquear el UI
  Future.microtask(() async {
    await ContextBuilder.buildAndSync();
    AuriRealtime.instance.markContextReady();

    // Ahora sí, se conecta el WebSocket de forma segura
    await AuriRealtime.instance.ensureConnected();
  });

  // Sync cada 15 min (no bloquea)
  AutoSyncTimer.start();
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

import 'dart:async';
import 'package:auri_app/services/context/context_builder.dart';

class AutoSyncTimer {
  static Timer? _timer;

  /// Inicia sincronización automática cada 15 minutos
  static void start() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(minutes: 15), (t) async {
      await ContextBuilder.buildAndSync();
    });

    print("⏱️ AutoSyncTimer iniciado (cada 15 minutos)");
  }

  /// Detener el timer (opcional)
  static void stop() {
    _timer?.cancel();
  }
}

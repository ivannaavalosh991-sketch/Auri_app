// lib/pages/home/home_screen.dart
import 'dart:async';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auri_app/models/reminder_hive.dart';
import 'package:auri_app/services/cleanup_service_v7_hive.dart';
import 'package:auri_app/services/weather_service.dart';
import 'package:auri_app/models/weather_model.dart';
import 'package:auri_app/widgets/auri_slime_placeholder.dart';
import 'package:auri_app/widgets/weather_display_glass.dart';
import 'package:auri_app/widgets/outfit_recommendation_glass.dart';
import 'package:auri_app/routes/app_routes.dart';
import 'package:auri_app/services/slime_mood_engine.dart';

import 'package:auri_app/auri/voice/voice_session_controller.dart';
import 'package:auri_app/widgets/siri_voice_button.dart';

import 'package:auri_app/services/realtime/auri_realtime.dart';
import 'package:auri_app/auri/ui/jarvis_hud.dart';
import 'package:auri_app/services/context/context_builder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _userCity = '';

  double _slimeMouthEnergy = 0.0;
  String _thinkingText = "";

  final WeatherService _weatherService = WeatherService();
  WeatherModel? _weather;
  bool _weatherLoading = true;
  String _weatherError = '';

  SlimeMood? _slimeMood;

  List<ReminderHive> _upcoming = [];

  @override
  void initState() {
    super.initState();

    // 🔄 justo al abrir el HomeScreen sincronizamos
    ContextBuilder.buildAndSync();

    // 🔌 Conectar al backend de Render
    AuriRealtime.instance.ensureConnected();

    final rt = AuriRealtime.instance;

    // --------------------------------------------------------------
    // JARVIS TEXT EVENTS
    // --------------------------------------------------------------
    rt.addOnPartial((txt) {
      setState(() => _thinkingText = txt);
    });

    rt.addOnFinal((txt) {
      print("💬 Respuesta final: $txt");
    });

    // STATES: thinking / idle
    rt.addOnThinking((isThinking) {
      SlimeMoodEngine.setVoiceState(isThinking ? "thinking" : "idle");
      if (!isThinking) setState(() => _thinkingText = "");
    });

    // --------------------------------------------------------------
    // 🔊 LIP SYNC — mover boca del slime
    // --------------------------------------------------------------
    Timer? _lipThrottle;

    rt.addOnLip((energy) {
      if (_lipThrottle?.isActive ?? false) return;

      _lipThrottle = Timer(const Duration(milliseconds: 66), () {
        if (!mounted) return;
        setState(() => _slimeMouthEnergy = energy);
      });
    });

    // --------------------------------------------------------------
    // 🎬 ACTIONS — comandos especiales del backend
    // --------------------------------------------------------------
    rt.addOnAction((data) {
      print("⚡ Acción recibida: $data");
      // ejemplo:
      if (data["action"] == "open_weather") {
        Navigator.pushNamed(context, AppRoutes.weatherPage);
      }
    });

    // ----------------------------------------------
    // Cargar datos
    // ----------------------------------------------
    _loadData();
  }

  // ------------------------------------------------------------
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName') ?? "Usuario";
    _userCity = prefs.getString('userCity') ?? "";

    setState(() {});
    await _loadWeather();
    await _loadReminders();
  }

  // ------------------------------------------------------------
  Future<void> _loadWeather() async {
    if (_userCity.trim().isEmpty) {
      _weatherError = "Configura tu ciudad en ajustes.";
      _weatherLoading = false;
      setState(() {});
      return;
    }

    try {
      final w = await _weatherService.getWeather(_userCity);
      _weather = w;
      _slimeMood = SlimeMoodEngine.fromWeather(w, DateTime.now());
      _weatherError = "";
    } catch (_) {
      _weatherError = "Error cargando clima";
    }

    _weatherLoading = false;
    setState(() {});
  }

  // ------------------------------------------------------------
  List<ReminderHive> _dedupForHome(List<ReminderHive> list) {
    final map = <String, ReminderHive>{};

    for (final r in list) {
      final base = r.title.replaceFirst("Pronto: ", "").trim();
      final dt = DateTime.tryParse(r.dateIso);
      if (dt == null) continue;

      if (!map.containsKey(base)) {
        map[base] = r;
      } else {
        final prev = map[base]!;
        final prevDt = DateTime.parse(prev.dateIso);
        if (dt.isBefore(prevDt)) map[base] = r;
      }
    }
    return map.values.toList();
  }

  // ------------------------------------------------------------
  Future<void> _loadReminders() async {
    final box = Hive.box<ReminderHive>('reminders');
    final now = DateTime.now();

    final cleaned = CleanupServiceHiveV7.clean(box.values.toList(), now);

    final horizon = now.add(const Duration(days: 7));
    final upcoming = cleaned.where((r) {
      final dt = DateTime.tryParse(r.dateIso);
      return dt != null && dt.isAfter(now) && dt.isBefore(horizon);
    }).toList();

    final deduped = _dedupForHome(upcoming)
      ..sort(
        (a, b) =>
            DateTime.parse(a.dateIso).compareTo(DateTime.parse(b.dateIso)),
      );

    _upcoming = deduped;
    setState(() {});
  }

  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final moodLabel = _slimeMood?.label ?? "Auri está atenta a todo 💜";

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: SiriVoiceButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        title: const Text("Auri"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF16001F), Color(0xFF09000F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        // -------------------------
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ----------------------------------------------
                // CABEZERA
                // ----------------------------------------------
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Hola, $_userName 👋",
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Auri está lista para tu día ✨",
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ----------------------------------------------
                // SLIME + HUD
                // ----------------------------------------------
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (_slimeMood?.baseColor ?? cs.primary)
                              .withOpacity(0.2),
                          boxShadow: [
                            BoxShadow(
                              color: (_slimeMood?.baseColor ?? cs.primary)
                                  .withOpacity(0.5),
                              blurRadius: 40,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      AuriSlimePlaceholder(
                        mouthEnergy: _slimeMouthEnergy,
                        wobble: _slimeMood?.wobble ?? 0.5,
                        glowColor: _slimeMood?.baseColor ?? cs.primary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                AuriJarvisHud(
                  onLipSync: (e) => setState(() => _slimeMouthEnergy = e),
                ),

                const SizedBox(height: 10),

                Text(
                  moodLabel,
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 26),

                // ----------------------------------------------
                // WEATHER + OUTFIT
                // ----------------------------------------------
                if (_weatherLoading)
                  const CircularProgressIndicator()
                else if (_weatherError.isNotEmpty)
                  _ErrorCard(message: _weatherError)
                else if (_weather != null)
                  Column(
                    children: [
                      _GlassCard(
                        child: WeatherDisplayGlass(
                          weather: _weather!,
                          onRefresh: _loadWeather,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GlassCard(
                        child: OutfitRecommendationGlass(
                          weather: _weather!,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.outfitPage,
                              arguments: {"weather": _weather},
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 28),

                // ----------------------------------------------
                // RECORDATORIOS
                // ----------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Próximos recordatorios",
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.reminders),
                      child: Text(
                        "Ver todos",
                        style: TextStyle(color: cs.primary),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                if (_upcoming.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "¡No tienes recordatorios próximos!",
                      style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                    ),
                  )
                else
                  Column(
                    children: _upcoming
                        .take(4)
                        .map((r) => _ReminderGlassItem(r: r, cs: cs))
                        .toList(),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: cs.primary.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ReminderGlassItem extends StatelessWidget {
  final ReminderHive r;
  final ColorScheme cs;

  const _ReminderGlassItem({required this.r, required this.cs});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(r.dateIso);
    final formatted = dt != null
        ? "${dt.day}/${dt.month}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}"
        : "Fecha inválida";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.alarm, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "${r.title} – $formatted",
              style: TextStyle(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

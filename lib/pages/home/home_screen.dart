// lib/pages/home/home_screen.dart

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
//import 'package:auri_app/auri/mind/auri_mind_engine.dart';
import 'package:auri_app/auri/voice/voice_session_controller.dart';
import 'package:auri_app/widgets/siri_voice_button.dart';
//import 'package:auri_app/auri/voice/live_tts_engine.dart';
import 'package:auri_app/services/realtime/auri_realtime.dart';
import 'package:auri_app/auri/ui/jarvis_hud.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _userCity = '';
  double _slimeMouthEnergy = 0.0; // para animar la boca del slime
  String _thinkingText = "";
  String jarvisText = ""; // si lo necesitas después

  final WeatherService _weatherService = WeatherService();
  WeatherModel? _weather;
  bool _weatherLoading = true;
  String _weatherError = '';

  SlimeMood? _slimeMood;

  List<ReminderHive> _upcoming = [];
  @override
  void initState() {
    super.initState();

    // 1. Conectar WebSocket Jarvis
    AuriRealtime.instance.connect("192.168.1.42");

    final rt = AuriRealtime.instance;

    // --------- PARCIAL (texto mientras piensa) ----------
    rt.addOnPartial((txt) {
      setState(() {
        _thinkingText = txt;
      });
    });

    // --------- FINAL (respuesta completa) ----------
    rt.addOnFinal((txt) {
      print("💬 Jarvis final: $txt");
      // Aquí puedes usarlo para HUD o resumen
    });

    // --------- THINKING ----------
    rt.addOnThinking((isThinking) {
      SlimeMoodEngine.setVoiceState(isThinking ? "thinking" : "idle");
    });

    // --------- LIP SYNC → slime -----------
    rt.addOnLip((energy) {
      setState(() {
        _slimeMouthEnergy = energy;
      });
    });

    // --------- ACCIONES -----------
    rt.addOnAction((rem) {
      print("📌 Jarvis quiere crear recordatorio: $rem");
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName') ?? "Usuario";
    _userCity = prefs.getString('userCity') ?? "";

    setState(() {});

    await _loadWeather();
    await _loadReminders();
  }

  Future<void> _loadWeather() async {
    if (_userCity.trim().isEmpty) {
      _weatherError = "Configura tu ciudad en ajustes.";
      _weatherLoading = false;
      setState(() {});
      return;
    }

    try {
      final w = await _weatherService.getWeather(_userCity);
      final mood = SlimeMoodEngine.fromWeather(w, DateTime.now());

      _weather = w;
      _slimeMood = mood;
      _weatherError = "";
    } catch (_) {
      _weatherError = "Error cargando clima";
    }

    _weatherLoading = false;
    setState(() {});
  }

  List<ReminderHive> _dedupForHome(List<ReminderHive> list) {
    final map = <String, ReminderHive>{};

    for (final r in list) {
      final baseTitle = r.title.replaceFirst("Pronto: ", "").trim();
      final date = DateTime.tryParse(r.dateIso);
      if (date == null) continue;

      if (!map.containsKey(baseTitle)) {
        map[baseTitle] = r;
      } else {
        final existing = map[baseTitle]!;
        final existingDate = DateTime.tryParse(existing.dateIso) ?? date;
        if (date.isBefore(existingDate)) {
          map[baseTitle] = r;
        }
      }
    }

    return map.values.toList();
  }

  Future<void> _loadReminders() async {
    final box = Hive.box<ReminderHive>('reminders');
    final now = DateTime.now();

    final cleaned = CleanupServiceHiveV7.clean(
      box.values.cast<ReminderHive>().toList(),
      now,
    );

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 360;

    final moodLabel = _slimeMood?.label ?? "Auri está atenta a todo 💜";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Auri"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.settings);
              await _loadData();
            },
          ),
        ],
      ),

      // BOTÓN DE VOZ AGREGADO AQUÍ
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: SiriVoiceButton(),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF16001F), Color(0xFF09000F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hola, $_userName 👋",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Auri está lista para tu día ✨",
                  style: TextStyle(
                    fontSize: 16,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 22),

                Center(
                  child: Column(
                    children: [
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
                                    .withOpacity(0.22),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_slimeMood?.baseColor ?? cs.primary)
                                        .withOpacity(0.7),
                                    blurRadius: 40,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                            AuriSlimePlaceholder(
                              mouthEnergy:
                                  _slimeMouthEnergy, // se actualiza con JarvisHUD
                              wobble:
                                  _slimeMood?.wobble ??
                                  0.5, // usa el mood si existe
                              glowColor: _slimeMood?.baseColor ?? cs.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      AuriJarvisHud(
                        ip: "192.168.1.42",
                        onLipSync: (e) => setState(() => _slimeMouthEnergy = e),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        moodLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                if (_weatherLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_weatherError.isNotEmpty)
                  _ErrorCard(message: _weatherError)
                else if (_weather != null)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useColumn = constraints.maxWidth < 480 || isNarrow;
                      final w = _weather!;

                      final weatherCard = _GlassCard(
                        child: WeatherDisplayGlass(
                          weather: w,
                          onRefresh: () => _loadWeather(),
                        ),
                      );

                      final outfitCard = _GlassCard(
                        child: OutfitRecommendationGlass(
                          weather: w,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.outfitPage,
                              arguments: {"weather": w},
                            );
                          },
                        ),
                      );

                      if (useColumn) {
                        return Column(
                          children: [
                            weatherCard,
                            const SizedBox(height: 14),
                            outfitCard,
                          ],
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: weatherCard),
                            const SizedBox(width: 14),
                            Expanded(child: outfitCard),
                          ],
                        );
                      }
                    },
                  ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Próximos recordatorios",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.reminders),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Ver todos",
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                if (_upcoming.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        "¡No tienes recordatorios próximos! ✨",
                        style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                      ),
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

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: cs.primary.withOpacity(0.35),
                width: 0.8,
              ),
            ),
            child: child,
          ),
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
        ? "${dt.day}/${dt.month}   ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}"
        : "Fecha inválida";

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.primary.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withOpacity(0.3),
                  ),
                  child: const Icon(Icons.alarm, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Vence: $formatted",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceButton extends StatefulWidget {
  @override
  State<_VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<_VoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulse = Tween<double>(
      begin: 0.9,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ScaleTransition(
      scale: _pulse,
      child: GestureDetector(
        onTap: () async {
          // Aquí arrancará la sesión de voz
          await VoiceSessionController.startRecording();
        },
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                cs.primary.withOpacity(0.8),
                cs.primary.withOpacity(0.35),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.6),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 32),
        ),
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

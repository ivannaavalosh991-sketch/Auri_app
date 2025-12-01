// -------------------------------------------------------------
// HOME SCREEN — Versión Estable V8 (FINAL)
// Fix global anti-overflow + Weather/Outfit sizing + hora local
// Realtime estabilizado + Ajustes Float + UI perfectamente estable
// -------------------------------------------------------------

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

// MODELS
import 'package:auri_app/models/reminder_hive.dart';
import 'package:auri_app/models/weather_model.dart';

// SERVICES
import 'package:auri_app/services/cleanup_service_v7_hive.dart';
import 'package:auri_app/services/weather_service.dart';
import 'package:auri_app/services/context/context_builder.dart';
import 'package:auri_app/services/realtime/auri_realtime.dart';
import 'package:auri_app/services/slime_mood_engine.dart';

// WIDGETS
import 'package:auri_app/widgets/auri_slime_placeholder.dart';
import 'package:auri_app/widgets/weather_display_glass.dart';
import 'package:auri_app/widgets/outfit_recommendation_glass.dart';
import 'package:auri_app/widgets/siri_voice_button.dart';
import 'package:auri_app/auri/ui/jarvis_hud.dart';

// ROUTER
import 'package:auri_app/routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _userCity = '';

  String _thinkingText = "";
  double _slimeMouthEnergy = 0.0;

  final WeatherService _weatherService = WeatherService();
  WeatherModel? _weather;
  bool _weatherLoading = true;
  String _weatherError = '';

  SlimeMood? _slimeMood;
  List<ReminderHive> _upcoming = [];

  bool _listenersAttached = false;

  // ============================================================
  // INIT
  // ============================================================
  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  Future<void> _initAsync() async {
    await ContextBuilder.buildAndSync(); // Hora local aplicada internamente
    AuriRealtime.instance.markContextReady();
    await AuriRealtime.instance.ensureConnected();
    _attachRealtimeListeners();
    await _loadData();
  }

  // ============================================================
  // LISTENERS
  // ============================================================
  void _attachRealtimeListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    final rt = AuriRealtime.instance;

    rt.addOnPartial((txt) {
      if (!mounted) return;
      setState(() => _thinkingText = txt);
    });

    rt.addOnFinal((txt) {
      if (!mounted) return;
      setState(() => _thinkingText = "");
    });

    rt.addOnThinking((isThinking) {
      SlimeMoodEngine.setVoiceState(isThinking ? "thinking" : "idle");
    });

    // LIPSYNC — CONTROL TOTAL
    Timer? lipThrottle;
    rt.addOnLip((energy) {
      if (lipThrottle?.isActive ?? false) return;
      lipThrottle = Timer(const Duration(milliseconds: 55), () {
        if (!mounted) return;
        setState(() => _slimeMouthEnergy = energy);
      });
    });

    rt.addOnAction((data) {
      if (!mounted) return;
      final action = data["action"];
      if (action == "open_weather") {
        Navigator.pushNamed(context, AppRoutes.weatherPage);
      } else if (action == "open_outfit") {
        Navigator.pushNamed(
          context,
          AppRoutes.outfitPage,
          arguments: {"weather": _weather},
        );
      }
    });
  }

  // ============================================================
  // LOADERS
  // ============================================================
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
      _weatherError = "Configura tu ciudad en Ajustes.";
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

  Future<void> _loadReminders() async {
    final box = Hive.box<ReminderHive>('reminders');
    final now = DateTime.now().toLocal(); // 100% HORA LOCAL

    final cleaned = CleanupServiceHiveV7.clean(box.values.toList(), now);

    final horizon = now.add(const Duration(days: 7));
    final upcoming = cleaned.where((r) {
      final dt = DateTime.tryParse(r.dateIso)?.toLocal();
      return dt != null && dt.isAfter(now) && dt.isBefore(horizon);
    }).toList();

    final deduped = _dedupForHome(upcoming)
      ..sort((a, b) {
        final ad = DateTime.parse(a.dateIso).toLocal();
        final bd = DateTime.parse(b.dateIso).toLocal();
        return ad.compareTo(bd);
      });

    _upcoming = deduped;
    setState(() {});
  }

  List<ReminderHive> _dedupForHome(List<ReminderHive> list) {
    final map = <String, ReminderHive>{};

    for (final r in list) {
      final base = r.title.replaceFirst("Pronto: ", "").trim();
      final dt = DateTime.tryParse(r.dateIso)?.toLocal();
      if (dt == null) continue;

      if (!map.containsKey(base)) {
        map[base] = r;
      } else {
        final prevDt = DateTime.parse(map[base]!.dateIso).toLocal();
        if (dt.isBefore(prevDt)) map[base] = r;
      }
    }
    return map.values.toList();
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: SiriVoiceButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeader(cs),
                  const SizedBox(height: 20),
                  _buildSlime(cs),
                  const SizedBox(height: 26),
                  _buildWeatherAndOutfit(),
                  const SizedBox(height: 26),
                  _buildReminders(cs),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),

          // -------------------------------------------------
          // AJUSTES GLASS FLOAT BUTTON
          // -------------------------------------------------
          Positioned(
            top: 18,
            right: 18,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BACKGROUND
  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF16001F), Color(0xFF09000F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  // HEADERS — overflow-safe
  Widget _buildHeader(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hola, $_userName 👋",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: cs.primary,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "Auri está lista para tu día ✨",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 16),
        ),
      ],
    );
  }

  // SLIME + HUD
  Widget _buildSlime(ColorScheme cs) {
    final moodLabel = _slimeMood?.label ?? "Auri está atenta a ti 💜";

    return Column(
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
                  color: (_slimeMood?.baseColor ?? cs.primary).withOpacity(0.2),
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
        const SizedBox(height: 8),
        AuriJarvisHud(onLipSync: (e) => setState(() => _slimeMouthEnergy = e)),
        const SizedBox(height: 8),
        Text(
          moodLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 14),
        ),
      ],
    );
  }

  // WEATHER + OUTFIT
  Widget _buildWeatherAndOutfit() {
    if (_weatherLoading) return const CircularProgressIndicator();
    if (_weatherError.isNotEmpty) return _ErrorCard(message: _weatherError);
    if (_weather == null) return const SizedBox.shrink();

    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _GlassCard(
            child: WeatherDisplayGlass(
              weather: _weather!,
              onRefresh: _loadWeather,
            ),
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _GlassCard(
            child: OutfitRecommendationGlass(
              weather: _weather!,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.outfitPage,
                arguments: {"weather": _weather},
              ),
            ),
          ),
        ),
      ],
    );
  }

  // REMINDERS — overflow proof
  Widget _buildReminders(ColorScheme cs) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Próximos recordatorios",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.reminders),
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text("Ver todos", style: TextStyle(color: cs.primary)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_upcoming.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "No tienes recordatorios próximos ✨",
              style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
            ),
          )
        else
          Column(
            children: _upcoming.take(4).map((r) {
              final dt = DateTime.tryParse(r.dateIso)?.toLocal();
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: cs.onSurface),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// SMALL CARDS
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: cs.primary.withOpacity(0.35)),
          ),
          child: child,
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

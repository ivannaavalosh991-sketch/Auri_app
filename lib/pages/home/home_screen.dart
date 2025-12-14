// -------------------------------------------------------------
// HOME SCREEN — Versión Estable V8.1 (patched, NO rebuild)
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
import 'package:auri_app/widgets/weather_display_glass.dart';
import 'package:auri_app/widgets/outfit_recommendation_glass.dart';
import 'package:auri_app/widgets/siri_voice_button.dart';
import 'package:auri_app/auri/ui/jarvis_hud.dart';
import 'package:auri_app/widgets/slime/slime_engine_widget.dart';

import 'package:auri_app/services/subscription_remote_service.dart';

// ROUTER
import 'package:auri_app/routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ✅ Para detectar cuando vuelves al Home (foreground) y re-sincronizar plan.
class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String _userName = '';
  String _userCity = '';
  String _plan = 'free';

  double _slimeMouthEnergy = 0.0;

  final WeatherService _weatherService = WeatherService();
  WeatherModel? _weather;
  bool _weatherLoading = true;
  String _weatherError = '';

  SlimeMood? _slimeMood;
  List<ReminderHive> _upcoming = [];

  bool _listenersAttached = false;

  bool get _isPro => _plan == 'pro' || _plan == 'ultra';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuriRealtime.instance.markContextReady();

    _initAsync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ Cuando la app vuelve al foreground, re-leemos plan por seguridad.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPlanFromPrefs(); // 🔥 evita que se quede pegado
    }
  }

  Future<void> _initAsync() async {
    // 🔥 1) BACKEND → prefs
    await SubscriptionRemoteService.syncPlanFromBackend();

    // 🔥 2) prefs → Home UI
    await _syncPlanFromPrefs();

    // 3) Context + realtime (sin cambios)
    await ContextBuilder.buildAndSync();
    AuriRealtime.instance.markContextReady();
    await AuriRealtime.instance.ensureConnected();

    _attachRealtimeListeners();
    await _loadData();
  }

  // ============================================================
  // PLAN — SINGLE SOURCE OF TRUTH
  // ============================================================
  Future<void> _syncPlanFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPlan = prefs.getString('auri_plan') ?? 'free';

    // Normaliza por si guardaron "PRO" o "Ultra"
    final normalized = savedPlan.trim().toLowerCase();

    debugPrint("🔄 HOME PLAN SYNC: $normalized");

    if (!mounted) return;
    if (_plan == normalized) return; // evita rebuild innecesario

    setState(() {
      _plan = normalized;
    });
  }

  Future<void> _openSubscription() async {
    final result = await Navigator.pushNamed(context, AppRoutes.subscription);

    if (!mounted) return;

    // ✅ Si subscription devolvió plan, lo aplicamos directo
    if (result is String) {
      final normalized = result.trim().toLowerCase();
      debugPrint("⬅️ PLAN DEVUELTO DESDE SUBSCRIPTION: $normalized");
      setState(() => _plan = normalized);
      return;
    }

    // ✅ Fallback: si no devolvió nada, re-leer desde prefs
    await _syncPlanFromPrefs();
  }

  // ============================================================
  // REALTIME
  // ============================================================
  void _attachRealtimeListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    final rt = AuriRealtime.instance;

    rt.addOnThinking(
      (isThinking) =>
          SlimeMoodEngine.setVoiceState(isThinking ? "thinking" : "idle"),
    );

    Timer? lipThrottle;
    rt.addOnLip((energy) {
      if (lipThrottle?.isActive ?? false) return;
      lipThrottle = Timer(const Duration(milliseconds: 55), () {
        if (!mounted) return;
        setState(() => _slimeMouthEnergy = energy);
      });
    });
  }

  // ============================================================
  // LOADERS
  // ============================================================
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName') ?? "Usuario";
    _userCity = prefs.getString('userCity') ?? "";

    // 🚫 IMPORTANTÍSIMO: aquí NO se toca _plan (evita bug de pegado)
    await _loadWeather();
    await _loadReminders();

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadWeather() async {
    _weatherLoading = true;
    _weatherError = "";
    _weather = null;

    if (_userCity.trim().isEmpty) {
      _weatherError = "Configura tu ciudad en Ajustes.";
      _weatherLoading = false;
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
  }

  Future<void> _loadReminders() async {
    final box = Hive.box<ReminderHive>('reminders');
    final now = DateTime.now().toLocal(); // 100% hora local

    final cleaned = CleanupServiceHiveV7.clean(box.values.toList(), now);
    final horizon = now.add(const Duration(days: 7));

    final upcoming = cleaned.where((r) {
      final dt = DateTime.tryParse(r.dateIso)?.toLocal();
      return dt != null && dt.isAfter(now) && dt.isBefore(horizon);
    }).toList();

    // ✅ Mantener tu dedupe original (si no lo quieres, lo quitamos)
    _upcoming = _dedupForHome(upcoming)
      ..sort((a, b) {
        final ad = DateTime.parse(a.dateIso).toLocal();
        final bd = DateTime.parse(b.dateIso).toLocal();
        return ad.compareTo(bd);
      });
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

          // AJUSTES (NO TOCAR POSICIÓN)
          Positioned(
            top: 18,
            right: 18,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque, // ✅ asegura tap
              onTap: () async {
                // Abre settings
                await Navigator.pushNamed(context, AppRoutes.settings);
                // ✅ al volver, re-sincroniza plan (si cambió en settings)
                if (!mounted) return;
                await _syncPlanFromPrefs();
              },
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

  Widget _buildBackground() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF16001F), Color(0xFF09000F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
  );

  // ------------------------------------------------------------
  // HEADER (PLAN SIEMPRE VISIBLE)
  // ------------------------------------------------------------
  Widget _buildHeader(ColorScheme cs) {
    final normalized = _plan.trim().toLowerCase();
    final label = normalized == 'pro'
        ? 'PRO'
        : normalized == 'ultra'
        ? 'ULTRA'
        : 'FREE';

    final gradient = normalized == 'free'
        ? [Colors.grey, Colors.grey.shade400]
        : normalized == 'pro'
        ? [const Color(0xFFFFD54F), const Color(0xFFFFB300)]
        : [const Color(0xFF9C27B0), const Color(0xFF673AB7)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                "Hola, $_userName 👋",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Auri está lista para tu día ✨",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 16),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SLIME + CTA SUTIL
  // ------------------------------------------------------------
  Widget _buildSlime(ColorScheme cs) {
    final moodLabel = _slimeMood?.label ?? "Auri está atenta a ti 💜";

    return Column(
      children: [
        if (!_isPro)
          GestureDetector(
            onTap: _openSubscription,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: const Text(
                "Hazte PRO ✨",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        SizedBox(
          width: 180,
          height: 180,
          child: SlimeEngineWidget(
            color: _slimeMood?.baseColor ?? Colors.purpleAccent,
            emotion: _slimeMood?.emoji ?? "🙂",
            moodWobble: _slimeMood?.wobble ?? 0.5,
            voiceEnergy: _slimeMouthEnergy,
          ),
        ),
        const SizedBox(height: 8),
        AuriJarvisHud(onLipSync: (e) => setState(() => _slimeMouthEnergy = e)),
        const SizedBox(height: 8),
        Text(
          moodLabel,
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildWeatherAndOutfit() {
    if (_weatherLoading) return const CircularProgressIndicator();
    if (_weatherError.isNotEmpty) return Text(_weatherError);
    if (_weather == null) return const SizedBox.shrink();

    return Column(
      children: [
        WeatherDisplayGlass(weather: _weather!, onRefresh: _loadWeather),
        const SizedBox(height: 14),
        OutfitRecommendationGlass(
          weather: _weather!,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.outfitPage,
            arguments: {"weather": _weather},
          ),
        ),
      ],
    );
  }

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
                padding: const EdgeInsets.only(left: 8),
                child: Text("Ver todos", style: TextStyle(color: cs.primary)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_upcoming.isEmpty)
          Text(
            "No tienes recordatorios próximos ✨",
            style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
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

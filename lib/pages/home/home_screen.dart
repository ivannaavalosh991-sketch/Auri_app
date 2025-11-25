// lib/pages/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auri_app/models/reminder_hive.dart';
import 'package:auri_app/widgets/auri_visual.dart';
import 'package:auri_app/widgets/weather_display.dart';
import 'package:auri_app/widgets/outfit_recommendation.dart';
import 'package:auri_app/services/weather_service.dart';
import 'package:auri_app/models/weather_model.dart';
import 'package:auri_app/routes/app_routes.dart';
import 'package:auri_app/services/cleanup_service_v7_hive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _userCity = '';

  final WeatherService _weatherService = WeatherService();
  WeatherModel? _weather;

  bool _weatherLoading = true;
  String _weatherError = '';

  List<ReminderHive> _upcoming = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadData());
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName') ?? "Usuario";
    _userCity = prefs.getString('userCity') ?? "";

    if (!mounted) return;
    setState(() {});

    await _loadWeather();
    await _loadReminders();
  }

  Future<void> _loadWeather() async {
    if (_userCity.isEmpty) {
      _weatherError = "Configura tu ciudad en ajustes.";
      _weatherLoading = false;
      if (!mounted) return;
      setState(() {});
      return;
    }

    try {
      final w = await _weatherService.getWeather(_userCity);
      _weather = w;
      _weatherError = '';
    } catch (_) {
      _weatherError = "Error cargando clima";
    }

    _weatherLoading = false;
    if (!mounted) return;
    setState(() {});
  }

  /// Agrupa recordatorios por "baseTitle" (sin el prefijo "Pronto: ")
  /// y se queda con el que ocurra primero. Así evitamos que en el HOME
  /// se vean duplicados tipo:
  ///   - "Pronto: Pago Netflix"
  ///   - "Pago Netflix"
  /// a la vez.
  List<ReminderHive> _dedupForHome(List<ReminderHive> list) {
    final map = <String, ReminderHive>{};

    for (final r in list) {
      final baseTitle = r.title.replaceFirst("Pronto: ", "").trim();

      DateTime? date;
      try {
        date = DateTime.parse(r.dateIso);
      } catch (_) {
        continue;
      }

      if (!map.containsKey(baseTitle)) {
        map[baseTitle] = r;
      } else {
        final existing = map[baseTitle]!;
        final existingDate = DateTime.parse(existing.dateIso);

        // Nos quedamos con el más cercano en el tiempo (el más próximo)
        if (date.isBefore(existingDate)) {
          map[baseTitle] = r;
        }
      }
    }

    return map.values.toList();
  }

  Future<void> _loadReminders() async {
    final box = Hive.box<ReminderHive>('reminders');
    final all = box.values.cast<ReminderHive>().toList();

    final now = DateTime.now();

    // Limpieza por si algo quedó desactualizado
    final cleaned = CleanupServiceHiveV7.clean(all, now);

    // Ventana de 7 días hacia adelante para el HOME
    final horizon = now.add(const Duration(days: 7));

    final filtered = cleaned.where((r) {
      final dt = DateTime.tryParse(r.dateIso);
      return dt != null && dt.isAfter(now) && dt.isBefore(horizon);
    }).toList();

    final deduped = _dedupForHome(filtered)
      ..sort((a, b) {
        final da = DateTime.parse(a.dateIso);
        final db = DateTime.parse(b.dateIso);
        return da.compareTo(db);
      });

    _upcoming = deduped;

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Auri: Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.settings);
              await loadData();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hola, $_userName",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Tu asistente Auri tiene tu día bajo control.",
              style: TextStyle(
                fontSize: 16,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 25),

            if (_weatherLoading)
              const Center(child: CircularProgressIndicator())
            else if (_weatherError.isNotEmpty)
              _ErrorCard(message: _weatherError)
            else if (_weather != null)
              WeatherDisplay(cityName: _userCity),

            const SizedBox(height: 20),

            if (_weather != null)
              OutfitRecommendationWidget(
                temperature: _weather!.temperature,
                condition: _weather!.condition,
                onTap: () {},
              ),

            const SizedBox(height: 25),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Próximos Recordatorios',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.alarm),
                  label: const Text("Ver Todos"),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.reminders);
                  },
                ),
              ],
            ),

            if (_upcoming.isEmpty)
              Padding(
                padding: const EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    "¡No tienes recordatorios pendientes en los próximos días! ✨",
                    style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                  ),
                ),
              )
            else
              ..._upcoming.map((r) => _ReminderItem(r: r, cs: cs)),

            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  const SizedBox(width: 100, height: 100, child: AuriVisual()),
                  const SizedBox(height: 10),
                  Text(
                    "Auri está lista para ayudarte.",
                    style: TextStyle(color: cs.onSurface.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderItem extends StatelessWidget {
  final ReminderHive r;
  final ColorScheme cs;

  const _ReminderItem({required this.r, required this.cs});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(r.dateIso);
    final formatted = date != null
        ? "${date.day}/${date.month} "
              "${date.hour.toString().padLeft(2, '0')}:"
              "${date.minute.toString().padLeft(2, '0')}"
        : "Fecha inválida";

    return Card(
      color: cs.surface.withOpacity(0.1),
      child: ListTile(
        leading: const Icon(Icons.alarm, color: Colors.purpleAccent),
        title: Text(r.title, overflow: TextOverflow.ellipsis),
        subtitle: Text("Vence: $formatted"),
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
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

// lib/pages/weather/weather_page.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auri_app/models/weather_model.dart';
import 'package:auri_app/services/weather_service.dart';
import 'package:auri_app/widgets/auri_slime_placeholder.dart';
import 'package:auri_app/widgets/weather_display_glass.dart';
import 'package:auri_app/services/slime_mood_engine.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _weatherService = WeatherService();
  WeatherModel? _weather;
  String _error = '';
  bool _loading = true;
  SlimeMood? _mood;

  @override
  void initState() {
    super.initState();
    _loadInitialWeather();
  }

  Future<void> _loadInitialWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('userCity') ?? "Ciudad";
    await _fetchWeather(city);
  }

  Future<void> _fetchWeather(String city) async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final w = await _weatherService.getWeather(city);
      final mood = SlimeMoodEngine.fromWeather(w, DateTime.now());

      setState(() {
        _weather = w;
        _mood = mood;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "No se pudo obtener el clima para $city.";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Clima con Auri"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: _buildBody(cs),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return _ErrorCard(message: _error);
    }

    if (_weather == null) {
      return const Center(child: Text("No hay datos de clima disponibles."));
    }

    final w = _weather!;
    final mood = _mood ?? SlimeMoodEngine.fromWeather(w, DateTime.now());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABECERA: Slime + mood
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: mood.baseColor.withOpacity(0.35),
                        boxShadow: [
                          BoxShadow(
                            color: mood.baseColor.withOpacity(
                              0.5 + 0.4 * mood.glowIntensity,
                            ),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    AuriSlimePlaceholder(
                      mouthEnergy: 0, // no hay voz aquí
                      wobble: mood.wobble,
                      glowColor: mood.baseColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: cs.primary.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${mood.emoji} Estado de Auri",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.secondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mood.label,
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurface.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Tarjeta principal de clima
          WeatherDisplayGlass(
            weather: w,
            onRefresh: () => _fetchWeather(w.cityName),
          ),

          const SizedBox(height: 20),

          // Detalles extendidos
          _GlassDetailsCard(weather: w),
        ],
      ),
    );
  }
}

class _GlassDetailsCard extends StatelessWidget {
  final WeatherModel weather;

  const _GlassDetailsCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: cs.primary.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Detalles del día",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.thermostat, color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Sensación general: ${weather.outfitSuggestion}",
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.water_drop, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Humedad: ${weather.humidity}%",
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.air, color: Colors.cyanAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Viento: ${weather.windSpeed} m/s",
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.cloud_outlined, color: cs.secondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Condición: ${weather.description}",
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.redAccent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 10),
            Flexible(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

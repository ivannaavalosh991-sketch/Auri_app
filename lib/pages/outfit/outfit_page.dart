// lib/pages/outfit/outfit_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:auri_app/models/weather_model.dart';
import 'package:auri_app/widgets/auri_slime_placeholder.dart';
import 'package:auri_app/services/slime_mood_engine.dart';
import 'package:auri_app/services/outfit_engine.dart';
import 'package:auri_app/widgets/slime/slime_engine_widget.dart';

class OutfitPage extends StatefulWidget {
  final WeatherModel weather;

  const OutfitPage({super.key, required this.weather});

  @override
  State<OutfitPage> createState() => _OutfitPageState();
}

class _OutfitPageState extends State<OutfitPage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> fade;
  late Animation<Offset> slide;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    fade = CurvedAnimation(parent: controller, curve: Curves.easeOut);

    slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weather = widget.weather;
    final mood = SlimeMoodEngine.fromWeather(weather, DateTime.now());
    final accessory = OutfitEngine.pickAccessory(weather);

    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 700;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Outfit recomendado"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              mood.baseColor.withOpacity(0.38),
              Colors.black.withOpacity(0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
          child: FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: Column(
                children: [
                  // --- SLIME HEADER ---
                  Row(
                    children: [
                      SizedBox(
                        width: isWide ? 160 : 130,
                        height: isWide ? 160 : 130,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: isWide ? 160 : 130,
                              height: isWide ? 160 : 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: mood.baseColor.withOpacity(0.4),
                                boxShadow: [
                                  BoxShadow(
                                    color: mood.baseColor.withOpacity(
                                      0.65 + mood.glowIntensity * 0.3,
                                    ),
                                    blurRadius: 50,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),

                            // BASE SLIME
                            SlimeEngineWidget(
                              color: mood.baseColor,
                              emotion: mood
                                  .emoji, // usamos el emoji como estado emocional
                              moodWobble: mood.wobble,
                              voiceEnergy: 0, // Outfit no usa TTS
                            ),

                            // ACCESSORY
                            if (accessory != null)
                              Positioned(
                                top: 0,
                                child: Text(
                                  accessory.emoji,
                                  style: const TextStyle(fontSize: 42),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Auri viste contigo",
                              style: TextStyle(
                                fontSize: isWide ? 26 : 22,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${weather.cityName} • ${weather.temperature.toStringAsFixed(1)}°C",
                              style: TextStyle(
                                fontSize: 15,
                                color: cs.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- MAIN OUTFIT CARD ---
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          OutfitEngine.title(weather),
                          style: TextStyle(
                            fontSize: isWide ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          OutfitEngine.description(weather),
                          style: TextStyle(
                            fontSize: 15,
                            color: cs.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- MOOD CARD ---
                  _GlassCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mood.emoji, style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            mood.label,
                            style: TextStyle(
                              fontSize: 15,
                              color: cs.onSurface.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Notas de estilo",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: cs.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _StyleTip(
                    icon: Icons.checkroom_outlined,
                    tip: "Usa capas si el clima cambia durante el día.",
                    color: cs.secondary,
                  ),
                  _StyleTip(
                    icon: Icons.palette_outlined,
                    tip: "Combina tonos tierra con algo más vivo.",
                    color: cs.secondary,
                  ),
                  _StyleTip(
                    icon: Icons.light_mode_outlined,
                    tip: "Si hay sol fuerte: gorra o lentes.",
                    color: cs.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// --- Glass Card ---
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: cs.primary.withOpacity(0.35)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// --- Style Tip ---
class _StyleTip extends StatelessWidget {
  final IconData icon;
  final String tip;
  final Color color;

  const _StyleTip({required this.icon, required this.tip, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.88),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

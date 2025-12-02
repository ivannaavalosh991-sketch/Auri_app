// ignore_for_file: prefer_const_constructors

import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/weather_model.dart';

class OutfitRecommendationGlass extends StatelessWidget {
  final WeatherModel weather;
  final VoidCallback? onTap;

  const OutfitRecommendationGlass({
    super.key,
    required this.weather,
    this.onTap,
  });

  String _title() {
    final t = weather.temperature;
    final c = weather.condition.toLowerCase();

    if (c.contains('rain')) return "Listo para la lluvia";
    if (c.contains('snow')) return "Abrigo extremo";
    if (t >= 28) return "Verano intenso";
    if (t >= 20) return "Look ligero";
    if (t >= 14) return "Capas suaves";
    return "Ropa abrigada";
  }

  String _description() {
    final t = weather.temperature;
    final c = weather.condition.toLowerCase();

    if (c.contains('rain')) {
      return "Chamarra impermeable y colores oscuros.";
    }
    if (c.contains('snow')) {
      return "Abrigo grueso, bufanda y guantes.";
    }
    if (t >= 28) {
      return "Ropa muy ligera, hidrátate.";
    }
    if (t >= 20) {
      return "Look cómodo y fresco.";
    }
    if (t >= 14) {
      return "Chaqueta ligera es ideal.";
    }
    return "Usa abrigo o ropa térmica.";
  }

  String _icon() {
    final c = weather.condition.toLowerCase();
    if (c.contains('rain')) return "🌧️";
    if (c.contains('snow')) return "❄️";
    if (c.contains('cloud')) return "☁️";
    if (c.contains('clear')) return "☀️";
    return "👕";
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: cs.primary.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ICON
                Text(_icon(), style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 8),

                // TITLE
                Text(
                  _title(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 5),

                // DESCRIPTION
                Text(
                  _description(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withOpacity(0.75),
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

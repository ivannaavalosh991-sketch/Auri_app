import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:auri_app/models/weather_model.dart';

class WeatherDisplayGlass extends StatelessWidget {
  final WeatherModel weather;
  final VoidCallback? onRefresh;

  const WeatherDisplayGlass({super.key, required this.weather, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: weather.moodColor.withOpacity(0.45),
              width: 1.3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                alignment: Alignment.centerLeft,
                child: Text(
                  weather.cityName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // 🔹 Descripción limitada
              Text(
                weather.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withOpacity(0.65),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(weather.emoji, style: const TextStyle(fontSize: 40)),
                  Text(
                    "${weather.temperature.round()}°C",
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(Icons.air, size: 18),
                  const SizedBox(width: 6),

                  // 🔥 Esto evita overflows horizontales
                  Expanded(
                    child: Text(
                      "${weather.windSpeed} m/s  •  ${weather.humidity}% humedad",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              GestureDetector(
                onTap: onRefresh,
                child: Text(
                  "Actualizar",
                  style: TextStyle(
                    color: cs.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

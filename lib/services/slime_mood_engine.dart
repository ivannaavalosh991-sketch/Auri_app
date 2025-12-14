// lib/services/slime_mood_engine.dart

import 'package:flutter/material.dart';
import 'package:auri_app/models/weather_model.dart';

class SlimeMood {
  final Color baseColor;
  final double glowIntensity; // 0–1
  final double wobble; // 0–1 (qué tanto se mueve)
  final String label; // texto que mostramos debajo de Auri
  final String emoji; // estado visual rápido

  const SlimeMood({
    required this.baseColor,
    required this.glowIntensity,
    required this.wobble,
    required this.label,
    required this.emoji,
  });
}

class SlimeMoodEngine {
  /// ======================================================================
  /// 1) Estado según clima (tu implementación original)
  /// ======================================================================
  static SlimeMood fromWeather(WeatherModel weather, DateTime now) {
    final hour = now.hour;
    final isNight = hour < 6 || hour >= 21;
    final c = weather.condition.toLowerCase();
    final t = weather.temperature;

    // 🌧️ Lluvia
    if (c.contains('rain') || c.contains('drizzle')) {
      return SlimeMood(
        baseColor: Colors.blueAccent.shade200,
        glowIntensity: 0.7,
        wobble: 0.45,
        label: isNight
            ? "Auri está calmada viendo la lluvia nocturna 🌧️"
            : "Auri está en modo lluvia, pero pendiente de tus pendientes 🌧️",
        emoji: "🌧️",
      );
    }

    // ❄️ Nieve
    if (c.contains('snow')) {
      return SlimeMood(
        baseColor: Colors.lightBlue.shade200,
        glowIntensity: 0.8,
        wobble: 0.35,
        label: "Auri está esponjosa y abrigada ❄️",
        emoji: "❄️",
      );
    }

    // ⛈️ Tormenta
    if (c.contains('thunder')) {
      return SlimeMood(
        baseColor: Colors.deepPurpleAccent,
        glowIntensity: 0.95,
        wobble: 0.75,
        label:
            "Auri está alerta por la tormenta, pero tiene todo bajo control ⚡",
        emoji: "⛈️",
      );
    }

    // ☀️ Mucho calor
    if (t >= 30) {
      return SlimeMood(
        baseColor: Colors.orangeAccent.shade200,
        glowIntensity: 0.9,
        wobble: 0.6,
        label: "Auri está energética, pero te recuerda hidratarte ☀️",
        emoji: "🔥",
      );
    }

    // 🌤️ Soleado
    if (c.contains('clear')) {
      return SlimeMood(
        baseColor: Colors.purpleAccent,
        glowIntensity: 0.85,
        wobble: 0.55,
        label: "Auri está feliz, es un buen día para avanzar cosas 😎",
        emoji: "😎",
      );
    }

    // ☁️ Nublado
    if (c.contains('cloud')) {
      return SlimeMood(
        baseColor: Colors.indigoAccent,
        glowIntensity: 0.6,
        wobble: 0.4,
        label: "Auri está relajada, día perfecto para concentrarse ☁️",
        emoji: "☁️",
      );
    }

    // 🧊 Frío fuerte
    if (t <= 10) {
      return SlimeMood(
        baseColor: Colors.blueGrey.shade300,
        glowIntensity: 0.5,
        wobble: 0.3,
        label: "Auri está acurrucada con suéter imaginario 🧣",
        emoji: "🥶",
      );
    }

    // Default
    return SlimeMood(
      baseColor: Colors.purpleAccent,
      glowIntensity: 0.7,
      wobble: 0.5,
      label: "Auri está en modo asistente, lista para ayudarte ✨",
      emoji: "💫",
    );
  }

  /// ======================================================================
  /// 2) Estado según emociones del backend AuriMind (NUEVO)
  /// ======================================================================
  static SlimeMood fromEmotionSnapshot(Map<String, dynamic> e) {
    final overall = (e["overall"] ?? "neutral").toString();
    final stress = (e["stress"] ?? 0.2) as double;
    final energy = (e["energy"] ?? 0.5) as double;

    Color color;
    double glow;
    double wobble;
    String label;
    String emoji;

    switch (overall) {
      case "happy":
      case "excited":
        color = Colors.purpleAccent;
        glow = 0.9;
        wobble = 0.7 + (energy * 0.2);
        label = "Auri está emocionada ✨";
        emoji = "✨";
        break;

      case "sad":
      case "depressed":
        color = Colors.blueGrey.shade300;
        glow = 0.3;
        wobble = 0.1 + (energy * 0.1);
        label = "Auri está sintiendo tu tristeza 💜";
        emoji = "🥺";
        break;

      case "angry":
        color = Colors.redAccent;
        glow = 0.7;
        wobble = 0.2;
        label = "Auri percibe tensión ⚡";
        emoji = "😡";
        break;

      case "anxious":
        color = Colors.indigoAccent;
        glow = 0.5;
        wobble = 0.3 + (stress * 0.4);
        label = "Auri está preocupada por ti 🫂";
        emoji = "😰";
        break;

      case "tired":
      case "sleepy":
        color = Colors.blueGrey.shade200;
        glow = 0.2;
        wobble = 0.1;
        label = "Auri está con energía bajita 😴";
        emoji = "😴";
        break;

      default:
        color = Colors.purpleAccent;
        glow = 0.6;
        wobble = 0.4 + (energy * 0.2);
        label = "Auri está contigo 💜";
        emoji = "💜";
    }

    return SlimeMood(
      baseColor: color,
      glowIntensity: glow,
      wobble: wobble,
      label: label,
      emoji: emoji,
    );
  }

  /// Solo logs por ahora
  static void setVoiceState(String state) {
    print("🎙 Auri voice-state → $state");
  }
}

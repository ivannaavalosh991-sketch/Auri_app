// lib/auri/mind/auri_brain_v3.dart

import 'package:auri_app/auri/memory/memory_manager.dart';
import 'package:auri_app/auri/memory/memory_models.dart';

class AuriBrainV3 {
  AuriBrainV3._();
  static final AuriBrainV3 instance = AuriBrainV3._();

  // Estado emocional interno
  double warmth = 0.8; // calidez
  double energy = 0.6; // energía
  double softness = 0.7; // ternura

  // --------------------------------------------------------
  // Procesa respuesta final y la hace “Auri style”
  // --------------------------------------------------------
  String enhance(String text) {
    _updateEmotionFromMemory();

    final tone = _toneSignature();

    return "$tone $text";
  }

  // --------------------------------------------------------
  // Ajusta emociones basado en memoria
  // --------------------------------------------------------
  void _updateEmotionFromMemory() {
    final positives = AuriMemoryManager.instance.search("positive_interaction");

    if (positives.isNotEmpty) {
      warmth = (warmth + 0.1).clamp(0.0, 1.0);
      softness = (softness + 0.1).clamp(0.0, 1.0);
    }

    final stress = AuriMemoryManager.instance.search("user_stress");
    if (stress.isNotEmpty) {
      energy = (energy - 0.1).clamp(0.0, 1.0);
      softness = (softness + 0.2).clamp(0.0, 1.0);
    }
  }

  // --------------------------------------------------------
  // Firma tonal de Auri
  // --------------------------------------------------------
  String _toneSignature() {
    String w = warmth > 0.7
        ? "💜 (suave y cercano)"
        : warmth > 0.4
        ? "✨ (amigable)"
        : "…";

    String e = energy > 0.7 ? "⚡" : "";

    String s = softness > 0.7 ? "🌙" : "";

    return "$w$e$s";
  }
}

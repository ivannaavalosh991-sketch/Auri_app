// Outfit Page
import 'package:flutter/material.dart';
import '../services/outfit_service.dart';
import '../models/outfit_model.dart';

class OutfitPage extends StatelessWidget {
  final double temperature;
  final String condition;

  const OutfitPage({
    super.key,
    required this.temperature,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    // Instancia el servicio y obtiene la recomendación
    final OutfitService outfitService = OutfitService();
    final OutfitRecommendation recommendation = outfitService.getRecommendation(
      temperature,
      condition,
    );

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estilo y Outfits 💫'),
        backgroundColor: colorScheme.surface.withOpacity(0.1),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recomendación de Auri para hoy',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Tarjeta de Recomendación Principal (Diseño Estético)
            _OutfitCard(
              recommendation: recommendation,
              colorScheme: colorScheme,
            ),

            const SizedBox(height: 30),

            // Sección de Notas de Estilo
            Text(
              'Notas de Estilo Adicionales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 10),

            // Consejos adicionales (Simulación de "inteligencia" de Auri)
            _StyleTip(
              icon: Icons.access_time_filled,
              tip:
                  'El clima de hoy (${condition}) sugiere que podrías necesitar un ajuste al anochecer.',
              colorScheme: colorScheme,
            ),
            _StyleTip(
              icon: Icons.palette,
              tip:
                  'Auri recomienda colores neutros o tonos tierra para un look moderno y equilibrado.',
              colorScheme: colorScheme,
            ),
            _StyleTip(
              icon: Icons.lightbulb_outline,
              tip:
                  'Añade un accesorio (reloj o collar minimalista) para elevar tu outfit.',
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para la tarjeta principal
class _OutfitCard extends StatelessWidget {
  final OutfitRecommendation recommendation;
  final ColorScheme colorScheme;

  const _OutfitCard({required this.recommendation, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(recommendation.icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 10),
          Text(
            recommendation.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            recommendation.description,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
            softWrap: true,
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para las notas de estilo
class _StyleTip extends StatelessWidget {
  final IconData icon;
  final String tip;
  final ColorScheme colorScheme;

  const _StyleTip({
    required this.icon,
    required this.tip,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.secondary, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurface.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para la Recomendación de Outfits de Auri
import 'package:flutter/material.dart';
import '../models/outfit_model.dart';

class OutfitRecommendationWidget extends StatelessWidget {
  final double temperature; // Temperatura actual en Celsius
  final String condition; // Condición climática principal (Ej: 'Clear', 'Rain')
  final VoidCallback? onTap;

  const OutfitRecommendationWidget({
    super.key,
    required this.temperature,
    required this.condition,
    this.onTap,
  });

  // 1. Lógica de recomendación del outfit
  OutfitRecommendation _getRecommendation() {
    final lowerCondition = condition.toLowerCase();

    if (lowerCondition.contains('rain') || lowerCondition.contains('drizzle')) {
      return const OutfitRecommendation(
        title: 'Listo para el Aguacero ☔',
        description:
            'Vístete en capas resistentes al agua y no olvides tu paraguas. ¡El estilo no se moja!',
        icon: '🌧️',
      );
    }
    if (lowerCondition.contains('snow') || lowerCondition.contains('sleet')) {
      return const OutfitRecommendation(
        title: 'Abrigado y Cómodo 🧣',
        description:
            'Usa ropa térmica, un abrigo pesado y calzado impermeable. ¡Mantén el calor!',
        icon: '❄️',
      );
    }
    if (lowerCondition.contains('thunderstorm')) {
      return const OutfitRecommendation(
        title: 'Máxima Precaución ⚠️',
        description:
            'Mejor quedarse en casa hoy. Si tienes que salir, lleva algo cómodo y ligero.',
        icon: '⛈️',
      );
    }

    if (temperature >= 30) {
      return const OutfitRecommendation(
        title: 'Verano, Estilo Fluido ☀️',
        description:
            'Ropa muy ligera, lino, algodón fresco. Colores claros para reflejar el sol. ¡Hidrátate!',
        icon: '🌡️',
      );
    } else if (temperature >= 20) {
      return const OutfitRecommendation(
        title: 'Casual y Ligero 🍃',
        description:
            'Jeans, camisa ligera o camiseta elegante. Perfecto para un día activo sin sobrecalentarse.',
        icon: '👕',
      );
    } else if (temperature >= 10) {
      return const OutfitRecommendation(
        title: 'Capas Ligeras 👌',
        description:
            'Una chaqueta delgada o un suéter elegante serán suficientes. Ideal para las mañanas frías.',
        icon: '🧥',
      );
    } else {
      return const OutfitRecommendation(
        title: 'Moda de Invierno 🧤',
        description:
            'Abrigo grueso, gorro y guantes. ¡El frío es el momento perfecto para ese abrigo llamativo!',
        icon: '🥶',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = _getRecommendation();
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: colorScheme.surface.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.primary.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu Outfit Recomendado por Auri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            recommendation.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

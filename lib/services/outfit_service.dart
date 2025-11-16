// Outfit Service
import '../models/outfit_model.dart';

class OutfitService {
  // 1. Lógica de recomendación del outfit centralizada
  OutfitRecommendation getRecommendation(double temperature, String condition) {
    final lowerCondition = condition.toLowerCase();

    // Prioridad 1: Condiciones Extremas
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

    // Prioridad 2: Recomendaciones por Temperatura
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
      // Aquí podrías añadir lógica para la hora del día o las preferencias del usuario
    } else if (temperature >= 10) {
      return const OutfitRecommendation(
        title: 'Capas Ligeras 👌',
        description:
            'Una chaqueta delgada o un suéter elegante serán suficientes. Ideal para las mañanas frías.',
        icon: '🧥',
      );
    } else {
      // Menos de 10 grados
      return const OutfitRecommendation(
        title: 'Moda de Invierno 🧤',
        description:
            'Abrigo grueso, gorro y guantes. ¡El frío es el momento perfecto para ese abrigo llamativo!',
        icon: '🥶',
      );
    }
  }

  // Futura función: obtener outfits guardados, tendencias de moda, etc.
}

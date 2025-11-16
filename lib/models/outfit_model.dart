// Outfit Model
// Clase base para definir una recomendación de outfit simple para Auri.
class OutfitRecommendation {
  // Título corto de la recomendación (Ej: "Casual y Ligero")
  final String title;
  // Descripción detallada del outfit
  final String description;
  // Ícono o emoji asociado al outfit
  final String icon;

  const OutfitRecommendation({
    required this.title,
    required this.description,
    required this.icon,
  });
}

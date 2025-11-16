class WeatherModel {
  // 1. Las propiedades que nos interesan de la API
  final String cityName;
  final double temperature;
  final String mainCondition; // Ej: "Clear", "Clouds", "Rain"
  final String icon; // El código del icono (ej. "04d")

  // 2. Un constructor para inicializar estas propiedades
  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.icon,
  });

  // 3. El 'factory constructor' (la parte MÁS importante)
  // Este método sabe cómo "leer" el JSON de OpenWeatherMap
  // y convertirlo en un objeto WeatherModel.
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    // Así es como navegamos dentro del JSON que nos da la API
    return WeatherModel(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
      mainCondition: json['weather'][0]['main'],
      icon: json['weather'][0]['icon'],
    );
  }

  // (Opcional) Un método helper para obtener la URL completa del icono
  String get iconUrl {
    return 'https://openweathermap.org/img/wn/$icon@4x.png';
  }
}

import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherDisplay extends StatefulWidget {
  final String cityName;

  const WeatherDisplay({super.key, required this.cityName});

  @override
  State<WeatherDisplay> createState() => _WeatherDisplayState();
}

class _WeatherDisplayState extends State<WeatherDisplay> {
  final _weatherService = WeatherService();
  WeatherModel? _weather;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Inicia la carga del clima usando la ciudad recibida
    fetchWeather(widget.cityName);
  }

  // Si la ciudad cambia (aunque no debería en esta implementación), recarga.
  @override
  void didUpdateWidget(covariant WeatherDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cityName != widget.cityName) {
      fetchWeather(widget.cityName);
    }
  }

  void fetchWeather(String city) async {
    // Verificar si la ciudad es válida o solo espacios en blanco
    if (city.trim().isEmpty || city.toLowerCase() == 'ciudad desconocida') {
      setState(() {
        _errorMessage = 'Por favor, especifica una ciudad en la Encuesta.';
        _weather = null;
      });
      return;
    }

    setState(() {
      _weather = null; // Reinicia para mostrar el indicador de carga
      _errorMessage = '';
    });

    try {
      final weatherData = await _weatherService.getWeather(city);
      setState(() {
        _weather = weatherData;
      });
    } catch (e) {
      // Capturar la excepción (ej. Ciudad no encontrada, Error de API Key)
      print("Error fetching weather: $e");
      setState(() {
        _errorMessage = 'No se pudo obtener el clima para ${city}.';
      });
    }
  }

  // Método auxiliar para el icono
  String getWeatherIcon(String mainCondition) {
    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return '☁️';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'clear':
        return '☀️';
      default:
        return '❓';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Mostrar Error
    if (_errorMessage.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ Error al cargar el clima',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(_errorMessage, style: const TextStyle(fontSize: 14)),
          ],
        ),
      );
    }

    // 2. Mostrar Carga
    if (_weather == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 3. Mostrar Datos del Clima
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ciudad
              Text(
                _weather!.cityName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              // Condición
              Text(
                _weather!.mainCondition.toUpperCase(),
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              // Botón de recarga
              GestureDetector(
                onTap: () => fetchWeather(widget.cityName),
                child: const Text(
                  'Recargar',
                  style: TextStyle(
                    color: Colors.tealAccent,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),

          Row(
            children: [
              // Icono del clima
              Text(
                getWeatherIcon(_weather!.mainCondition),
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 10),
              // Temperatura
              Text(
                '${_weather!.temperature.round()}°C',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

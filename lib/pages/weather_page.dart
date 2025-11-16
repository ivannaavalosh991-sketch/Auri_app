import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  // 1. Instancia del servicio
  final _weatherService = WeatherService();

  // 2. Variables de estado
  WeatherModel? _weather;
  String _errorMessage = '';

  // 3. Método para obtener el clima
  // Nota: Usamos una ciudad de ejemplo ('Mexico City')
  void fetchWeather(String city) async {
    // Limpiar errores y poner estado de carga
    setState(() {
      _weather = null;
      _errorMessage = '';
    });

    try {
      final weatherData = await _weatherService.getWeather(city);
      setState(() {
        _weather = weatherData;
      });
    } catch (e) {
      // Capturar la excepción del servicio
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  // 4. Inicialización
  @override
  void initState() {
    super.initState();
    // Llamar a la función al iniciar la página
    fetchWeather("Mexico City");
  }

  // 5. Método auxiliar para el icono
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
        return '🌧️';

      case 'thunderstorm':
        return '⛈️';

      case 'clear':
        return '☀️';

      case 'snow':
        return '❄️';

      default:
        return '🌡️';
    }
  }

  // 6. Construcción de la UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi App del Clima'),
        actions: [
          IconButton(
            onPressed: () => fetchWeather("Mexico City"), // Recargar
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const SizedBox(height: 10),
            // Mostrar Error
            if (_errorMessage.isNotEmpty)
              Text(
                'Error: $_errorMessage',
                style: const TextStyle(color: Colors.red),
              ),

            // Mostrar Carga
            if (_weather == null && _errorMessage.isEmpty)
              const CircularProgressIndicator(),

            // Mostrar Datos del Clima
            if (_weather != null) ...[
              // Nombre de la Ciudad
              Text(
                _weather!.cityName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Icono del clima
              Text(
                getWeatherIcon(_weather!.mainCondition),
                style: const TextStyle(fontSize: 64),
              ),

              // Condición principal
              Text(_weather!.mainCondition),

              // Temperatura
              Text(
                '${_weather!.temperature.round()}°C',
                style: const TextStyle(fontSize: 48),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ¡Importante! Dependerá de nuestro modelo

class WeatherService {
  // URL base de la API de OpenWeatherMap
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  // Tu API Key (¡DEBES REEMPLAZAR ESTO CON TU PROPIA CLAVE!)
  final String apiKey = dotenv.env['API_KEY'] ?? 'API_KEY_NO_ENCONTRADA';

  // --- Método principal para obtener el clima ---
  Future<WeatherModel> getWeather(String cityName) async {
    // 1. Construir la URL completa con los parámetros
    // (q=ciudad, appid=clave, units=metric para Celsius)
    final uri = Uri.parse(
      '$_baseUrl?q=$cityName&appid=$apiKey&units=metric&lang=es',
    );

    // 2. Realizar la petición GET
    try {
      final response = await http.get(uri);

      // 3. Verificar si la respuesta fue exitosa (Código 200)
      if (response.statusCode == 200) {
        // 4. Decodificar el JSON (el texto de la respuesta)
        final json = jsonDecode(response.body);

        // 5. Convertir el JSON a nuestro objeto WeatherModel
        // Usamos un 'factory constructor' llamado 'fromJson'
        // (que definiremos en el modelo)
        return WeatherModel.fromJson(json);
      } else {
        // 6. Si el servidor responde con un error (ej. 404 Ciudad no encontrada)
        // Lanza una excepción que la UI (la vista) deberá capturar.
        throw Exception(
          'Error al cargar el clima. Código: ${response.statusCode}',
        );
      }
    } catch (e) {
      // 7. Capturar errores de red (ej. sin internet o la URL está mal)
      throw Exception('Error de conexión: $e');
    }
  }

  // (Opcional) Método para obtener la ciudad actual basada en geolocalización
  // (Esto requeriría otro paquete como 'geolocator' y es más avanzado)
}

import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackendConfig {
  static String get baseUrl {
    final env = dotenv.env['BACKEND_ENV'] ?? 'dev';
    if (env == 'prod') {
      return dotenv.env['BACKEND_HTTP_PROD']!;
    } else {
      return dotenv.env['BACKEND_HTTP_DEV']!;
    }
  }

  static String get wsUrl {
    final env = dotenv.env['BACKEND_ENV'] ?? 'dev';
    if (env == 'prod') {
      return dotenv.env['BACKEND_WS_PROD']!;
    } else {
      return dotenv.env['BACKEND_WS_DEV']!;
    }
  }
}

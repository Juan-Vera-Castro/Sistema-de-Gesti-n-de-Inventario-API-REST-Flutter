import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración global de la aplicación leída desde el archivo `.env`.
class AppConfig {
  AppConfig._();

  static const String appName = 'Inventario';
  static const String _defaultBaseUrl = 'http://10.0.2.2:3000/api';
  static const int _defaultTimeoutMs = 10000;

  /// Carga las variables de entorno. Debe llamarse antes de `runApp`.
  static Future<void> load() => dotenv.load(fileName: '.env');

  /// URL base de la API REST, sin barra final.
  static String get apiBaseUrl {
    final url = dotenv.maybeGet('API_BASE_URL', fallback: _defaultBaseUrl)!;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static Duration get apiTimeout {
    final ms = int.tryParse(dotenv.maybeGet('API_TIMEOUT_MS') ?? '');
    return Duration(milliseconds: ms ?? _defaultTimeoutMs);
  }
}

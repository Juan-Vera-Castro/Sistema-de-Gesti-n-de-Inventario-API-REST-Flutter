import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Crea la instancia de Dio compartida por todos los servicios.
Dio createApiClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.apiTimeout,
      receiveTimeout: AppConfig.apiTimeout,
      sendTimeout: kIsWeb ? null : AppConfig.apiTimeout,
      headers: {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: false, logPrint: (o) => debugPrint('$o')),
    );
  }
  return dio;
}

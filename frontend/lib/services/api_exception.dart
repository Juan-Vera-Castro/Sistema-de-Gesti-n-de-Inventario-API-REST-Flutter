import 'package:dio/dio.dart';

/// Error de red o de la API traducido a un mensaje comprensible para el usuario.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;

  /// Errores por campo devueltos por la API (respuesta 422).
  final Map<String, String> fieldErrors;

  bool get isNotFound => statusCode == 404;
  bool get isValidation => statusCode == 422;

  factory ApiException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException('El servidor tardó demasiado en responder. Intenta de nuevo.');
      case DioExceptionType.connectionError:
        return const ApiException(
          'No se pudo conectar con el servidor. Verifica que la API esté en ejecución y la URL en .env.',
        );
      case DioExceptionType.cancel:
        return const ApiException('La petición fue cancelada.');
      case DioExceptionType.badCertificate:
        return const ApiException('Certificado del servidor no válido.');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return _fromResponse(error.response);
    }
  }

  static ApiException _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode;
    final data = response?.data;

    String? message;
    var fieldErrors = <String, String>{};
    if (data is Map<String, dynamic>) {
      message = data['message'] as String?;
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        fieldErrors = errors.map((campo, detalle) => MapEntry(campo, '$detalle'));
      }
    }

    message ??= switch (status) {
      400 => 'La petición no es válida.',
      404 => 'El recurso solicitado no existe.',
      422 => 'Los datos enviados no son válidos.',
      final int s when s >= 500 => 'Error interno del servidor. Intenta más tarde.',
      _ => 'Ocurrió un error inesperado de red.',
    };

    return ApiException(message, statusCode: status, fieldErrors: fieldErrors);
  }

  @override
  String toString() => message;
}

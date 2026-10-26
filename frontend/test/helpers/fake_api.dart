import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:inventario_app/services/producto_service.dart';

typedef FakeHandler = ({int status, Object body}) Function(RequestOptions options);

/// Adaptador HTTP que responde sin red, para probar servicios y vistas.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final FakeHandler handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final result = handler(options);
    return ResponseBody.fromString(
      jsonEncode(result.body),
      result.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ProductoService fakeService(FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test/api'))..httpClientAdapter = adapter;
  return ProductoService(dio: dio);
}

Map<String, Object?> productoJson(int id, {double precio = 1000, int cantidad = 2}) => {
  'id': id,
  'nombre': 'Producto $id',
  'codigo': 'COD-$id',
  'descripcion': null,
  'precio': precio,
  'cantidad': cantidad,
  'categoria': 'General',
  'creado_en': '2026-10-26T20:00:00.000Z',
  'actualizado_en': '2026-10-26T20:00:00.000Z',
};

Map<String, Object?> ok(Object? data) => {'success': true, 'message': 'ok', 'data': data};

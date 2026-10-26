import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/inventario_resumen.dart';
import '../models/producto.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Único punto de acceso al recurso `/productos` de la API.
/// Las vistas nunca usan Dio directamente: siempre pasan por este servicio.
class ProductoService {
  ProductoService({Dio? dio}) : _dio = dio ?? createApiClient();

  final Dio _dio;
  static const _path = '/productos';

  /// Se incrementa tras cada creación, edición o eliminación para que
  /// el Dashboard y el listado se recarguen automáticamente.
  final ValueNotifier<int> cambios = ValueNotifier(0);

  Future<List<Producto>> listar() {
    return _send(
      () => _dio.get(_path),
      (data) => (data as List<dynamic>).map((item) => Producto.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  Future<Producto> obtener(int id) {
    return _send(() => _dio.get('$_path/$id'), _parseProducto);
  }

  Future<Producto> crear(Producto producto) async {
    final creado = await _send(() => _dio.post(_path, data: producto.toJson()), _parseProducto);
    _notificarCambio();
    return creado;
  }

  Future<Producto> actualizar(int id, Producto producto) async {
    final actualizado = await _send(() => _dio.put('$_path/$id', data: producto.toJson()), _parseProducto);
    _notificarCambio();
    return actualizado;
  }

  Future<void> eliminar(int id) async {
    await _send(() => _dio.delete('$_path/$id'), (_) {});
    _notificarCambio();
  }

  Future<InventarioResumen> obtenerResumen() async {
    return InventarioResumen.fromProductos(await listar());
  }

  static Producto _parseProducto(dynamic data) => Producto.fromJson(data as Map<String, dynamic>);

  void _notificarCambio() => cambios.value++;

  /// Ejecuta la petición, desempaqueta `data` del formato estándar de la API,
  /// la convierte con [parse] y traduce cualquier fallo a [ApiException].
  Future<T> _send<T>(Future<Response<dynamic>> Function() request, T Function(dynamic data) parse) async {
    try {
      final response = await request();
      final body = response.data;
      if (body is! Map<String, dynamic> || body['success'] != true) {
        throw const ApiException('Respuesta inesperada del servidor.');
      }
      return parse(body['data']);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    } on TypeError {
      // fromJson con campos ausentes o de tipo distinto al esperado.
      throw const ApiException('El servidor devolvió datos con un formato inesperado.');
    }
  }
}

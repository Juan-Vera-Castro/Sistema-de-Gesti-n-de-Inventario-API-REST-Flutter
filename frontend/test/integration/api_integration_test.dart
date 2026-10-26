// Prueba de integración contra la API real (backend en ejecución).
// Se omite salvo que se defina la variable de entorno API_BASE_URL:
//   API_BASE_URL=http://localhost:3000/api flutter test test/integration
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/models/producto.dart';
import 'package:inventario_app/services/api_exception.dart';
import 'package:inventario_app/services/producto_service.dart';

void main() {
  final baseUrl = Platform.environment['API_BASE_URL'];

  test('CRUD completo de productos contra la API', () async {
    final service = ProductoService(dio: Dio(BaseOptions(baseUrl: baseUrl!)));
    final codigo = 'INT-${DateTime.now().millisecondsSinceEpoch}';
    final nuevo = Producto(
      nombre: 'Producto de integración',
      codigo: codigo,
      precio: 1234.5,
      cantidad: 3,
      categoria: 'Pruebas',
    );

    final antes = await service.obtenerResumen();

    final creado = await service.crear(nuevo);
    expect(creado.id, isNotNull);
    expect(creado.codigo, codigo);

    final despues = await service.obtenerResumen();
    expect(despues.totalProductos, antes.totalProductos + 1);
    expect(despues.totalUnidades, antes.totalUnidades + 3);

    await expectLater(
      service.crear(nuevo),
      throwsA(isA<ApiException>().having((e) => e.fieldErrors.containsKey('codigo'), 'codigo duplicado', true)),
    );

    final editado = await service.actualizar(
      creado.id!,
      Producto(nombre: 'Editado', codigo: codigo, precio: 10, cantidad: 0, categoria: 'Pruebas'),
    );
    expect(editado.nombre, 'Editado');
    expect((await service.obtener(creado.id!)).cantidad, 0);

    await service.eliminar(creado.id!);
    await expectLater(
      service.obtener(creado.id!),
      throwsA(isA<ApiException>().having((e) => e.isNotFound, 'isNotFound', true)),
    );
  }, skip: baseUrl == null ? 'Define API_BASE_URL para ejecutar la prueba de integración' : false);
}

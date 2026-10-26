import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/models/producto.dart';
import 'package:inventario_app/services/api_exception.dart';

import 'helpers/fake_api.dart';

void main() {
  test('listar desempaqueta data del formato estándar', () async {
    final adapter = FakeAdapter(
      (_) => (
        status: 200,
        body: {
          ...ok([productoJson(1), productoJson(2)]),
          'total': 2,
        },
      ),
    );
    final productos = await fakeService(adapter).listar();
    expect(productos.map((p) => p.id), [1, 2]);
    expect(adapter.requests.single.path, '/productos');
  });

  test('un 422 se traduce en ApiException con errores por campo', () async {
    final adapter = FakeAdapter(
      (_) => (
        status: 422,
        body: {
          'success': false,
          'message': 'Los datos del producto no son válidos',
          'errors': {'codigo': 'Ya existe un producto con este código'},
        },
      ),
    );
    final service = fakeService(adapter);
    final producto = Producto.fromJson(productoJson(1));

    await expectLater(
      service.crear(producto),
      throwsA(
        isA<ApiException>()
            .having((e) => e.isValidation, 'isValidation', true)
            .having((e) => e.fieldErrors['codigo'], 'codigo', isNotNull),
      ),
    );
    expect(service.cambios.value, 0, reason: 'un fallo no debe notificar cambios');
  });

  test('crear, actualizar y eliminar usan el método HTTP correcto y notifican cambios', () async {
    final adapter = FakeAdapter((o) => (status: o.method == 'POST' ? 201 : 200, body: ok(productoJson(7))));
    final service = fakeService(adapter);
    final producto = Producto.fromJson(productoJson(7));

    await service.crear(producto);
    await service.actualizar(7, producto);
    await service.eliminar(7);

    expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
      'POST /productos',
      'PUT /productos/7',
      'DELETE /productos/7',
    ]);
    expect(service.cambios.value, 3);
  });
}

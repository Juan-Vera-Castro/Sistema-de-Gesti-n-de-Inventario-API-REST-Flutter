import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/models/inventario_resumen.dart';
import 'package:inventario_app/models/producto.dart';

import 'helpers/fake_api.dart';

void main() {
  group('Producto', () {
    test('fromJson convierte números enteros y fechas', () {
      final p = Producto.fromJson(productoJson(1, precio: 2500, cantidad: 4));
      expect(p.id, 1);
      expect(p.precio, 2500.0);
      expect(p.cantidad, 4);
      expect(p.creadoEn, DateTime.utc(2026, 10, 26, 20));
      expect(p.valorTotal, 10000);
    });

    test('toJson solo envía los campos editables', () {
      final json = Producto.fromJson(productoJson(1)).toJson();
      expect(json.keys, unorderedEquals(['nombre', 'codigo', 'descripcion', 'precio', 'cantidad', 'categoria']));
    });
  });

  test('InventarioResumen calcula las tres métricas', () {
    final productos = [
      Producto.fromJson(productoJson(1, precio: 1000, cantidad: 3)),
      Producto.fromJson(productoJson(2, precio: 250.5, cantidad: 2)),
      Producto.fromJson(productoJson(3, precio: 9000, cantidad: 0)),
    ];
    final resumen = InventarioResumen.fromProductos(productos);
    expect(resumen.totalProductos, 3);
    expect(resumen.totalUnidades, 5);
    expect(resumen.valorTotal, 3501);
    expect(resumen.productosAgotados, 1);
  });
}

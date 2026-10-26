import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/config/formatters.dart';
import 'package:inventario_app/views/dashboard_view.dart';
import 'package:inventario_app/views/productos_list_view.dart';

import 'helpers/fake_api.dart';

Widget _app(Widget home) => MaterialApp(home: home);

void main() {
  testWidgets('Dashboard muestra las tres métricas calculadas', (tester) async {
    final adapter = FakeAdapter(
      (_) => (
        status: 200,
        body: ok([productoJson(1, precio: 1000, cantidad: 3), productoJson(2, precio: 500, cantidad: 4)]),
      ),
    );
    await tester.pumpWidget(_app(DashboardView(service: fakeService(adapter))));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Productos registrados'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text(Formatters.moneda(5000)), findsOneWidget);
  });

  testWidgets('Listado muestra estado vacío', (tester) async {
    final adapter = FakeAdapter((_) => (status: 200, body: ok([])));
    await tester.pumpWidget(_app(ProductosListView(service: fakeService(adapter))));
    await tester.pumpAndSettle();
    expect(find.text('No hay productos registrados'), findsOneWidget);
  });

  testWidgets('Listado muestra error con opción de reintentar', (tester) async {
    final adapter = FakeAdapter(
      (_) => (status: 500, body: {'success': false, 'message': 'Error interno del servidor'}),
    );
    await tester.pumpWidget(_app(ProductosListView(service: fakeService(adapter))));
    await tester.pumpAndSettle();
    expect(find.text('Error interno del servidor'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('Listado muestra nombre, precio y cantidad', (tester) async {
    final adapter = FakeAdapter((_) => (status: 200, body: ok([productoJson(1, precio: 45900, cantidad: 35)])));
    await tester.pumpWidget(_app(ProductosListView(service: fakeService(adapter))));
    await tester.pumpAndSettle();
    expect(find.text('Producto 1'), findsOneWidget);
    expect(find.textContaining(Formatters.moneda(45900)), findsOneWidget);
    expect(find.text('35'), findsOneWidget);
  });
}

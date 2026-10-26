import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/config/formatters.dart';
import 'package:inventario_app/views/dashboard_view.dart';
import 'package:inventario_app/views/producto_form_view.dart';
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

  testWidgets('Actualizar recarga los datos sin errores (Dashboard y listado)', (tester) async {
    final adapter = FakeAdapter((_) => (status: 200, body: ok([productoJson(1)])));
    final service = fakeService(adapter);

    for (final view in [DashboardView(service: service), ProductosListView(service: service)]) {
      adapter.requests.clear();
      await tester.pumpWidget(_app(view));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(adapter.requests, hasLength(2));
    }
  });

  testWidgets('Formulario rechaza precios con separador de miles y no envía la petición', (tester) async {
    final adapter = FakeAdapter((_) => (status: 201, body: ok(productoJson(1))));
    await tester.pumpWidget(_app(ProductoFormView(service: fakeService(adapter))));

    Finder campo(String label) => find.widgetWithText(TextFormField, label);
    await tester.enterText(campo('Nombre *'), 'Cable HDMI');
    await tester.enterText(campo('Código *'), 'TEC-200');
    await tester.enterText(campo('Categoría *'), 'Tecnología');
    await tester.enterText(campo('Precio *'), '1.000');
    await tester.enterText(campo('Cantidad *'), '5');

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Registrar producto'));
    await tester.tap(find.widgetWithText(FilledButton, 'Registrar producto'));
    await tester.pumpAndSettle();

    expect(find.text('Sin puntos de miles; máx. 2 decimales'), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });
}

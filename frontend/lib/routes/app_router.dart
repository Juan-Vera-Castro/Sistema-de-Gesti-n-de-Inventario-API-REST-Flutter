import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/producto.dart';
import '../services/producto_service.dart';
import '../views/dashboard_view.dart';
import '../views/home_shell.dart';
import '../views/producto_detail_view.dart';
import '../views/producto_form_view.dart';
import '../views/productos_list_view.dart';
import '../widgets/state_views.dart';
import 'app_routes.dart';

/// Configuración de go_router.
///
/// `/` y `/productos` son pestañas de la barra inferior; detalle y formularios
/// se abren a pantalla completa sobre el navegador raíz.
GoRouter createRouter(ProductoService service) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: AppRoutes.dashboard,
                builder: (context, state) => DashboardView(service: service),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/productos',
                name: AppRoutes.productos,
                builder: (context, state) => ProductosListView(service: service),
                routes: [
                  GoRoute(
                    path: 'nuevo',
                    name: AppRoutes.productoNuevo,
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => ProductoFormView(service: service),
                  ),
                  GoRoute(
                    path: ':id',
                    name: AppRoutes.productoDetalle,
                    parentNavigatorKey: rootKey,
                    builder: (context, state) =>
                        _conId(state, (id) => ProductoDetailView(key: ValueKey(id), service: service, id: id)),
                    routes: [
                      GoRoute(
                        path: 'editar',
                        name: AppRoutes.productoEditar,
                        parentNavigatorKey: rootKey,
                        builder: (context, state) => _conId(
                          state,
                          (id) => ProductoFormView(
                            service: service,
                            id: id,
                            inicial: state.extra is Producto ? state.extra as Producto : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const _RutaNoEncontrada(),
  );
}

/// Valida que el parámetro `:id` sea numérico antes de construir la pantalla.
Widget _conId(GoRouterState state, Widget Function(int id) builder) {
  final id = int.tryParse(state.pathParameters['id'] ?? '');
  return id == null || id <= 0 ? const _RutaNoEncontrada() : builder(id);
}

class _RutaNoEncontrada extends StatelessWidget {
  const _RutaNoEncontrada();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página no encontrada')),
      body: MessageView(
        icon: Icons.link_off_rounded,
        title: 'La página solicitada no existe',
        actionLabel: 'Ir al inicio',
        actionIcon: Icons.home_rounded,
        onAction: () => context.goNamed(AppRoutes.dashboard),
      ),
    );
  }
}

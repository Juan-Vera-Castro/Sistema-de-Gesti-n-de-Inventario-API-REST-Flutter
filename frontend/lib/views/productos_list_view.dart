import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/producto.dart';
import '../routes/app_routes.dart';
import '../services/producto_service.dart';
import '../widgets/producto_tile.dart';
import '../widgets/state_views.dart';

/// Listado de productos (nombre, precio y cantidad disponible).
class ProductosListView extends StatefulWidget {
  const ProductosListView({super.key, required this.service});

  final ProductoService service;

  @override
  State<ProductosListView> createState() => _ProductosListViewState();
}

class _ProductosListViewState extends State<ProductosListView> {
  late Future<List<Producto>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.listar();
    widget.service.cambios.addListener(_reload);
  }

  @override
  void dispose() {
    widget.service.cambios.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = widget.service.listar();
    });
  }

  Future<void> _refresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {
      // El error se muestra en la vista mediante el FutureBuilder.
    }
  }

  void _nuevo() => context.pushNamed(AppRoutes.productoNuevo);

  void _abrir(Producto producto) {
    context.pushNamed(AppRoutes.productoDetalle, pathParameters: {'id': '${producto.id}'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [IconButton(tooltip: 'Actualizar', icon: const Icon(Icons.refresh), onPressed: _reload)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevo,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: FutureBuilder<List<Producto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const LoadingView(message: 'Cargando productos...');
          }
          if (snapshot.hasError) {
            return ErrorView(message: '${snapshot.error}', onRetry: _reload);
          }

          final productos = snapshot.data ?? const <Producto>[];
          if (productos.isEmpty) {
            return EmptyView(
              title: 'No hay productos registrados',
              message: 'Registra tu primer producto para empezar a controlar el inventario.',
              actionLabel: 'Registrar producto',
              onAction: _nuevo,
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              // Espacio inferior para que el botón flotante no tape el último elemento.
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: productos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final producto = productos[index];
                return ProductoTile(producto: producto, onTap: () => _abrir(producto));
              },
            ),
          );
        },
      ),
    );
  }
}

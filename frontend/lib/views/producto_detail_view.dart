import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/formatters.dart';
import '../models/producto.dart';
import '../routes/app_routes.dart';
import '../services/api_exception.dart';
import '../services/producto_service.dart';
import '../themes/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/state_views.dart';

/// Detalle completo de un producto con acciones de editar y eliminar.
class ProductoDetailView extends StatefulWidget {
  const ProductoDetailView({super.key, required this.service, required this.id});

  final ProductoService service;
  final int id;

  @override
  State<ProductoDetailView> createState() => _ProductoDetailViewState();
}

class _ProductoDetailViewState extends State<ProductoDetailView> {
  late Future<Producto> _future;
  bool _eliminando = false;

  @override
  void initState() {
    super.initState();
    _future = widget.service.obtener(widget.id);
  }

  void _reload() {
    setState(() => _future = widget.service.obtener(widget.id));
  }

  void _salir() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.productos);
    }
  }

  Future<void> _editar(Producto producto) async {
    final actualizado = await context.pushNamed<Producto>(
      AppRoutes.productoEditar,
      pathParameters: {'id': '${widget.id}'},
      extra: producto,
    );
    if (actualizado != null && mounted) {
      setState(() => _future = Future.value(actualizado));
    }
  }

  Future<void> _eliminar(Producto producto) async {
    final confirmado = await showConfirmDialog(
      context,
      title: 'Eliminar producto',
      message:
          '¿Seguro que deseas eliminar "${producto.nombre}" (${producto.codigo})? '
          'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmado || !mounted) return;

    setState(() => _eliminando = true);
    try {
      await widget.service.eliminar(widget.id);
      if (!mounted) return;
      AppSnackbar.success(context, 'Producto "${producto.nombre}" eliminado');
      _salir();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _eliminando = false);
      AppSnackbar.error(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Producto>(
      future: _future,
      builder: (context, snapshot) {
        final producto = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle del producto'),
            actions: [
              if (producto != null) ...[
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _eliminando ? null : () => _editar(producto),
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _eliminando ? null : () => _eliminar(producto),
                ),
              ],
            ],
          ),
          body: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<Producto> snapshot) {
    if (snapshot.hasData) {
      return Stack(
        children: [
          _DetalleContenido(producto: snapshot.data!),
          if (_eliminando) const LinearProgressIndicator(),
        ],
      );
    }
    if (snapshot.hasError) {
      final error = snapshot.error;
      if (error is ApiException && error.isNotFound) {
        return MessageView(
          icon: Icons.search_off_rounded,
          title: 'Producto no encontrado',
          message: error.message,
          actionLabel: 'Volver al listado',
          actionIcon: Icons.arrow_back,
          onAction: _salir,
        );
      }
      return ErrorView(message: '$error', onRetry: _reload);
    }
    return const LoadingView(message: 'Cargando producto...');
  }
}

class _DetalleContenido extends StatelessWidget {
  const _DetalleContenido({required this.producto});

  final Producto producto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stockColor = producto.agotado ? theme.colorScheme.error : AppTheme.success;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(producto.nombre, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(avatar: const Icon(Icons.qr_code_2, size: 18), label: Text(producto.codigo)),
            Chip(avatar: const Icon(Icons.sell_outlined, size: 18), label: Text(producto.categoria)),
            Chip(
              avatar: Icon(Icons.circle, size: 12, color: stockColor),
              label: Text(producto.agotado ? 'Agotado' : 'Disponible'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _Dato(
                icon: Icons.attach_money_rounded,
                label: 'Precio unitario',
                value: Formatters.moneda(producto.precio),
              ),
              const Divider(height: 1),
              _Dato(
                icon: Icons.inventory_rounded,
                label: 'Cantidad disponible',
                value: '${Formatters.entero(producto.cantidad)} unidades',
                valueColor: stockColor,
              ),
              const Divider(height: 1),
              _Dato(
                icon: Icons.payments_rounded,
                label: 'Valor en inventario',
                value: Formatters.moneda(producto.valorTotal),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descripción', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(
                  (producto.descripcion?.isNotEmpty ?? false) ? producto.descripcion! : 'Sin descripción',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _Dato(icon: Icons.tag, label: 'ID', value: '${producto.id}'),
              const Divider(height: 1),
              _Dato(icon: Icons.event_outlined, label: 'Creado', value: Formatters.fecha(producto.creadoEn)),
              const Divider(height: 1),
              _Dato(icon: Icons.update, label: 'Actualizado', value: Formatters.fecha(producto.actualizadoEn)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icon, required this.label, required this.value, this.valueColor});

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: valueColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../config/formatters.dart';
import '../models/producto.dart';
import '../themes/app_theme.dart';

/// Elemento del listado: nombre, precio y cantidad disponible.
class ProductoTile extends StatelessWidget {
  const ProductoTile({super.key, required this.producto, this.onTap});

  final Producto producto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stockColor = producto.agotado ? scheme.error : AppTheme.success;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Text(producto.nombre.characters.first.toUpperCase()),
        ),
        title: Text(producto.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${Formatters.moneda(producto.precio)} · ${producto.categoria}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.entero(producto.cantidad),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: stockColor, fontWeight: FontWeight.bold),
            ),
            Text(producto.agotado ? 'agotado' : 'unidades', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

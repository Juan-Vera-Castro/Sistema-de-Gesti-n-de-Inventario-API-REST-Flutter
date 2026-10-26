import 'producto.dart';

/// Métricas agregadas del inventario que se muestran en el Dashboard.
class InventarioResumen {
  const InventarioResumen({
    required this.totalProductos,
    required this.totalUnidades,
    required this.valorTotal,
    required this.productosAgotados,
  });

  final int totalProductos;
  final int totalUnidades;
  final double valorTotal;
  final int productosAgotados;

  factory InventarioResumen.fromProductos(List<Producto> productos) {
    return InventarioResumen(
      totalProductos: productos.length,
      totalUnidades: productos.fold(0, (suma, p) => suma + p.cantidad),
      valorTotal: productos.fold(0.0, (suma, p) => suma + p.valorTotal),
      productosAgotados: productos.where((p) => p.agotado).length,
    );
  }
}

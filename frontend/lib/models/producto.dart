/// Entidad Producto tal como la expone la API REST.
class Producto {
  const Producto({
    this.id,
    required this.nombre,
    required this.codigo,
    this.descripcion,
    required this.precio,
    required this.cantidad,
    required this.categoria,
    this.creadoEn,
    this.actualizadoEn,
  });

  /// `null` mientras el producto no ha sido creado en el servidor.
  final int? id;
  final String nombre;
  final String codigo;
  final String? descripcion;
  final double precio;
  final int cantidad;
  final String categoria;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  /// Valor económico de las existencias de este producto.
  double get valorTotal => precio * cantidad;

  bool get agotado => cantidad == 0;

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: (json['id'] as num?)?.toInt(),
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String,
      descripcion: json['descripcion'] as String?,
      precio: (json['precio'] as num).toDouble(),
      cantidad: (json['cantidad'] as num).toInt(),
      categoria: json['categoria'] as String,
      creadoEn: DateTime.tryParse(json['creado_en'] as String? ?? ''),
      actualizadoEn: DateTime.tryParse(json['actualizado_en'] as String? ?? ''),
    );
  }

  /// Cuerpo para POST/PUT: solo los campos editables.
  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'codigo': codigo,
        'descripcion': descripcion,
        'precio': precio,
        'cantidad': cantidad,
        'categoria': categoria,
      };
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/producto.dart';
import '../routes/app_routes.dart';
import '../services/api_exception.dart';
import '../services/producto_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/state_views.dart';

/// Formulario de registro (POST) y edición (PUT) de productos.
///
/// Si [id] es `null` crea un producto; si no, lo edita. Para editar usa
/// [inicial] cuando viene desde el detalle o lo consulta a la API si no.
class ProductoFormView extends StatefulWidget {
  const ProductoFormView({super.key, required this.service, this.id, this.inicial});

  final ProductoService service;
  final int? id;
  final Producto? inicial;

  bool get esEdicion => id != null;

  @override
  State<ProductoFormView> createState() => _ProductoFormViewState();
}

class _ProductoFormViewState extends State<ProductoFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _codigo = TextEditingController();
  final _descripcion = TextEditingController();
  final _precio = TextEditingController();
  final _cantidad = TextEditingController();
  final _categoria = TextEditingController();

  /// Errores por campo devueltos por la API (422).
  Map<String, String> _serverErrors = {};
  Future<void>? _carga;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    if (widget.inicial != null) {
      _rellenar(widget.inicial!);
    } else if (widget.esEdicion) {
      _carga = _cargarProducto();
    }
  }

  @override
  void dispose() {
    for (final c in [_nombre, _codigo, _descripcion, _precio, _cantidad, _categoria]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarProducto() async {
    _rellenar(await widget.service.obtener(widget.id!));
  }

  void _rellenar(Producto p) {
    _nombre.text = p.nombre;
    _codigo.text = p.codigo;
    _descripcion.text = p.descripcion ?? '';
    _precio.text = p.precio == p.precio.roundToDouble() ? p.precio.toStringAsFixed(0) : p.precio.toStringAsFixed(2);
    _cantidad.text = '${p.cantidad}';
    _categoria.text = p.categoria;
  }

  /// Entero con hasta 2 decimales (`45900`, `15000,5`, `9.99`). Se rechazan
  /// separadores de miles: `1.000` sería ambiguo (¿mil o uno?).
  static final _formatoPrecio = RegExp(r'^\d+([.,]\d{1,2})?$');

  static double? _parsePrecio(String text) {
    final limpio = text.trim();
    if (!_formatoPrecio.hasMatch(limpio)) return null;
    return double.tryParse(limpio.replaceAll(',', '.'));
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;

    final descripcion = _descripcion.text.trim();
    final producto = Producto(
      nombre: _nombre.text.trim(),
      codigo: _codigo.text.trim(),
      descripcion: descripcion.isEmpty ? null : descripcion,
      precio: _parsePrecio(_precio.text)!,
      cantidad: int.parse(_cantidad.text.trim()),
      categoria: _categoria.text.trim(),
    );

    setState(() => _guardando = true);
    try {
      final guardado = widget.esEdicion
          ? await widget.service.actualizar(widget.id!, producto)
          : await widget.service.crear(producto);
      if (!mounted) return;
      AppSnackbar.success(
        context,
        widget.esEdicion ? 'Producto actualizado correctamente' : 'Producto "${guardado.nombre}" registrado',
      );
      if (context.canPop()) {
        context.pop(guardado);
      } else {
        context.goNamed(AppRoutes.productoDetalle, pathParameters: {'id': '${guardado.id}'});
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _serverErrors = error.fieldErrors;
      });
      AppSnackbar.error(context, error.message);
    }
  }

  void _limpiarErrorServidor(String campo) {
    if (_serverErrors.containsKey(campo)) {
      setState(() => _serverErrors = Map.of(_serverErrors)..remove(campo));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.esEdicion ? 'Editar producto' : 'Registrar producto')),
      body: _carga == null
          ? _buildForm()
          : FutureBuilder<void>(
              future: _carga,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingView(message: 'Cargando datos del producto...');
                }
                if (snapshot.hasError) {
                  return ErrorView(
                    message: '${snapshot.error}',
                    onRetry: () => setState(() {
                      _carga = _cargarProducto();
                    }),
                  );
                }
                return _buildForm();
              },
            ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _campo(
            campo: 'nombre',
            controller: _nombre,
            label: 'Nombre *',
            icon: Icons.label_outline,
            maxLength: 100,
            validator: (v) => _requerido(v, 'el nombre'),
          ),
          _campo(
            campo: 'codigo',
            controller: _codigo,
            label: 'Código *',
            hint: 'Ej. TEC-010',
            icon: Icons.qr_code_2,
            maxLength: 50,
            capitalization: TextCapitalization.characters,
            validator: (v) => _requerido(v, 'el código'),
          ),
          _campo(
            campo: 'categoria',
            controller: _categoria,
            label: 'Categoría *',
            hint: 'Ej. Tecnología',
            icon: Icons.sell_outlined,
            maxLength: 50,
            validator: (v) => _requerido(v, 'la categoría'),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _campo(
                  campo: 'precio',
                  controller: _precio,
                  label: 'Precio *',
                  hint: 'Ej. 45900',
                  icon: Icons.attach_money_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa el precio';
                    final precio = _parsePrecio(v);
                    if (precio == null) return 'Sin puntos de miles; máx. 2 decimales';
                    if (precio <= 0) return 'Debe ser mayor que 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _campo(
                  campo: 'cantidad',
                  controller: _cantidad,
                  label: 'Cantidad *',
                  icon: Icons.inventory_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa la cantidad';
                    final cantidad = int.tryParse(v.trim());
                    if (cantidad == null) return 'Debe ser un entero';
                    if (cantidad < 0) return 'No puede ser negativa';
                    return null;
                  },
                ),
              ),
            ],
          ),
          _campo(
            campo: 'descripcion',
            controller: _descripcion,
            label: 'Descripción (opcional)',
            icon: Icons.notes_rounded,
            maxLength: 500,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(widget.esEdicion ? Icons.save_rounded : Icons.add_rounded),
            label: Text(_guardando ? 'Guardando...' : (widget.esEdicion ? 'Guardar cambios' : 'Registrar producto')),
          ),
        ],
      ),
    );
  }

  static String? _requerido(String? value, String nombre) {
    return (value == null || value.trim().isEmpty) ? 'Ingresa $nombre' : null;
  }

  Widget _campo({
    required String campo,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int? maxLength,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization capitalization = TextCapitalization.sentences,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        enabled: !_guardando,
        decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon)),
        maxLength: maxLength,
        maxLines: maxLines,
        keyboardType: keyboardType ?? (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
        textInputAction: textInputAction,
        textCapitalization: capitalization,
        inputFormatters: inputFormatters,
        validator: validator,
        forceErrorText: _serverErrors[campo],
        onChanged: (_) => _limpiarErrorServidor(campo),
      ),
    );
  }
}

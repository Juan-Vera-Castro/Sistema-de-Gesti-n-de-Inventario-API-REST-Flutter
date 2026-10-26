import 'package:intl/intl.dart';

/// Formateadores de presentación (moneda colombiana, unidades y fechas).
class Formatters {
  Formatters._();

  // Patrón explícito: el de es_CO en intl ubica el símbolo al final ("45.900 $").
  static final _monedaEntera = NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$',
    decimalDigits: 0,
    customPattern: '¤ #,##0',
  );
  static final _monedaDecimal = NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$',
    decimalDigits: 2,
    customPattern: '¤ #,##0.00',
  );
  static final _entero = NumberFormat.decimalPattern('es_CO');
  static final _fecha = DateFormat('dd/MM/yyyy HH:mm');

  /// Muestra decimales solo si el valor los tiene (p. ej. `$ 45.900` o `$ 15.000,46`).
  static String moneda(double valor) {
    final tieneDecimales = (valor * 100).round() % 100 != 0;
    return (tieneDecimales ? _monedaDecimal : _monedaEntera).format(valor);
  }

  static String entero(int valor) => _entero.format(valor);

  static String fecha(DateTime? fecha) => fecha == null ? '—' : _fecha.format(fecha.toLocal());
}

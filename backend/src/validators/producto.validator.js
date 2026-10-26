// Reglas de validación de la entidad Producto (SPECIFICATION.md §5.4).

function readText(value, { campo, etiqueta, max, required, errors }) {
  if (value === undefined || value === null || (typeof value === 'string' && value.trim() === '')) {
    if (required) errors[campo] = `El campo ${etiqueta} es obligatorio`;
    return null;
  }
  if (typeof value !== 'string') {
    errors[campo] = `El campo ${etiqueta} debe ser texto`;
    return null;
  }
  const text = value.trim();
  if (text.length > max) {
    errors[campo] = `El campo ${etiqueta} no puede superar ${max} caracteres`;
    return null;
  }
  return text;
}

/** Acepta números o cadenas numéricas; devuelve NaN si no es convertible. */
function toNumber(value) {
  if (typeof value === 'number') return value;
  if (typeof value === 'string' && value.trim() !== '') return Number(value.trim());
  return Number.NaN;
}

/**
 * Valida y normaliza el cuerpo de un producto.
 * @returns {{ data: object|null, errors: Record<string, string> }}
 */
export function validateProducto(body) {
  const errors = {};

  if (body === null || typeof body !== 'object' || Array.isArray(body)) {
    return { data: null, errors: { body: 'El cuerpo de la petición debe ser un objeto JSON' } };
  }

  const nombre = readText(body.nombre, { campo: 'nombre', etiqueta: 'nombre', max: 100, required: true, errors });
  const codigo = readText(body.codigo, { campo: 'codigo', etiqueta: 'código', max: 50, required: true, errors });
  const descripcion = readText(body.descripcion, { campo: 'descripcion', etiqueta: 'descripción', max: 500, required: false, errors });
  const categoria = readText(body.categoria, { campo: 'categoria', etiqueta: 'categoría', max: 50, required: true, errors });

  let precio = null;
  if (body.precio === undefined || body.precio === null || body.precio === '') {
    errors.precio = 'El campo precio es obligatorio';
  } else {
    precio = toNumber(body.precio);
    if (!Number.isFinite(precio)) {
      errors.precio = 'El precio debe ser un número válido';
    } else {
      // Se valida después de redondear: 0.001 > 0 pero se guardaría como 0.
      precio = Math.round(precio * 100) / 100;
      if (precio <= 0) errors.precio = 'El precio debe ser mayor que 0 (mínimo 0.01)';
    }
  }

  let cantidad = null;
  if (body.cantidad === undefined || body.cantidad === null || body.cantidad === '') {
    errors.cantidad = 'El campo cantidad es obligatorio';
  } else {
    cantidad = toNumber(body.cantidad);
    if (!Number.isSafeInteger(cantidad)) errors.cantidad = 'La cantidad debe ser un número entero válido';
    else if (cantidad < 0) errors.cantidad = 'La cantidad no puede ser negativa';
  }

  if (Object.keys(errors).length > 0) return { data: null, errors };
  return { data: { nombre, codigo, descripcion, precio, cantidad, categoria }, errors };
}

/** Convierte el parámetro `:id` en entero positivo o devuelve null. */
export function parseId(raw) {
  if (!/^\d+$/.test(raw)) return null;
  const id = Number(raw);
  return Number.isSafeInteger(id) && id > 0 ? id : null;
}

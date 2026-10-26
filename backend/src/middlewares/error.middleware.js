import { HttpError, sendError } from '../utils/response.js';

/** Ruta no encontrada. */
export function notFoundHandler(req, res) {
  sendError(res, { status: 404, message: `Ruta no encontrada: ${req.method} ${req.originalUrl}` });
}

/** Manejador global: convierte cualquier error en una respuesta JSON estándar. */
// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, next) {
  if (err instanceof HttpError) {
    return sendError(res, { status: err.status, message: err.message, errors: err.errors });
  }

  // JSON mal formado (body-parser de Express).
  if (err.type === 'entity.parse.failed') {
    return sendError(res, { status: 400, message: 'El cuerpo de la petición no es un JSON válido' });
  }

  // Violación de UNIQUE en SQLite (p. ej. dos peticiones simultáneas con el mismo código).
  if (typeof err.message === 'string' && err.message.includes('UNIQUE constraint failed: productos.codigo')) {
    return sendError(res, {
      status: 422,
      message: 'Los datos del producto no son válidos',
      errors: { codigo: 'Ya existe un producto con este código' },
    });
  }

  if (err.status >= 400 && err.status < 500) {
    return sendError(res, { status: err.status, message: err.message });
  }

  console.error(err);
  return sendError(res, { status: 500, message: 'Error interno del servidor' });
}

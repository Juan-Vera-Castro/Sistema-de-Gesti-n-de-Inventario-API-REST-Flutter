// Formato estándar de respuestas JSON de la API.

export function sendSuccess(res, { status = 200, message, data, total }) {
  const body = { success: true, message };
  if (total !== undefined) body.total = total;
  body.data = data;
  return res.status(status).json(body);
}

export function sendError(res, { status, message, errors }) {
  const body = { success: false, message };
  if (errors && Object.keys(errors).length > 0) body.errors = errors;
  return res.status(status).json(body);
}

/** Error con código HTTP que el manejador global convierte en respuesta JSON. */
export class HttpError extends Error {
  constructor(status, message, errors) {
    super(message);
    this.status = status;
    this.errors = errors;
  }
}

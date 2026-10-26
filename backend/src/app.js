import cors from 'cors';
import express from 'express';
import { createProductoController } from './controllers/producto.controller.js';
import { errorHandler, notFoundHandler } from './middlewares/error.middleware.js';
import { createProductoRepository } from './repositories/producto.repository.js';
import { createProductoRouter } from './routes/producto.routes.js';
import { sendSuccess } from './utils/response.js';

/**
 * Construye la aplicación Express a partir de una conexión SQLite
 * (inyectable para poder probarla con una base de datos en memoria).
 */
export function createApp(db) {
  const app = express();
  app.disable('x-powered-by');
  app.use(cors());
  app.use(express.json({ limit: '100kb' }));

  const controller = createProductoController(createProductoRepository(db));

  app.get('/api/health', (req, res) => {
    sendSuccess(res, { message: 'API de inventario operativa', data: { status: 'ok' } });
  });
  app.use('/api/productos', createProductoRouter(controller));

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
